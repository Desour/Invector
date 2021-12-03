-- SolarSail Engine
-- Author: Jordach
-- License: Reserved

-- Primary Namespaces:

solarsail = {}

solarsail.skybox = {}
solarsail.camera = {}
solarsail.controls = {}
solarsail.player = {}
solarsail.util = {}
solarsail.util.functions = {}

--[[
	solarsail.util.function.normalize_pos()
		
	pos_a = vector.new(); considered the zero point
	pos_b = vector.new(); considered the space around the zero point
	returns pos_b localised by pos_a.
]]

function solarsail.util.functions.get_local_pos(pos_a, pos_b)
	local pa = table.copy(pos_a)
	local pb = table.copy(pos_b)
	local res = vector.new(
		pb.x - pa.x,
		pb.y - pa.y,
		pb.z - pa.z
	)
	return res
end

--[[
	solarsail.util.functions.convert_from_hex()

	input = ColorSpec
	returns three variables red, green and blue in base 10 values.
]]--

function solarsail.util.functions.convert_from_hex(input)
	local r, g, b = input:match("^#(%x%x)(%x%x)(%x%x)")
	return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

--[[
	solarsail.util.functions.lerp()

	var_a = input number to blend from. (at ratio 0)
	var_b = input number to blend to. (at ratio 1)
	returns the blended value depending on ratio.
]]--

function solarsail.util.functions.lerp(var_a, var_b, ratio)
	return (1-ratio)*var_a + (ratio*var_b)
end

--[[
	solarsail.util.functions.remap()
	
	val = Input value
	min_val = minimum value of your expected range
	max_val = maximum value of your expected range
	min_map = minimum value of your remapped range
	max_map = maximum value of your remapped range
	returns a value between min_map and max_map based on where val is relative to min_val and max_val.
]]

function solarsail.util.functions.remap(val, min_val, max_val, min_map, max_map)
	return (val-min_val)/(max_val-min_val) * (max_map-min_map) + min_map
end

function solarsail.util.functions.blend_colours(val, min_val, max_val, min_col, max_col)
	if val <= min_val then
		return min_col
	elseif val >= max_val then
		return max_col
	end

	local min_r, min_g, min_b = solarsail.util.functions.convert_from_hex(min_col)
	local max_r, max_g, max_b = solarsail.util.functions.convert_from_hex(max_col)
	
	local blend = solarsail.util.functions.remap(val, min_val, max_val, 0, 1)
	local res_r = solarsail.util.functions.lerp(min_r, max_r, blend)
	local res_g = solarsail.util.functions.lerp(min_g, max_g, blend)
	local res_b = solarsail.util.functions.lerp(min_b, max_b, blend)
	return minetest.rgba(res_r, res_g, res_b)
end

function solarsail.util.functions.y_direction(rads, recoil)
	return math.sin(rads) * recoil
end

function solarsail.util.functions.xz_amount(rads)
	local pi = math.pi
	return math.sin(rads+(pi/2))
end

-- Takes vector based velocities or positions (as vec_a to vec_b)
function solarsail.util.functions.get_3d_angles(vector_a, vector_b)
	-- Does the usual Pythagoras bullshit:
	local x_dist = vector_a.x - vector_b.x + 1
	local z_dist = vector_a.z - vector_b.z + 1
	local hypo = math.sqrt(x_dist^2 + z_dist^2)

	-- But here's the kicker: we're using arctan to get the cotangent of the angle,
	-- but also applies to *negative* numbers. In such cases where the positions
	-- are northbound (positive z); the angle is 180 degrees off.
	local xz_angle = -math.atan(x_dist/z_dist)
	
	-- For the pitch angle we do it very similar, but use the 
	-- Hypotenuse as the Adjacent side, and the Y distance as the
	-- Opposite, so arctangents are needed.
	local y_dist = vector_a.y - vector_b.y
	local y_angle = math.atan(y_dist/hypo)
	
	-- Fixes radians using south facing (-Z) radians when heading north (+Z)
	if z_dist < 0 then
		xz_angle = xz_angle - math.rad(180)
	end
	return xz_angle, y_angle
end

function solarsail.util.functions.pos_to_dist(pos_1, pos_2)
	local res = {}
	res.x = (pos_1.x - pos_2.x)
	res.y = (pos_1.y - pos_2.y)
	res.z = (pos_1.z - pos_2.z)
	return math.sqrt(res.x*res.x + res.y*res.y + res.z*res.z)
end

solarsail.avg_dtime = 0
solarsail.last_dtime = {}

local dtime_steps = 0
local num_steps = 30*2

minetest.register_globalstep(function(dtime)
	if dtime_steps == num_steps then
		local avg = 0
		for i=1, num_steps do
			avg = avg + solarsail.last_dtime[i]
		end
		solarsail.avg_dtime = avg / num_steps
		dtime_steps = 0
		solarsail.last_dtime[1] = dtime
		--print(string.format("%.4f", tostring(solarsail.avg_dtime)))
		--minetest.chat_send_all(string.format("%.4f", tostring(solarsail.avg_dtime)))
	else
		dtime_steps = dtime_steps + 1
		solarsail.last_dtime[dtime_steps] = dtime
	end
end)

if true then
	-- Handle flat mapgen, for building a world
	
	minetest.register_node("solarsail:wireframe", {
		description = "Wireframe, prototyping node",
		tiles = {"solarsail_wireframe.png"},
		groups = {debug=1}
	})
	
	minetest.register_alias("mapgen_stone", "solarsail:wireframe")
	minetest.register_alias("mapgen_grass", "solarsail:wireframe")
	minetest.register_alias("mapgen_water_source", "solarsail:wireframe")
	minetest.register_alias("mapgen_river_water_source", "solarsail:wireframe")
	
	-- Sava data handling (per-player):
	
	--dofile(minetest.get_modpath("solarsail").."/save.lua")
	
	-- HSVA->RGBA->HSVA handling:
	
	--dofile(minetest.get_modpath("solarsail").."/colour.lua")
	
	-- HUD rendering and formspec handling:
	
	--dofile(minetest.get_modpath("solarsail").."/hud.lua")
	
	-- Cameras used in dialog, cutscenes or when controlled by the player:
	
	--dofile(minetest.get_modpath("solarsail").."/camera.lua")
	
	-- Start skybox engine:
	
	dofile(minetest.get_modpath("solarsail").."/skybox.lua")
	
	-- Control handling for HUDs, player entity, etc:
	
	dofile(minetest.get_modpath("solarsail").."/control.lua")
	
	-- Third person player camera handling + third person model:
	
	dofile(minetest.get_modpath("solarsail").."/player.lua")
	
	-- Basic, advanced NPC AI;
	
	--dofile(minetest.get_modpath("solarsail").."/npc.lua")
	
	-- Player menus:
	
	--dofile(minetest.get_modpath("solarsail").."/menu.lua")
end

