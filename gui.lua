-- polls/api.lua
-- Core logic for poll system

polls.active_poll = nil       -- current poll table or nil
polls.player_votes = {}       -- votes[name] = option index
polls.history = {}            -- loaded/saved by storage.lua

local function safe_name(player)
    if not player or not player.is_player or not player:is_player() then
        return nil
    end
    return player:get_player_name()
end

-----------------------------------------------------------
-- ANNOUNCE TO ALL
-----------------------------------------------------------
function polls.announce(msg)
    minetest.chat_send_all("[Poll] " .. msg)
end

-----------------------------------------------------------
-- CREATE A NEW POLL
-----------------------------------------------------------
function polls.create_poll(creator, question, options)
    if not question or question == "" then return false, "Invalid question" end
    if #options < 2 then return false, "Need at least 2 options" end

    polls.active_poll = {
        question = question,
        options = options,
        created_by = creator,
        created_at = os.time()
    }

    polls.player_votes = {}

    polls.announce("New poll created by " .. creator .. ": " .. question)
    return true
end

-----------------------------------------------------------
-- CANCEL CURRENT POLL
-----------------------------------------------------------
function polls.cancel_poll(name)
    if not polls.active_poll then return false, "No active poll" end
    polls.active_poll = nil
    polls.player_votes = {}
    polls.announce(name .. " cancelled the poll.")
    return true
end

-----------------------------------------------------------
-- GET RESULTS
-----------------------------------------------------------
function polls.get_results()
    if not polls.active_poll then return nil end

    local results = {}
    for i = 1, #polls.active_poll.options do
        results[i] = 0
    end

    for _, vote in pairs(polls.player_votes) do
        if results[vote] then
            results[vote] = results[vote] + 1
        end
    end

    return results
end

-----------------------------------------------------------
-- PLAYER VOTING
-----------------------------------------------------------
function polls.handle_vote(player, fields)
    local name = safe_name(player)
    if not name then return end
    if not polls.active_poll then return end
    if polls.player_votes[name] then return end

    for k, v in pairs(fields) do
        if k:sub(1,5) == "opt_" then
            local index = tonumber(k:sub(6))
            if index then
                polls.player_votes[name] = index
                minetest.chat_send_player(name, 
                    "You voted for: " .. polls.active_poll.options[index])
                return
            end
        end
    end
end

-----------------------------------------------------------
-- SHOW POLL FOR PLAYER IF SAFE
-----------------------------------------------------------
function polls.try_show_poll(player)
    if not polls.active_poll then return end

    local name = safe_name(player)
    if not name then return end

    if polls.player_votes[name] then return end

    -- Check if another formspec is open
    local fs = minetest.get_player_formspec(name)
    if fs and fs ~= "" then return end

    -- Show our voting formspec
    polls.show_vote_formspec(name)
end
