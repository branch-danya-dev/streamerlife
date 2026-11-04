--!nonstrict
-- Runtime persistence state machine; dependencies allow deterministic fault/race tests.
return function(Config, Domain, Lease, io)
	local Store = { records = {}, loading = {}, closing = false, requests = 0, failures = 0 }
	local function retry(callback)
		for attempt = 1, Config.SaveAttempts do
			Store.requests += 1
			local ok, value = pcall(callback)
			if ok then
				return value
			end -- nil is an explicit rejected lease, not a network failure.
			Store.failures += 1
			io.failed(attempt)
			if attempt < Config.SaveAttempts then
				io.wait(0.5 * 2 ^ (attempt - 1))
			end
		end
		return nil
	end

	function Store.load(player)
		if Store.closing or Store.records[player] or Store.loading[player] then
			return nil
		end
		Store.loading[player] = true
		local token = io.token()
		local key = "player_" .. tostring(player.UserId)
		local result = retry(function()
			return io.update(key, function(old)
				return Lease.acquire(old, token, io.now())
			end)
		end)
		if not result or not result.lock or result.lock.token ~= token then
			Store.loading[player] = nil
			return nil
		end
		local record = {
			profile = result.data,
			token = token,
			key = key,
			expires = result.lock.expires,
			revision = result.revision,
			saving = false,
			closing = false,
		}
		Store.records[player] = record
		if Store.closing or not io.present(player) then
			Store.save(player, true)
			Store.loading[player] = nil
			return nil
		end
		Store.loading[player] = nil
		return record.profile, result.arrival
	end

	function Store.get(player)
		local record = Store.records[player]
		if not record or record.closing or io.now() >= record.expires - 10 then
			return nil
		end
		return record.profile
	end

	function Store.save(player, release)
		local record = Store.records[player]
		if not record then
			return true
		end
		if release then
			record.closing = true
		end
		while record.saving do
			io.wait(0.05)
		end
		if Store.records[player] ~= record then
			return true
		end
		if record.closing and not release then
			return false
		end
		record.saving = true
		record.revision += 1
		local revision = record.revision
		local snapshot = Domain.copy(record.profile)
		local result = retry(function()
			return io.update(record.key, function(old)
				return Lease.save(old, record.token, revision, snapshot, io.now(), release)
			end)
		end)
		record.saving = false
		if result then
			record.profile.lastSeen = math.max(record.profile.lastSeen, result.data.lastSeen)
			if result.lock then
				record.expires = result.lock.expires
			end
		end
		if release then
			Store.records[player] = nil
		elseif not result and io.now() >= record.expires - 30 then
			record.closing = true
			io.kick(player)
		end
		return result ~= nil
	end

	function Store.close()
		Store.closing = true
		if Store.beforeClose then
			Store.beforeClose()
		end
		local pending = 0
		for player in pairs(Store.records) do
			pending += 1
			io.spawn(function()
				Store.save(player, true)
				pending -= 1
			end)
		end
		local deadline = io.clock() + 25
		-- An acquisition already inside UpdateAsync can finish after shutdown starts.
		-- load() releases that lease; keep BindToClose alive until it has done so.
		while (pending > 0 or next(Store.loading) ~= nil) and io.clock() < deadline do
			io.wait(0.1)
		end
		return pending == 0 and next(Store.loading) == nil
	end
	return Store
end
