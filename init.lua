prophunt = {}  -- Define the prophunt table

local hidename = dofile(minetest.get_modpath("prophunt") .. "/api.lua")
local S = core.get_translator(prophunt.modname)

local hidden_players = {}  -- Table to store hidden player data
local prop_item_name = "prophunt:item"

--local function is_player_hidden(name)
--    local player = minetest.get_player_by_name(name)
--    if player then
--        return player:get_physics_override().speed == 0
--    end
--    return false
--end

local function is_player_hidden(name)
    return hidden_players[name] ~= nil
end

local function unhide_player(name)
    local player = minetest.get_player_by_name(name)
    -- Player has moved, unhide player
    player:set_properties({
        nametag = name,
        visual_size = {x = 1, y = 1}
    })
    player:set_physics_override({speed = 1, jump = 1})

    -- Unhide the player
    local last_pos
    if hidden_players[name] and hidden_players[name].last_pos then
        last_pos = hidden_players[name].last_pos
    else
        last_pos = pos
    end

    if last_pos then
        local node_name = minetest.get_node(last_pos).name
        if node_name ~= "air" then
            minetest.set_node(last_pos, {name = "air"})
        end
    end

    hidden_players[name] = nil
    mcl_hunger.set_hunger(player, 20)
    minetest.chat_send_player(name, "You are no longer hiding.")
end

local last_check_time = minetest.get_us_time()

local function check_hidden_players()
    local current_time = minetest.get_us_time()
    local dtime = (current_time - last_check_time) / 1000000
    last_check_time = current_time

    -- chatgpt I need: if myname is not in hidden_players add +2 hp 
    
    for name, data in pairs(hidden_players) do
        local player = minetest.get_player_by_name(name)
        prophunt.hide(name)
        if player then
            -- Calculate elapsed time since last hunger update
            if not data.last_hunger_update_time then
                data.last_hunger_update_time = 0
            end

            data.last_hunger_update_time = data.last_hunger_update_time + dtime

            -- Update hunger based on elapsed time
            if is_player_hidden(name) then
                if data.last_hunger_update_time >= 3 then
                    player:set_hp(player:get_hp() - 2)  -- Lower health by 2
                    data.last_hunger_update_time = 0
                end
            end
            
            local pos = player:get_pos()
            local node = minetest.get_node(pos)
            if node.name == "air" then
                -- Node at player's position is air, reveal and kill player
                player:set_properties({
                    nametag = name,
                    visual_size = {x = 1, y = 1}
                })
                player:set_physics_override({speed = 1, jump = 1})
                minetest.set_node(pos, {name = "air"})
                hidden_players[name] = nil
                player:set_hp(0)  -- Kill player
                minetest.chat_send_player(name, "You where found.")
            end
            if pos.x ~= data.last_pos.x or pos.y ~= data.last_pos.y or pos.z ~= data.last_pos.z then
                unhide_player(name)
            end
            if player:get_player_control().up or player:get_player_control().down or player:get_player_control().left or player:get_player_control().right then
                minetest.chat_send_player(name, "Cannot hide while moving!")
                local node = minetest.get_node(player:get_pos())
                unhide_player(name)
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
    if not is_player_hidden(name) then
        if not player:get_player_control().up and not player:get_player_control().down and not player:get_player_control().left and not player:get_player_control().right then
            local node = minetest.get_node(pos)
            local floor_pos = player:get_pos()
            floor_pos.y = floor_pos.y - 1
            local floor = minetest.get_node(floor_pos)
            if node.name == "air" and floor.name ~= "air" then

                -- Hide the player
                local node_name = "mcl_core:stone"  -- Replace with the node you want to place
                if floor.name ~= "air" then
                    node_name=floor.name
                end
                player:set_properties({
                    speed=0,
                    nametag = "",
                    visual_size = {x = 0, y = 0}
                })
                player:set_physics_override({speed = 0, jump = 0})
                minetest.set_node(pos, {name = node_name})
                hidden_players[name] = {pos = pos, node = node_name, last_pos = pos} -- Initialize last_pos here
                prophunt.hide(name)
                --local vel = player:get_velocity()
                --player:add_velocity({x = -vel.x, y = -vel.y, z = -vel.z})
                minetest.chat_send_player(name, "You are now hiding. Right-click with the Prop Hunt item to reveal yourself.")
            else
                if not is_player_hidden(name) then
                    minetest.chat_send_player(name, "Cannot hide on " .. node.name)
                end
            end
        else
            minetest.chat_send_player(name, "Cannot hide while moving.")
        end
    else
        local node = minetest.get_node(pos)
        unhide_player(name)
    end
