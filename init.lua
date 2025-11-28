
-- polls/init.lua
-- Main loader for the poll mod (crash-proof)

polls = {}

-- Load API
dofile(minetest.get_modpath("polls") .. "/api.lua")

-- Load storage
dofile(minetest.get_modpath("polls") .. "/storage.lua")

-- Load GUI system
dofile(minetest.get_modpath("polls") .. "/gui.lua")

-- Register CEO priv
minetest.register_privilege("ceo", {
    description = "Allows creating and managing polls",
    give_to_singleplayer = false,
})

-- Show poll on join (after 10s, if safe)
minetest.register_on_joinplayer(function(player)
    minetest.after(10, function()
        if not player or not player:is_player() then return end
        polls.try_show_poll(player)
    end)
end)

-- Handle voting GUI fields
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if not formname then return end
    if formname == "polls:vote" then
        polls.handle_vote(player, fields)
    elseif formname == "polls:editor" then
        polls.handle_editor_input(player, fields)
    end
end)
