--!nonstrict
-- Pure UpdateAsync transformations. Returning nil cancels the write.
return function(Config, Domain)
	local Lease = {}
	function Lease.acquire(old, token, now)
		if old ~= nil then
			if type(old) ~= "table" or type(old.data) ~= "table" or old.data.version ~= Config.Schema then
				return nil
			end
			if old.lock then
				if old.lock.token == token and old.lock.expires > now then
					return Domain.copy(old)
				end
				if old.lock.expires > now then
					return nil
				end
			end
		end
		local p = Domain.normalize(if old then old.data else nil, now)
		local arrival = Domain.offline(p, now)
		return {
			data = p,
			lock = { token = token, expires = now + Config.LeaseSeconds },
			arrival = arrival,
			revision = 0,
		}
	end
	function Lease.save(old, token, revision, profile, now, release)
		if type(old) ~= "table" then
			return nil
		end
		local writeId = token .. ":" .. tostring(revision)
		if old.lastWrite == writeId then
			return Domain.copy(old)
		end
		if
			not old.lock
			or old.lock.token ~= token
			or old.lock.expires <= now
			or revision <= (old.revision or 0)
		then
			return nil
		end
		local p = Domain.copy(profile)
		p.lastSeen = math.max(p.lastSeen, now)
		return {
			data = p,
			lock = if release then nil else { token = token, expires = now + Config.LeaseSeconds },
			arrival = old.arrival,
			revision = revision,
			lastWrite = writeId,
		}
	end
	return Lease
end
