-- painting - in-game painting for minetest

-- THIS MOD CODE AND TEXTURES LICENSED
--						<3 TO YOU <3
--		UNDER TERMS OF WTFPL LICENSE

-- 2012, 2013, 2014 obneq aka jin xi

-- picture is drawn using a nodebox to draw the canvas
-- and an entity which has the painting as its texture.
-- this texture is created by minetests internal image
-- compositing engine (see tile.cpp).

-- Edited by Jasper den Ouden (a few commits now)

dofile(minetest.get_modpath("painting").."/crafts.lua")

local textures = {
	white = "white.png", yellow = "yellow.png",
	orange = "orange.png", red = "red.png",
	violet = "violet.png", blue = "blue.png",
	green = "green.png", magenta = "magenta.png",
	cyan = "cyan.png", grey = "grey.png",
	darkgrey = "darkgrey.png", black = "black.png",
	darkgreen = "darkgreen.png", brown="brown.png",
	pink = "pink.png"
}

local colors = {}

local revcolors = {
   "darkgreen", "magenta", "blue", "cyan", "grey", "red", "pink", "darkgrey",
   "violet", "black", "green", "brown", "yellow", "orange", "white",
}

local thickness = 0.1

-- picture node
local picbox = {
	type = "fixed",
	fixed = { -0.499, -0.499, 0.499, 0.499, 0.499, 0.499 - thickness }
}

-- Initiate a white grid.
local function initgrid(res)
	local grid, a, x, y = {}, res-1
	for x = 0, a do
		grid[x] = {}
		for y = 0, a do
			grid[x][y] = colors["white"]
		end
	end
	return grid
end

local function to_imagestring(data, res)
	if not data then return end
	local t,n = {"[combine:", res, "x", res, ":"},6
	for y = 0, res - 1 do
		for x = 0, res - 1 do
       t[n] = x..","..y.."=".. (revcolors[ data[x][y] ] or "white") ..".png:"
			n = n+1
		end
	end
	return table.concat(t)
end

local function dot(v, w)  -- Inproduct.
	return	v.x * w.x + v.y * w.y + v.z * w.z
end

local function intersect(pos, dir, origin, normal)
	local t = -(dot(vector.subtract(pos, origin), normal)) / dot(dir, normal)
	return vector.add(pos, vector.multiply(dir, t))
end

local function clamp(x, min,max)
   return math.max(math.min(x, max),min)
end

minetest.register_node("painting:pic", {
	description = "Picture",
	tiles = { "white.png" },
	inventory_image = "painted.png",
	drawtype = "nodebox",
	sunlight_propagates = true,
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = picbox,
	selection_box = picbox,
	groups = { snappy = 2, choppy = 2, oddly_breakable_by_hand = 2,
             not_in_creative_inventory=1},

	--handle that right below, don't drop anything
	drop = "",

	after_dig_node=function(pos, _, oldmetadata, digger)
		--find and remove the entity
		for _,e in pairs(minetest.get_objects_inside_radius(pos, 0.5)) do
			if e:get_luaentity().name == "painting:picent" then
				e:remove()
			end
		end

		--put picture data back into inventory item
		digger:get_inventory():add_item("main", {
			name = "painting:paintedcanvas",
			count = 1,
			metadata = oldmetadata.fields["painting:picturedata"]
		})
	end
})

-- picture texture entity
minetest.register_entity("painting:picent", {
	collisionbox = { 0, 0, 0, 0, 0, 0 },
	visual = "upright_sprite",
	textures = { "white.png" },

	on_activate = function(self, staticdata)
		local pos = self.object:getpos()
		local meta = minetest.get_meta(pos)
		local data = minetest.deserialize(meta:get_string("painting:picturedata"))
		if data and data.grid then
       self.object:set_properties{textures = { to_imagestring(data.grid, data.res) }}
    end
	end
})

-- Figure where it hits the canvas, in fraction given position and direction.
local function figure_paint_pos_raw(pos, d,od, ppos, l)
   --get player eye level, see player.h line 129
   local player_eye_h = 1.625
  ppos.y = ppos.y + player_eye_h

  local normal = { x = d.x, y = 0, z = d.z }
  local p = intersect(ppos, l, pos, normal)

  local off = -0.5
  pos = vector.add(pos, {x=off*od.x, y=off, z=off*od.z})
  p = vector.subtract(p, pos)
  return math.abs(p.x + p.z), 1 - p.y
end

local dirs = {  -- Directions the painting may be.
	[0] = { x = 0, z = 1 },
	[1] = { x = 1, z = 0 },
	[2] = { x = 0, z =-1 },
	[3] = { x =-1, z = 0 }
}
-- .. idem .. given self and puncher.
local function figure_paint_pos(self, puncher)
   local x,y = figure_paint_pos_raw(self.object:getpos(),
                                    dirs[self.fd], dirs[(self.fd + 1) % 4],
                                    puncher:getpos(), puncher:get_look_dir())
   return math.floor(self.res*clamp(x, 0, 1)), math.floor(self.res*clamp(y, 0, 1))
