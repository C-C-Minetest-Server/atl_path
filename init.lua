--[[
    This program allow to create paths with shovel
    Copyright (C) 2024  Atlante and contributors

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

local S = minetest.get_translator("atl_path")

minetest.register_node("atl_path:path_dirt", {
    description = S("Dirt Path"),
    drawtype = "nodebox",
    tiles = {
        "atl_dirt_path_top.png",
        "atl_dirt_path_top.png",
        "default_dirt.png^atl_dirt_path_side.png"
    },
    use_texture_alpha = "clip",
    is_ground_content = false,
    paramtype = "light",
    node_box = {
        type = "fixed",
        fixed = { -1 / 2, -1 / 2, -1 / 2, 1 / 2, 1 / 2 - 1 / 16, 1 / 2 },
    },
    collision_box = {
        type = "fixed",
        fixed = { -1 / 2, -1 / 2, -1 / 2, 1 / 2, 1 / 2 - 1 / 16, 1 / 2 },
    },
    selection_box = {
        type = "fixed",
        fixed = { -1 / 2, -1 / 2, -1 / 2, 1 / 2, 1 / 2 - 1 / 16, 1 / 2 },
    },
    drop = "default:dirt",
    groups = { no_silktouch = 1, crumbly = 3, not_in_creative_inventory = 1 },
    sounds = default.node_sound_dirt_defaults()
})

local function is_attached_bottom(pos)
    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[pos]
    local paramtype2 = def and def.paramtype2 or "none"
    local attach_group = minetest.get_item_group(node.name, "attached_node")

    if attach_group == 3 then
        return true
    elseif attach_group == 1 then
        if paramtype2 == "wallmounted" then
            return minetest.wallmounted_to_dir(node.param2).y == -1
        end
        return true
    elseif attach_group == 2
        and paramtype2 == "facedir" -- 4dir won't attach to bottom
        and minetest.facedir_to_dir(node.param2).y == -1 then
        return true
    end
    return false
end

local function override_shovel_tools()
    for name, def in pairs(minetest.registered_items) do
        if def.groups and def.groups.shovel == 1 then
            local uses = 100
            if def.tool_capabilities and def.tool_capabilities.groupcaps and def.tool_capabilities.groupcaps.crumbly then
                uses = def.tool_capabilities.groupcaps.crumbly.uses or 100
            end

            local wear = minetest.get_tool_wear_after_use(uses)

            minetest.override_item(name, {
                on_place = function(itemstack, user, pointed_thing)
                    if pointed_thing.type ~= "node" then
                        return itemstack
                    end

                    local pos = pointed_thing.under
                    local node = minetest.get_node(pos)
                    local node_def = minetest.registered_nodes[node.name]

                    if node_def and node_def.groups and node_def.groups.soil == 1 then
                        local pos_above = {x = pos.x, y = pos.y + 1, z = pos.z}
                        local node_above = minetest.get_node(pos_above)
                        if is_attached_bottom(pos_above) then
                            minetest.set_node(pos, {name = "atl_path:path_dirt"})
                            itemstack:add_wear(wear)
                            minetest.remove_node(pos_above)
                            minetest.add_item(pos_above, node_above.name)
                        elseif node_above.name == "air" then
                            minetest.set_node(pos, {name = "atl_path:path_dirt"})
                            itemstack:add_wear(wear)
                        else
                            return itemstack
                        end
                    end
                    return itemstack
                end
            })
        end
    end
end

override_shovel_tools()
