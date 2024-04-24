local prop_item_name = "prophunt:item"

minetest.register_craftitem(prop_item_name, {
    description = "Prop Hunt Item",
    inventory_image = "default_stone.png",
    on_use = function(itemstack, player, pointed_thing)
        -- Check if the player is crouching
        if player:get_player_control().sneak then
            -- Transform player into a random block
            local pos = player:get_pos()
            local random_node_name = "default:stone"  -- Replace with actual random node selection logic
            minetest.set_node(pos, {name = random_node_name})
        end
    end,
})

-- Register an on_unCrouch event to restore the player to normal
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "default:stone" then
        local name = player:get_player_name()
        if fields.sneak then
            local pos = player:get_pos()
            local node = minetest.get_node(pos)
            local node_def = minetest.registered_nodes[node.name]
            if node_def and node_def.groups and node_def.groups.prop_hunt then
                local prop_item_name = "prop_hunt:item"
                minetest.set_node(pos, {name = prop_item_name})
            end
        end
    end
end)

local hide_player_data = {}

minetest.register_chatcommand("hideme", {
    description = "Toggle hiding your name and preventing movement",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then
            return
        end

        if hide_player_data[name] then
            -- Player is already hiding, restore previous state
            player:set_properties({
                nametag = name,
                visual_size = {x = 1, y = 1}
            })
            player:set_physics_override({speed = 1, jump = 1, gravity = 2})
            minetest.set_node(hide_player_data[name].pos, {name = hide_player_data[name].node})
            hide_player_data[name] = nil
            minetest.chat_send_player(name, "You are no longer hiding.")
        else
            -- Player is not hiding, hide name, prevent movement, and place a node
            local pos = player:get_pos()
            local node_name = "mcl_core:stone"  -- Replace with the node you want to place
            player:set_properties({
                nametag = "",
                visual_size = {x = 0, y = 0}
            })
            player:set_physics_override({speed = 0, jump = 0, gravity = 2})
            minetest.set_node(pos, {name = node_name})
            hide_player_data[name] = {pos = pos, node = node_name}
            
            minetest.chat_send_player(name, "You are now hiding. Right-click with the Prop Hunt item to change the node.")
            
        end
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "" then
        local name = player:get_player_name()
        if fields.rightclick and hide_player_data[name] then
            local itemstack = player:get_wielded_item()
            if itemstack:get_name() == "prophunt:item" then
                local pos = hide_player_data[name].pos
                local node_name = "default:dirt"  -- Change to the node you want to change to
                minetest.set_node(pos, {name = node_name})
                hide_player_data[name].node = node_name
            end
        end
    end
end)
