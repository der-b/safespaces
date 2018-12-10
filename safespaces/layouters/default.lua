--
-- basic layout algorithm
--

-- stores the tile information
local tiles = {};


-- access tiles by coordinates
-- x = 0, y = 0 is the center tile
local function getTile(x, y) 
	x = x - tiles["x_min"];
	y = y - tiles["y_min"];
	if (nil == tiles[x * tiles["array_x_size"] + y]) then
		tiles[x * tiles["array_x_size"] + y] = {};
	end
	return tiles[x * tiles["array_x_size"] + y];
end


-- initialize tiles
local function initTiles()
	if (nil ~= tiles["inited"]) then
		print("already inited");
		return;
	end

	tiles["inited"] = true;

	tiles["x_max"] = 1;
	tiles["x_min"] = -1;
	tiles["y_max"] = 1;
	tiles["y_min"] = -1;

	tiles["array_x_size"] = tiles["x_max"] - tiles["x_min"] + 1;
	tiles["array_y_size"] = tiles["y_max"] - tiles["y_min"] + 1;

	for x = tiles["x_min"], tiles["x_max"], 1 do
		for y = tiles["y_min"], tiles["y_max"], 1 do 
			t = getTile(x, y);
			t["model"] = nil;
			t["offset_x"] = x;
			t["offset_y"] = y;
			t["enable"] = not ((x == y or x == -y) and x ~= 0);
			t["tiles"] = tiles;
		end
	end

	tiles["tile_dist_x"] = 65 * (math.pi/180);
	tiles["tile_dist_y"] = 65 * (math.pi/180);
	
	tiles["notTiled"] = {};

	tiles["getTile"] = getTile;

	tiles["swapNotTiled"] = function()
		if (nil ~= tiles["notTiled"][1]) then
			local tmp = getTile(0,0)["model"];
			getTile(0, 0)["model"] = tiles["notTiled"][1];
			getTile(0, 0)["model"]["active"] = true;
			getTile(0, 0)["model"]["tile"] = getTile(0, 0);
			tiles["notTiled"][1] = tmp;
			tmp["tile"] = nil;
			tmp["active"] = false;
		end
	end

	tiles["rotateNotTiledLeft"] = function()
		local tmp; 
		print("rotateNotTiledLeft");
		if (2 <= #tiles["notTiled"]) then
			tmp = table.remove(tiles["notTiled"]);
			table.insert(tiles["notTiled"], 1, tmp);
		end
	end

	tiles["rotateNotTiledRight"] = function()
		local tmp; 
		print("rotateNotTiledLeft");
		if (2 <= #tiles["notTiled"]) then
			tmp = table.remove(tiles["notTiled"], 1);
			table.insert(tiles["notTiled"], tmp);
		end
	end

	tiles["toRight"] = function() 
		if (getTile(-1, 0)["model"]) then
			local tmp = getTile(0, 0)["model"];
			getTile(0, 0)["model"] = getTile(-1, 0)["model"];
			getTile(-1, 0)["model"] = tmp;
			getTile(0, 0)["model"]["tile"] = getTile(0, 0);
			getTile(-1, 0)["model"]["tile"] = getTile(-1, 0);
			tmp["active"] = false;
			getTile(0, 0)["model"]["active"] = true;
		end
	end

	tiles["toLeft"] = function() 
		if (getTile(1, 0)["model"]) then
			local tmp = getTile(0, 0)["model"];
			getTile(0, 0)["model"] = getTile(1, 0)["model"];
			getTile(1, 0)["model"] = tmp;
			getTile(0, 0)["model"]["tile"] = getTile(0, 0);
			getTile(1, 0)["model"]["tile"] = getTile(1, 0);
			tmp["active"] = false;
			getTile(0, 0)["model"]["active"] = true;
		end
	end

	tiles["toUp"] = function() 
		if (getTile(0, -1)["model"]) then
			local tmp = getTile(0, 0)["model"];
			getTile(0, 0)["model"] = getTile(0, -1)["model"];
			getTile(0, -1)["model"] = tmp;
			getTile(0, 0)["model"]["tile"] = getTile(0, 0);
			getTile(0, -1)["model"]["tile"] = getTile(0, -1);
			tmp["active"] = false;
			getTile(0, 0)["model"]["active"] = true;
		end
	end

	tiles["toDown"] = function() 
		if (getTile(0, 1)["model"]) then
			local tmp = getTile(0, 0)["model"];
			getTile(0, 0)["model"] = getTile(0, 1)["model"];
			getTile(0, 1)["model"] = tmp;
			getTile(0, 0)["model"]["tile"] = getTile(0, 0);
			getTile(0, 1)["model"]["tile"] = getTile(0, 1);
			tmp["active"] = false;
			getTile(0, 0)["model"]["active"] = true;
		end
	end

	tiles["destroy"] = function(model)
		if (getTile(0, 0)["model"] == model) then
			model["tile"] = nil;
			model["known"] = false;
			getTile(0, 0)["model"] = nil;
			
			if (1 <= #tiles["notTiled"]) then
				getTile(0, 0)["model"] = table.remove(tiles["notTiled"], 1);
				getTile(0, 0)["model"]["active"] = true;
				getTile(0, 0)["model"]["tile"] = getTile(0, 0);
				
			else
				for i = 8, 0, -1 do
					if (nil ~= tiles[i]["model"]) then 
						getTile(0, 0)["model"] = tiles[i]["model"];
						getTile(0, 0)["model"]["tile"] = getTile(0, 0);
						tiles[i]["model"] = nil;
						break;
					end
				end
			end
		else
			local pos = table.find_i(tiles["notTiled"], model);
			if (type(pos) == "number") then
				table.remove(tiles["notTiled"], pos);
			else
				for i = 8, 0, -1 do
					if (model == tiles[i]["model"]) then 
						tiles[i]["model"]["tile"] = nil;
						tiles[i]["model"] = nil;
						break;
					end
				end
			end
		end
	end
end




return function(layer)
	print("---------------------------------");
	print("---------- relayouting ----------");
	print("---------------------------------");
	initTiles();
	if (layer.fixed) then
		return;
	end

-- 1. separate models that have parents and root models
	local root = {};
	local chld = {};
	for _,v in ipairs(layer.models) do
		if not v.parent then
			table.insert(root, v);
		else
			chld[v.parent] = chld[v.parent] and chld[v.parent] or {};
			table.insert(chld[v.parent], v);
			if (v["tile"]) then
				v["tile"]["model"] = nil;
				v["tile"] = nil;
				v["known"] = false;
			end
		end
	end

-- make sure we have one element that is selected and visible
	if (not layer.selected) then
		for i,v in ipairs(root) do
			if (v.active) then
				v:select();
				if (nil == getTile(0, 0)["model"]) then
					v["tile"] = getTile(0, 0);
					v["tile"]["model"] = v;
				end
				break;
			end
		end
	end


	local max_h = 0;
	local h_pi = math.pi * 0.5;

	local function getang(phi)
		phi = math.fmod(-phi + 0.5*math.pi, 2 * math.pi);
		return math.deg(phi);
	end

	local dphi_ccw = h_pi;
	local dphi_cw = h_pi;
	local function ptoc(phi)
		return
			-layer.radius * math.cos(phi),
			-layer.radius * math.sin(phi);
	end

	local as = layer.ctx.animation_speed;
	local in_first = true;

	for i,v in ipairs(root) do
		if (not v["known"]) then
			v["known"] = true;
			if (nil == v["tile"]) then
				for i = 0, 8, 1 do
					if (nil == tiles[i]["model"] and tiles[i]["enable"]) then 
						tmp = getTile(0, 0)["model"];
						v["tile"] = getTile(0, 0);
						v["tile"]["model"] = v;
						if (tmp) then
							tmp["tile"] = tiles[i];
							tmp["tile"]["model"] = tmp;
						end
						break;
					end
				end
			end

			if (not v["tile"]) then
				tmp = getTile(0, 0)["model"];
				v["tile"] = getTile(0, 0);
				v["tile"]["model"] = v;
				table.insert(tiles["notTiled"], 1, tmp);
				tmp["tile"] = nil;
			end
		end
	end

	for i,v in ipairs(root) do

-- get scaled model size
		local w,h, _ = v:get_size();
		local x = 0;
		local z = 0;
		local y = 0;
		local ang_x = 0;
		local ang_y = 0;
		local ang_z = 0;
		local mpx, mpz = ptoc(h_pi);

-- find the bounding points
		local p1x = mpx - 0.5 * (w + layer.spacing);
		local p2x = mpx + 0.5 * (w + layer.spacing);

-- get half-arc length
		local p1p = math.atan(p1x / mpz);
		local p2p = math.atan(p2x / mpz);
		local half_len = 0.5 * (p2p - p1p);

		ang = 0;
		if (v["tile"]) then
			z = math.cos(tiles["tile_dist_x"] * v["tile"]["offset_x"]) * math.cos(tiles["tile_dist_y"] * v["tile"]["offset_y"]) * -layer.radius;
			x = math.sin(tiles["tile_dist_x"] * v["tile"]["offset_x"]) * -layer.radius;
			y = math.sin(tiles["tile_dist_y"] * v["tile"]["offset_y"]) * -layer.radius;
			ang_z =  (tiles["tile_dist_x"] * v["tile"]["offset_x"] * 180) / math.pi;
			ang_y = -(tiles["tile_dist_y"] * v["tile"]["offset_y"] * 180) / math.pi;
			print("----------------------" .. v.name .. "------------------------------");
			print("x " .. x);
			print("y " .. y);
			print("z " .. z);
			print("abs " .. math.sqrt(x * x + y * y + z * z));
			print("ang_x " .. ang_x);
			print("ang_y " .. ang_y);
			print("ang_z " .. ang_z);
			print("----------------------------------------------------");
		else
			local r = 10;
			local x_off = 35;
			local y_off = 35;
			local z_off = - 9;
			local to_cam = - math.pi + math.tan(z_off/x_off);
			local part = 2 * math.pi / #tiles["notTiled"];
			local pos = (table.find_i(tiles["notTiled"], v) - 1) * part + math.pi;
			x = math.cos(pos) * r + x_off;
			y = y_off;
			z = math.sin(pos) * r + z_off - 1;
			ang_z = getang(to_cam);
		end

		if (math.abs(v.layer_pos[1] - x) ~= 0.0001) or
			(math.abs(v.layer_pos[2] - y) ~= 0.0001) or
			(math.abs(v.layer_pos[3] - z) ~= 0.0001) then

			move3d_model(v.vid, x, y, z, as);
			rotate3d_model(v.vid,
				ang_x, ang_y, ang_z,
				as
			);

			--local sx, sy, sz = v:get_scale();
			--scale3d_model(v.vid, sx, sy, 1, as);
		end

		if (v == getTile(0,0)["model"]) then
			v:select();
		end

		v.layer_pos = {x, y, z};
	end

-- avoid linking to stay away from the cascade deletion problem, if it needs
-- to be done for animations, then take the delete- and set a child as the
-- new parent.
	for k,v in pairs(chld) do
		if (k == getTile(0, 0)["model"]) then
			for i,m in pairs(v) do
				local ang_x = 0;
				local ang_y = 0;
				local r = 10;
				local x_off = -35;
				local y_off = 35;
				local z_off = - 9;
				local to_cam = math.tan(z_off/x_off);
				local part = 2 * math.pi / #v;
				local pos = (i - 1) * part + math.pi;
				x = math.cos(pos) * r + x_off;
				y = y_off;
				z = math.sin(pos) * r + z_off - 1;
				ang_z = getang(to_cam);

				move3d_model(m.vid, x, y, z, as);
				rotate3d_model(m.vid,
					ang_x, ang_y, ang_z,
					as
				);

				local sx, sy, sz = m:get_scale();
				scale3d_model(m.vid, sx, sy, 1, as);
			end
		else
			local x = 100;
			local y = 100;
			local z = 100;
			for i,m in pairs(v) do
				move3d_model(m.vid, x, y, z, as);
				rotate3d_model(m.vid, 0, 0, 0, as);
			end
		end

--		local dz = 0.0;
--		local lp = k.layer_pos;
--		local la = k.layer_ang;
--		local of_y = 0;
--
---- note that there is no vertical billboarding here, the idea being that you
---- only need peripheral visual queue to know if you want to swap up / down
--		local pw, ph, pd = k:get_size();
--		local mf = k.merged and 0.1 or 1;
--
---- starts at half- old, then apply half new (they may have different scaling)
--		of_y = ph;
--		for i=1,#v,2 do
--			local j = v[i];
--			rotate3d_model(j.vid, 0, 0, la, as)
--			local sx, sy, sz = j:get_scale();
--			scale3d_model(j.vid, sx, sy, 1, as);
--			if (j.active) then
--				pw, ph, pd = j:get_size();
--				of_y = of_y + mf * (ph + layer.vspacing);
--				move3d_model(j.vid, lp[1], lp[2] + of_y, lp[3] - dz, as);
--				dz = dz + 0.01;
--			end
--		end
--
--		local pw, ph, pd = k:get_size();
--		of_y = ph + layer.vspacing;
--		dz = 0.0;
--
--		for i=2,#v,2 do
--			local j = v[i];
--			rotate3d_model(j.vid, 0, 0, la, as)
--			local sx, sy, sz = j:get_scale();
--			scale3d_model(j.vid, sx, sy, 1, as);
--			if (j.active) then
--				pw, ph, pd = j:get_size();
--				of_y = of_y + mf * (ph + layer.vspacing);
--				move3d_model(j.vid, lp[1], lp[2] - of_y, lp[3] - dz, as);
--				dz = dz + 0.01;
--			end
--		end

	end
end