end

local function draw_input(self, name, x,y, as_line)
   local x0 = self.x0
   if as_line and x0 then -- Draw line if requested *and* have a previous position.
      local y0 = self.y0
      local line = vector.twoline(x0-x, y0-y)  -- This figures how to do the line.
      for _,coord in pairs(line) do
         self.grid[x+coord[1]][y+coord[2]] = colors[name]
      end
   else  -- Draw just single point.
      self.grid[x][y] = colors[name]
   end
   self.x0, self.y0 = x, y -- Update previous position.
   -- Actually update the grid.
   self.object:set_properties{textures = { to_imagestring(self.grid, self.res) }}
end

local paintbox = {
	[0] = { -0.5,-0.5,0,0.5,0.5,0 },
	[1] = { 0,-0.5,-0.5,0,0.5,0.5 }
}

-- Painting as being painted.
minetest.register_entity("painting:paintent", {
	collisionbox = { 0, 0, 0, 0, 0, 0 },
	visual = "upright_sprite",
	textures = { "white.png" },

	on_punch = function(self, puncher)
		--check for brush.
     local name = string.match(puncher:get_wielded_item():get_name(), "_([^_]*)")
     if not textures[name] then  -- Not one of the brushes; can't paint.
        return
     end

     assert(self.object)
     local x,y = figure_paint_pos(self, puncher)
     draw_input(self, name, x,y, puncher:get_player_control().sneak)

     local wielded = puncher:get_wielded_item()  -- Wear down the tool.
     wielded:add_wear(65535/256)
     puncher:set_wielded_item(wielded)
	end,

	on_activate = function(self, staticdata)
		local data = minetest.deserialize(staticdata)
		if not data then
			return
		end
		self.fd = data.fd
		self.x0, self.y0 = data.x0, data.y0
		self.res = data.res
		self.grid = data.grid
		self.object:set_properties{ textures = { to_imagestring(self.grid, self.res) }}
		if not self.fd then
			return
		end
		self.object:set_properties{ collisionbox = paintbox[self.fd%2] }
		self.object:set_armor_groups{immortal=1}
	end,

	get_staticdata = function(self)
     local data = { fd = self.fd, res = self.res, grid = self.grid,
                    x0 = self.x0, y0 = self.y0 }
     return minetest.serialize(data)
	end
})

-- just pure magic
local walltoface = {-1, -1, 1, 3, 0, 2}

--paintedcanvas picture inventory item
minetest.register_craftitem("painting:paintedcanvas", {
	description = "Painted Canvas",
	inventory_image = "painted.png",
	stack_max = 1,
	groups = { snappy = 2, choppy = 2, oddly_breakable_by_hand = 2, not_in_creative_inventory=1 },

	on_place = function(itemstack, placer, pointed_thing)
		--place node
		local pos = pointed_thing.above
		if minetest.is_protected(pos, placer:get_player_name()) then
			return
		end

		local under = pointed_thing.under

		local wm = minetest.dir_to_wallmounted(vector.subtract(under, pos))

		local fd = walltoface[wm + 1]
		if fd == -1 then
			return itemstack
		end

		minetest.add_node(pos, {name = "painting:pic", param2 = fd})

		--save metadata
		local data = itemstack:get_metadata()
		minetest.get_meta(pos):set_string("painting:picturedata", data)

		--add entity
		dir = dirs[fd]
		local off = 0.5 - thickness - 0.01

		pos.x = pos.x + dir.x * off
		pos.z = pos.z + dir.z * off

		data = minetest.deserialize(data)

		local p = minetest.add_entity(pos, "painting:picent"):get_luaentity()
		p.object:set_properties{ textures = { to_imagestring(data.grid, data.res) }}
		p.object:setyaw(math.pi * fd / -2)

		return ItemStack("")
	end
})

--canvas inventory items
for i = 4,6 do
	minetest.register_craftitem("painting:canvas_"..2^i, {
    description = "Canvas(" .. 2^i .. ")",
		inventory_image = "default_paper.png",
		stack_max = 99,
	})
end

--canvas for drawing
local canvasbox = {
	type = "fixed",
	fixed = { -0.5, -0.5, 0, 0.5, 0.5, thickness }
}

