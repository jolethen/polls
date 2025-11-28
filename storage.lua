-- polls/storage.lua
-- Persistent poll history (saved in world folder)

local storage_path = minetest.get_worldpath() .. "/poll_history.json"

-----------------------------------------------------------
-- SAFE JSON READ
-----------------------------------------------------------
local function safe_json_read(path)
    local f = io.open(path, "r")
    if not f then return {} end

    local data = f:read("*a")
    f:close()

    if not data or data == "" then
        return {}
    end

    local ok, decoded = pcall(minetest.parse_json, data)
    if ok and type(decoded) == "table" then
        return decoded
    end

    return {}
end

-----------------------------------------------------------
-- SAFE JSON WRITE
-----------------------------------------------------------
local function safe_json_write(path, data)
    local encoded = minetest.write_json(data, true)
    if not encoded then return end

    local f = io.open(path, "w")
    if not f then return end

    f:write(encoded)
    f:close()
end

-----------------------------------------------------------
-- LOAD HISTORY ON START
-----------------------------------------------------------
polls.history = safe_json_read(storage_path)

-----------------------------------------------------------
-- SAVE CURRENT POLL TO HISTORY
-----------------------------------------------------------
function polls.save_history()
    if not polls.active_poll then return end

    local entry = {
        question   = polls.active_poll.question,
        options    = polls.active_poll.options,
        created_by = polls.active_poll.created_by,
        created_at = polls.active_poll.created_at,
        results    = polls.get_results() or {}
    }

    table.insert(polls.history, entry)

    safe_json_write(storage_path, polls.history)
end