end

minetest.register_craftitem(prop_item_name, {
    description = "Prop Hunt Item",
    inventory_image = "random_texture.png",
    _tt_help = "Right-click to hide",
    _doc_items_longdesc = "The Prop Hunt Item allows you to hide as a random block.",
    on_place = toggle_hide,
    --on_use = toggle_hide,
})

minetest.register_globalstep(check_hidden_players)

minetest.register_craft({
    output = prop_item_name,
    recipe = {
        {"default:stone", "default:stone", "default:stone"},
        {"default:stone", "default:diamond", "default:stone"},
        {"default:stone", "default:stone", "default:stone"},
    },
})


-- teleport_item.lua

minetest.register_craftitem("prophunt:teleport_item", {
    description = "Teleport Stick",
    inventory_image = "default_stick.png",
    on_use = function(itemstack, player, pointed_thing, node)
        local player_pos = player:get_pos()
        local players = minetest.get_connected_players()
        local nearest_distance = nil
        local nearest_player_pos = nil

        for _, other_player in ipairs(players) do
            local name = other_player:get_player_name()
            if name ~= player:get_player_name() then
                local distance = vector.distance(player_pos, other_player:get_pos())
                if nearest_distance == nil or distance < nearest_distance then
                    nearest_distance = distance
                    nearest_player_pos = other_player:get_pos()
                end
            end
        end

        if nearest_player_pos then
            -- Calculate teleport distance (random between 10 and 40)
            local teleport_distance = 10
            -- Calculate teleport direction
            local direction = vector.direction(player_pos, nearest_player_pos)
            -- Calculate teleport position
            local teleport_pos = vector.add(player_pos, vector.multiply(vector.normalize(direction), teleport_distance))

            -- Calculate height difference between two players
            local height_difference = math.abs(player:get_pos().y - nearest_player_pos.y)

            -- Teleport the player
            if nearest_distance > 50 then

                -- Remove the node at the teleport position
                minetest.remove_node(teleport_pos)


                -- Set the player's position to the teleport position
                player:set_pos(teleport_pos)
                minetest.set_node(player_pos, {name="mcl_core:snowblock"})

                -- Set a block of dirt below the player's feet
                player_pos = player:get_pos()
                local player_pos_below = {x=player_pos.x, y=player_pos.y - 1, z=player_pos.z}
                local player_pos_top = {x=teleport_pos.x, y=teleport_pos.y - 1, z=teleport_pos.z}
                local player_pos_top2 = {x=teleport_pos.x, y=teleport_pos.y - 2, z=teleport_pos.z}
                if minetest.get_node(player_pos_below).name == "air" then
                    minetest.set_node(player_pos_top, {name="air"})
                    minetest.set_node(player_pos_top2, {name="air"})
                    minetest.set_node(player_pos, {name="air"})
                end

                -- Set a block of dirt below the player's feet
                if minetest.get_node(player_pos_below).name == "air" then
                    minetest.set_node(player_pos_below, {name="mcl_core:dirt"})
                end

            else
                minetest.chat_send_player(player:get_player_name(), "The nearest player is too close to teleport.")
                minetest.chat_send_player(player:get_player_name(), "Hint: Your height difference is: " .. tostring(height_difference))

            end

            -- Print the distance
            minetest.chat_send_player(player:get_player_name(), "Distance to nearest player: " .. tostring(nearest_distance))
        else
            minetest.chat_send_player(player:get_player_name(), "No other players online.")
        end

        return itemstack
    end,
})