minetest.register_node("painting:canvasnode", {
	description = "Canvas",
	tiles = { "white.png" },
	inventory_image = "painted.png",
	drawtype = "nodebox",
	sunlight_propagates = true,
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = canvasbox,
	selection_box = canvasbox,
	groups = { snappy = 2, choppy = 2, oddly_breakable_by_hand = 2,
             not_in_creative_inventory=1 },

	drop = "",

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		--get data and remove pixels
		local data = {}
		for _,e in pairs(minetest.get_objects_inside_radius(pos, 0.1)) do
			e = e:get_luaentity()
			if e.grid then
				data.grid = e.grid
				data.res = e.res
			end
			e.object:remove()
		end

		pos.y = pos.y-1
		minetest.get_meta(pos):set_int("has_canvas", 0)

		if data.grid then
			local item = { name = "painting:paintedcanvas", count = 1,
                     metadata = minetest.serialize(data) }
			digger:get_inventory():add_item("main", item)
		end
	end
})

local easelbox = { -- Specifies 3d model.
	type = "fixed",
	fixed = {
		--feet
		{-0.4, -0.5, -0.5, -0.3, -0.4, 0.5 },
		{ 0.3, -0.5, -0.5,	0.4, -0.4, 0.5 },
		--legs
		{-0.4, -0.4, 0.1, -0.3, 1.5, 0.2 },
		{ 0.3, -0.4, 0.1,	0.4, 1.5, 0.2 },
		--shelf
		{-0.5, 0.35, -0.3, 0.5, 0.45, 0.1 }
	}
}

minetest.register_node("painting:easel", {
	description = "Easel",
	tiles = { "default_wood.png" },
	drawtype = "nodebox",
	sunlight_propagates = true,
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = easelbox,
	selection_box = easelbox,

	groups = { snappy = 2, choppy = 2, oddly_breakable_by_hand = 2 },

	on_punch = function(pos, node, player)
    local wield_name = player:get_wielded_item():get_name()
    local name, res = string.match(wield_name, "^([^_]+)_([^_]+)")
		if name ~= "painting:canvas" then  -- Can only put the canvas on there.
			return
		end

		pos.y = pos.y+1
		if minetest.get_node(pos).name ~= "air" then
			return
		end
		local fd = node.param2
		minetest.add_node(pos, { name = "painting:canvasnode", param2 = fd})

		local dir = dirs[fd]
		pos.x = pos.x - 0.01 * dir.x
		pos.z = pos.z - 0.01 * dir.z

		local p = minetest.add_entity(pos, "painting:paintent"):get_luaentity()
		p.object:set_properties{ collisionbox = paintbox[fd%2] }
		p.object:set_armor_groups{immortal=1}
		p.object:setyaw(math.pi * fd / -2)
		local res = tonumber(res) -- Was still string from matching.
		p.grid = initgrid(res)
		p.res = res
		p.fd = fd

		minetest.get_meta(pos):set_int("has_canvas", 1)
		local itemstack = ItemStack(wielded_raw)
		player:get_inventory():remove_item("main", itemstack)
	end,

	can_dig = function(pos)
		return minetest.get_meta(pos):get_int("has_canvas") == 0
	end
})

--brushes
local function table_copy(t)
	local t2 = {}
	for k,v in pairs(t) do
		t2[k] = v
	end
	return t2
end

local brush = {
	wield_image = "",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=0,
		groupcaps = {}
	}
}

for color, _ in pairs(textures) do
--	table.insert(revcolors, color) -- I don't think you should depend on `pairs` order.
	local brush_new = table_copy(brush)
	brush_new.description = color:gsub("^%l", string.upper).." brush"
	brush_new.inventory_image = "painting_brush_"..color..".png"
	minetest.register_tool("painting:brush_"..color, brush_new)
	minetest.register_craft{
		output = "painting:brush_"..color,
		recipe = {
			{"dye:"..color},
			{"default:stick"},
			{"default:stick"}
		}
	}
end

for i, color in ipairs(revcolors) do
	colors[color] = i
end

minetest.register_alias("easel", "painting:easel")
minetest.register_alias("canvas", "painting:canvas_16")

--[[ allows using many colours, doesn't work
function to_imagestring(data, res)
	if not data then
		return
	end
	local t,n = {},1
	local sbc = {}
	for y = 0, res - 1 do
		for x = 0, res - 1 do
			local col = revcolors[data[x][y] ]
			sbc[col] = sbc[col] or {}
			sbc[col][#sbc[col] ] = {x,y}
		end
	end
	for col,ps in pairs(sbc) do
		t[n] = "([combine:"..res.."x"..res..":"
		n = n+1
		for _,p in pairs(ps) do
			t[n] = p[1]..","..p[2].."=white.png:"
			n = n+1
		end
		t[n-1] = string.sub(t[n-1], 1,-2)
		t[n] = "^[colorize:"..col..")^"
		n = n+1
	end
	t[n-1] = string.sub(t[n-1], 1,-2)
	return table.concat(t)
end--]]
