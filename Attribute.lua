class "__Flags__" { IAttribute,
	InitDefinition = function(self, target, targetType, definition)
		enum.SetFlagsEnum(target, true)

		local enums = definition
        local cache = {}
        local count = 0
        local max   = 0

        -- Scan
        for k, v in pairs, enums do
            v       = tonumber(v)

            if v then
                if v == 0 then
                    if cache[0] then
                        error(strformat("The %s and %s can't be the same value", k, cache[0]), stack)
                    else
                        cache[0] = k
                    end
                elseif v > 0 then
                    count   = count + 1

                    local n = mlog(v) / mlog(2)
                    if floor(n) == n then
                        if cache[2^n] then
                            error(strformat("The %s and %s can't be the same value", k, cache[2^n]), stack)
                        else
                            cache[2^n]  = k
                            max         = n > max and n or max
                        end
                    else
                        error(strformat("The %s's value is not a valid flags value(2^n)", k), stack)
                    end
                else
                    error(strformat("The %s's value is not a valid flags value(2^n)", k), stack)
                end
            else
                count       = count + 1
                enums[k]    = -1
            end
        end

        -- So the definition would be more precisely
        if max >= count then error("The flags enumeration's value can't be greater than 2^(count - 1)", stack) end

        -- Auto-gen values
        local n     = 0
        for k, v in pairs, enums do
            if v == -1 then
                while cache[2^n] do n = n + 1 end
                cache[2^n]  = k
                enums[k]    = 2^n
            end
        end

        -- Mark the max value
        ninfo[FLD_ENUM_MAXVAL] = 2^count - 1

		return definition
	end
}
