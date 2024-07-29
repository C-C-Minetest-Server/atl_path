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

local function calculate_wear(uses)
    return math.floor(65535 / (uses*10))
end

local function override_shovel_tools()
    for name, def in pairs(minetest.registered_items) do
        if def.groups and def.groups.shovel == 1 then
            local uses = 100
            if def.tool_capabilities and def.tool_capabilities.groupcaps and def.tool_capabilities.groupcaps.crumbly then
                for _, cap in pairs(def.tool_capabilities.groupcaps.crumbly) do
                    if type(cap) == "table" and cap.uses then
                        uses = cap.uses
                        break
                    end
                end
            end

            local wear = calculate_wear(uses)

            minetest.override_item(name, {
                on_place = function(itemstack, user, pointed_thing)
                    if pointed_thing.type == "node" then
                        local pos = pointed_thing.under
                        local node = minetest.get_node(pos)
                        local node_def = minetest.registered_nodes[node.name]

                        if node_def and node_def.groups and node_def.groups.soil == 1 then
                            if node.name ~= "default:sand" and
                               node.name ~= "default:desert_sand" and
                               node.name ~= "default:silver_sand" then
                                local pos_above = {x = pos.x, y = pos.y + 1, z = pos.z}
                                local node_above = minetest.get_node(pos_above)
                                local node_above_def = minetest.registered_nodes[node_above.name]

                                if node_above_def and (node_above_def.groups.flora == 1 or node_above_def.groups.mushroom == 1) then
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
                        end
                    end
                    return itemstack
                end
            })
        end
    end
end

override_shovel_tools()
