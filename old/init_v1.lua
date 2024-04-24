local hidden_players = {}  -- Table to store hidden player data

local prop_item_name = "prophunt:item"

minetest.register_craftitem(prop_item_name, {
    description = "Prop Hunt Item",
    inventory_image = "default_stone.png",
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

local hidden_players = {}  -- Table to store hidden player data

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
                minetest.chat_send_player(name, "You are no longer hiding.")
            end
        end
    end
end

-- Register globalstep to run the check_hidden_players function every tick
minetest.register_globalstep(check_hidden_players)

minetest.register_chatcommand("hideme", {
    description = "Toggle hiding your name and preventing movement",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then
            return
        end

        if hidden_players[name] then
            -- Player is already hiding, restore previous state
            local data = hidden_players[name]
            player:set_properties({
                nametag = name,
                visual_size = {x = 1, y = 1}
            })
            player:set_physics_override({speed = 1, jump = 1})
            minetest.set_node(data.pos, {name = data.node})
            hidden_players[name] = nil
            minetest.chat_send_player(name, "You are no longer hiding.")
        else
            -- Player is not hiding, hide name, prevent movement, and place a node
            local pos = player:get_pos()
            local node_name = "mcl_core:stone"  -- Replace with the node you want to place
            player:set_properties({
                nametag = "",
                visual_size = {x = 0, y = 0}
            })
            player:set_physics_override({speed = 0, jump = 0})
            minetest.set_node(pos, {name = node_name})
            hidden_players[name] = {pos = pos, node = node_name, last_pos = pos}
            minetest.chat_send_player(name, "You are now hiding. Right-click with the Prop Hunt item to change the node.")
        end
    end,
})

minetest.register_globalstep(function(dtime)
    local players = minetest.get_connected_players()
    for _, player in ipairs(players) do
        local name = player:get_player_name()
        local wielded_item = player:get_wielded_item():get_name()
        if wielded_item == prop_item_name then
            if is_player_hidden(name) then
                repeat
                    local pos = player:get_pos()
                    player:set_pos(last_pos)
                until pos.x == last_pos.x and pos.y == last_pos.y and pos.z == last_pos.z
            end
        end
    end
end)
