-- polls/gui.lua
-- GUIs for poll creation, voting, and management

local function esc(x)
    return minetest.formspec_escape(x or "")
end

-----------------------------------------------------------
-- SHOW POLL CREATOR (CEO ONLY)
-----------------------------------------------------------
function polls.show_editor_formspec(name)
    local fs =
        "formspec_version[4]" ..
        "size[14,10]" ..
        "label[0.5,0.5;Create New Poll]" ..

        "label[0.5,1.4;Poll Question:]" ..
        "field[0.5,1.9;13,1;question;;]" ..

        "label[0.5,3;Options (one per line):]" ..
        "textarea[0.5,3.5;13,4;opts;;]" ..

        "button[2,8.2;4,1;create;Create Poll]" ..
        "button[8,8.2;4,1;cancel;Close]"

    minetest.show_formspec(name, "polls:editor", fs)
end

-----------------------------------------------------------
-- HANDLE POLL CREATOR INPUT
-----------------------------------------------------------
function polls.handle_editor_input(player, fields)
    local name = player and player:get_player_name()
    if not name then return end
    if not fields then return end

    if fields.cancel then
        minetest.close_formspec(name, "polls:editor")
        return
    end

    if fields.create then
        local q = fields.question or ""
        local raw_opts = fields.opts or ""

        -- Convert textarea lines into table
        local options = {}
        for line in raw_opts:gmatch("[^\r\n]+") do
            if line and line:gsub("%s+", "") ~= "" then
                table.insert(options, line)
            end
        end

        local ok, msg = polls.create_poll(name, q, options)
        if not ok then
            minetest.chat_send_player(name, "Poll create failed: " .. msg)
        else
            polls.save_history() -- store to disk
            minetest.chat_send_player(name, "Poll created.")
            minetest.close_formspec(name, "polls:editor")
        end
    end
end

-----------------------------------------------------------
-- SHOW VOTING FORM
-----------------------------------------------------------
function polls.show_vote_formspec(name)
    local p = polls.active_poll
    if not p then return end

    local fs =
        "formspec_version[4]" ..
        "size[14,10]" ..
        ("label[0.5,0.5;%s]"):format(esc("Poll: " .. p.question)) ..
        "label[0.5,1.3;Choose an option:]"

    local y = 2
    for i, opt in ipairs(p.options) do
        fs = fs .. ("button[1,%s;12,1;opt_%d;%s]"):format(y, i, esc(opt))
        y = y + 1.2
    end

    minetest.show_formspec(name, "polls:vote", fs)
end

-----------------------------------------------------------
-- SHOW POLL RESULTS (CEO ONLY)
-----------------------------------------------------------
function polls.show_results_formspec(name)
    if not polls.active_poll then
        minetest.chat_send_player(name, "No active poll.")
        return
    end

    local p = polls.active_poll
    local results = polls.get_results()
    local fs =
        "formspec_version[4]" ..
        "size[14,10]" ..
        ("label[0.5,0.5;%s]"):format(esc("Results: " .. p.question))

    local y = 2
    for i, opt in ipairs(p.options) do
        fs = fs .. ("label[0.5,%s;%s - %d votes]"):format(
            y, esc(opt), results[i] or 0
        )
        y = y + 1
    end

    minetest.show_formspec(name, "polls:results", fs)
end

-----------------------------------------------------------
-- CEO CONTROL PANEL (OPTIONAL)
-----------------------------------------------------------
function polls.show_ceo_panel(name)
    local fs =
        "formspec_version[4]" ..
        "size[14,8]" ..
        "label[0.5,0.5;Poll Administration]" ..
        "button[1,2;12,1;new;Create New Poll]" ..
        "button[1,3.5;12,1;view;View Results]" ..
        "button[1,5;12,1;kill;Cancel Poll]"

    minetest.show_formspec(name, "polls:ceo", fs)
end
