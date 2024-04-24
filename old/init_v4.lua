local hidden_players = {}  -- Table to store hidden player data
local prop_item_name = "prophunt:item"

--local function is_player_hidden(name)
--    return hidden_players[name] ~= nil
--end


local function is_player_hidden(name)
    return minetest.get_player_by_name(name):get_physics_override().speed == 0
end

-- Function to check if hidden player's position is equal to last position before hiding
local function check_hidden_players()
    for name, data in pairs(hidden_players) do
        local player = minetest.get_player_by_name(name)
        if player then
            local pos = player:get_pos()
            if pos.x ~= data.last_pos.x or pos.y ~= data.last_pos.y or pos.z ~= data.last_pos.z then
                -- Player has moved, unhide player
                player:set_properties({
                    nametag = name,
                    visual_size = {x = 1, y = 1}
                })
                player:set_physics_override({speed = 1, jump = 1})
                minetest.set_node(data.pos, {name = data.node})
                hidden_players[name] = nil
                minetest.set_node(pos, {name = "air"})
                minetest.chat_send_player(name, "You are no longer hiding.")
            end
        end
    end
end

local function toggle_hide(itemstack, placer, pointed_thing)
    local name = placer:get_player_name()
    local player = minetest.get_player_by_name(name)
    if not player then
        return
    end

    local pos = player:get_pos()
    if is_player_hidden(name) or player:get_player_control().up or player:get_player_control().down or player:get_player_control().left or player:get_player_control().right then
        -- Player is already hiding or moving, reveal them and remove the node
        player:set_properties({
            nametag = name,
            visual_size = {x = 1, y = 1}
        })
        player:set_physics_override({speed = 1, jump = 1})
        minetest.set_node(pos, {name = "air"})
        hidden_players[name] = nil
        minetest.chat_send_player(name, "You are no longer hiding.")
    else
        -- Hide the player
        local node_name = "mcl_core:stone"  -- Replace with the node you want to place
        player:set_properties({
            nametag = "",
            visual_size = {x = 0, y = 0}
        })
        player:set_physics_override({speed = 0, jump = 0})
        minetest.set_node(pos, {name = node_name})
        hidden_players[name] = {pos = pos, node = node_name, last_pos = pos} -- Initialize last_pos here
        minetest.chat_send_player(name, "You are now hiding. Right-click with the Prop Hunt item to reveal yourself.")
    end
end

minetest.register_craftitem(prop_item_name, {
    description = "Prop Hunt Item",
    inventory_image = "default_stone.png",
    _tt_help = "Right-click to hide",
    _doc_items_longdesc = "The Prop Hunt Item allows you to hide as a random block.",
    on_place = toggle_hide,
    on_use = function(itemstack, player, pointed_thing)
        -- Check if the player is crouching
        if player:get_player_control().sneak then
            -- Transform player into a random block
            local pos = player:get_pos()
            local node_name = "default:stone"  -- Replace with actual random node selection logic
            minetest.set_node(pos, {name = node_name})
            player:set_physics_override({speed = 0, jump = 0})
            player:set_nametag_attributes({color = {a = 0, r = 255, g = 255, b = 255}})
        end
    end,
})

local function is_player_hidden(name)
    return minetest.get_player_by_name(name):get_physics_override().speed == 0
end

-- Function to check if hidden player's position is equal to last position before hiding
local function check_hidden_players()
    for name, data in pairs(hidden_players) do
        local player = minetest.get_player_by_name(name)
        if player then
            local pos = player:get_pos()
            if pos.x ~= data.last_pos.x or pos.y ~= data.last_pos.y or pos.z ~= data.last_pos.z then
                -- Player has moved, unhide player
                player:set_properties({
                    nametag = name,
                    visual_size = {x = 1, y = 1}
                })
                player:set_physics_override({speed = 1, jump = 1})
                minetest.set_node(data.pos, {name = data.node})
                hidden_players[name] = nil
                minetest.set_node(pos, {name = "air"})
                minetest.chat_send_player(name, "You are no longer hiding.")
            end
        end
    end
end

minetest.register_globalstep(function(dtime)
    local players = minetest.get_connected_players()
    for _, player in ipairs(players) do
        local name = player:get_player_name()
        local wielded_item = player:get_wielded_item():get_name()
        if wielded_item == prop_item_name then
            if is_player_hidden(name) then
                local data = hidden_players[name]
                repeat
                    local pos = player:get_pos()
                    player:set_pos(data.last_pos)
                until pos.x == data.last_pos.x and pos.y == data.last_pos.y and pos.z == data.last_pos.z
            end
        end
    end
end)
