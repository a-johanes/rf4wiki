------- l10n info --------------
local l10n_info = mw.loadData('Module:Recipes/l10n')

------- The following is not related to l10n. --------------


local item_link = require('Module:Item').go
local trim = mw.text.trim
local cargo = mw.ext.cargo
local cache = require 'mw.ext.LuaCache'

local currentFrame -- global cache for current frame object.
local inputArgs -- global args cache.
local lang -- cache current lang.
local l10n_table

local resultanchor

local l10n = function(key)
	return l10n_table[key] or l10n_info['en'][key]
end

local extCols_stationBefore = nil
local extCols_stationAfter = nil

local extCols_A = nil
local extCols_B = nil
local extCols_C = nil
local extCols_D = nil

function getArg(key)
	local v = trim(inputArgs[key] or '')
	if v=='' then
		return nil
	else
		return v
	end
end

local itemLink = (function()
	local cache = {}
	return function(name, args)
		local key = name.."|"
		if args then
			for k, v in pairs(args) do
				key = key..k..'='..tostring(v)..'|'
			end
		end
		if not cache[key] then
			local args = args and mw.clone(args) or {}
			args[1] = name
			if (not args[2]) or args[2]=='' then
				args[2] = currentFrame:expandTemplate{ title = 'tr', args = {name, lang=lang} }
			end
			args['small'] = 'y'
			args['lang'] = lang or 'en'
			args['nolink'] = args['nolink'] and 'y' or nil
			cache[key] = item_link(currentFrame, args)
		end
		return cache[key]
	end
end)()

-- credit: http://richard.warburton.it
-- this version is with trim.
local explode = function(div,str)
	if (div=='') then return false end
	local pos,arr = 0,{}
	-- for each divider found
	for st,sp in function() return string.find(str,div,pos,true) end do
		table.insert(arr, trim(string.sub(str,pos,st-1))) -- Attach chars left of current divider
		pos = sp + 1 -- Jump past current divider
	end
	table.insert(arr, trim(string.sub(str,pos))) -- Attach chars right of last divider
	return arr
end

-- retuan a array of itemname, split xxx/yyy to item1=xxx, item2=yyy. If it's something like "Lead/Iron Bar", it will normalize as item1 = Iron Bar, item2 = Lead Bar.
local split = (function()
	local metals = {
		['Copper/Tin'] = 1,
		['Silver/Tungsten'] = 1,
		['Gold/Platinum'] = 1,
		['Iron/Lead'] = 1,
		['Cobalt/Palladium'] = 1,
		['Mythril/Orichalcum'] = 1,
		['Adamantite/Titanium'] = 1,
		['Tin/Copper'] = 2,
		['Tungsten/Silver'] = 2,
		['Platinum/Gold'] = 2,
		['Lead/Iron'] = 2,
		['Palladium/Cobalt'] = 2,
		['Orichalcum/Mythril'] = 2,
		['Titanium/Adamantite'] = 2,
	}
	return function(name)
		local count = select(2, name:gsub("/", "/", 2))
		if count == 0 then
			-- only 1 item
			return { trim(name) }
		elseif count == 1 then
			-- 2 items
			local item1a, item1b, item2a, item2b = name:match("^%s*(%S+)%s*(.-)/%s*(%S+)%s*(.-)$")
			local x = metals[item1a..'/'..item2a]
			if tostring(item1b) == '' and x then
				item1b = item2b
			end
			if x == 2 then
				return {trim(item2a..' '..item2b), trim(item1a..' '..item1b)}
			else
				return {trim(item1a..' '..item1b), trim(item2a..' '..item2b)}
			end
		else
			-- 3 or more items
			return explode('/', name)
		end
	end
end)()

-- return 1 or 2 value(s), when input is name[note], return item, note.
local itemname = function(str)
		local item, note = str:match("^(.-)(%b[])$")
		if item then
			return item, note
		else
			return str
		end
end

-- normalize ingredient name input, Lead Bar=>¦Lead Bar¦, Iron/Lead Bar => ¦Iron Bar¦Lead Bar¦, Lead/Iron Bar => ¦Iron Bar¦Lead Bar¦ ....
local normalize = function(name)
	local result = '¦'
	for k, v in ipairs(split(name)) do
		result = result .. itemname(v) .. '¦'
	end
	return result
end

local escape = function(str)
	return str:gsub("'", "\\'"):gsub("&#39;", "\\'")
end
local enclose = function(str)
	return "'" .. escape(str) .. "'"
end

local getItemGroupName = function(item)
	if item == 'Wood' or item == 'Ebonwood' or item == 'Rich Mahogany' or item == 'Pearlwood' or item == 'Shadewood'
	or item == 'Spooky Wood' or item == 'Boreal Wood' or item == 'Palm Wood' then
		return 'Any Wood'
	elseif item == 'Iron Bar' or item == 'Lead Bar' then
		return 'Any Iron Bar'
	elseif item == 'Sand Block' or item == 'Pearlsand Block' or item == 'Crimsand Block' or item == 'Ebonsand Block' or item == 'Hardened Sand Block' or item == 'Hardened Ebonsand Block' or item == 'Hardened Crimsand Block' or item == 'Hardened Pearlsand Block' then
		return 'Any Sand'
	elseif item == 'Red Pressure Plate' or item == 'Green Pressure Plate' or item == 'Gray Pressure Plate' or item == 'Brown Pressure Plate'
	    or item == 'Blue Pressure Plate' or item == 'Yellow Pressure Plate' or item == 'Lihzahrd Pressure Plate' then
		return 'Any Pressure Plate'
	elseif item == 'Bird' or item == 'Blue Jay' or item == 'Cardinal' then
		return 'Any Bird'
	elseif item == 'Black Scorpion' or item == 'Scorpion' then
		return 'Any Scorpion'
	elseif item == 'Squirrel' or item == 'Red Squirrel' then
		return 'Any Squirrel'
	elseif item == 'Grubby' or item == 'Sluggy' or item == 'Buggy' then
		return 'Any Jungle Bug'
	elseif item == 'Mallard Duck' or item == 'Duck' then
		return 'Any Duck'
	elseif item == 'Sulphur Butterfly' or item == 'Julia Butterfly' or item == 'Monarch Butterfly' or item == 'Purple Emperor Butterfly'
	    or item == 'Red Admiral Butterfly' or item == 'Tree Nymph Butterfly' or item == 'Ulysses Butterfly' or item == 'Zebra Swallowtail Butterfly' then
		return 'Any Butterfly'
	elseif item == 'Firefly' or item == 'Lightning Bug' then
		return 'Any Firefly'
	elseif item == 'Snail' or item == 'Glowing Snail' then
		return 'Any Snail'
	elseif item == 'Apple' or item == 'Apricot' or item == 'Banana' or item == 'Blackcurrant' or item == 'Blood Orange' or item == 'Cherry' or item == 'Coconut' 
		or item == 'Dragon Fruit' or item == 'Elderberry' or item == 'Grapefruit' or item == 'Lemon' or item == 'Mango' or item == 'Peach' 
		or item == 'Pineapple' or item == 'Plum' or item == 'Rambutan' or item == 'Star Fruit' then
		return 'Any Fruit'
	elseif item == 'Black Dragonfly' or item == 'Blue Dragonfly' or item == 'Green Dragonfly' or item == 'Orange Dragonfly'
		or item == 'Red Dragonfly' or item == 'Yellow Dragonfly' then
		return 'Any Dragonfly'
	elseif item == 'Turtle' or item == 'Jungle Turtle' then
		return 'Any Turtle'
	end
end

local normalizeStation = function(station)
	if station == 'Altar' then
		station = 'Demon Altar'
	end
	return station
end

local normalizeVersion = function(_version)
	local _version = trim(_version):lower()
	local version = ''
	if _version:find('desktop', 1, true) then
		version = version .. ' desktop'
	end
	if _version:find('console', 1, true) then
		version = version .. ' console'
	end
	if _version:find('old-gen', 1, true) then
		version = version .. ' old-gen'
	end
	if _version:find('japan', 1, true) then
		version = version .. ' japan'
	end
	if _version:find('mobile', 1, true) then
		version = version .. ' mobile'
	end
	if _version:find('3ds', 1, true) then
		version = version .. ' 3ds'
	end
	if _version:find('switch', 1, true) then
		version = version .. ' switch'
	end
	if _version:find('tmodloader', 1, true) then
		version = version .. ' tmodloader'
	end
	if version == ' desktop console old-gen mobile 3ds switch tmodloader' then
		version = ''
	end
	return trim(version)
end

local criStr = function(args)
	local constraints = {}
	-- station = ? and station != ?
	local _station = trim(args['station'] or '')
	local _stationnot = trim(args['stationnot'] or '')
	local str = ''
	if _station ~= '' then
		for _, v in ipairs(explode('/', _station)) do
			if str ~= '' then
				str = str .. ' OR '
			end
			str = str .. "station = " .. enclose(normalizeStation(v))
		end
	end
	if _stationnot ~= '' then
		if str ~= '' then
			str = '(' .. str .. ')'
		end
		for _, v in ipairs(explode('/', _stationnot)) do
			if str ~= '' then
				str = str .. ' AND '
			end
			str = str .. 'station <> ' .. enclose(normalizeStation(v))
		end
	end
	constraints['station'] = str
	-- result = ? and result != ?
	local _result = trim(args['result'] or '')
	local _resultnot = trim(args['resultnot'] or '')
	local str = ''
	if _result ~= '' then
		for _, v in ipairs(explode('/', _result)) do
			if str ~= '' then
				str = str .. ' OR '
			end
			if mw.ustring.sub(v, 1, 5) == 'LIKE ' then
				str = str .. "result LIKE " .. enclose(trim(mw.ustring.sub(v, 6)))
			else
				str = str .. 'result=' .. enclose(v)
			end
		end
	end
	if _resultnot ~= '' then
		if str ~= '' then
			str = '(' .. str .. ')'
		end
		for _, v in ipairs(explode('/', _resultnot)) do
			if str ~= '' then
				str = str .. ' AND '
			end
			if mw.ustring.sub(v, 1, 5) == 'LIKE ' then
				str = str .. "result NOT LIKE " .. enclose(trim(mw.ustring.sub(v, 6)))
			else
				str = str .. 'result <> ' .. enclose(v)
			end
		end
	end
	if str ~= '' then
		constraints['result'] = str
	end
	-- ingredient = ?
	local _ingredient = trim(args['ingredient'] or '')
	if _ingredient ~= '' then
		local str = ''
		for _, v in ipairs(explode('/', _ingredient)) do
			if str ~= '' then
				str = str .. ' OR '
			end
			if mw.ustring.sub(v, 1, 1) == '#' then
				str = str .. "ingredients HOLDS LIKE '%¦" .. escape(mw.ustring.sub(v, 2)) .. "¦%'"
			elseif mw.ustring.sub(v, 1, 5) == 'LIKE ' then
				str = str .. "ingredients HOLDS LIKE '%¦" .. escape(trim(mw.ustring.sub(v, 6))) .. "¦%'"
			else
				str = str .. "ingredients HOLDS LIKE '%¦" .. escape(v) .. "¦%'"
				-- any xxx
				local group = getItemGroupName(v)
				if group then
					str = str .. " OR ingredients HOLDS LIKE '%¦" .. escape(group) .. "¦%'"
				end
			end
		end
		constraints['ingredient'] = str
	end

	--versions
	local _version = normalizeVersion(args['version'] or args['versions'] or '')
	if _version ~= '' then
		constraints['version'] = 'version = '..enclose(_version)
	end

	local where = ''
	if constraints['station'] then
		where = constraints['station']
	end
	if constraints['result'] then
		if where ~= '' then
			where = where .. ' AND '
		end
		where = where .. '(' .. constraints['result'] .. ')'
	end
	if constraints['ingredient'] then
		if where ~= '' then
			where = where .. ' AND '
		end
		where = where .. '(' .. constraints['ingredient'] .. ')'
	end
	if constraints['version'] then
		if where ~= '' then
			where = where .. ' AND '
		end
		where = where .. '(' .. constraints['version'] .. ')'
	end
	return where
end

local resultCell = function(row, showResultId, needLink, noVersion, template)
	local result, resultid, resultimage, resulttext, amount, version = row['result'], row['resultid'], row['resultimage'], row['resulttext'], row['amount'], row['version']
	local str = ''
	local args = {anchor = resultanchor, nolink = not needLink, class='multi-line'}
	if showResultId then
		args['id'] = resultid
	end
	if resultimage then
		args['image'] = resultimage
	end
	if resulttext then
		args[2] = resulttext
	end
	if version ~= '' then
		args['icons'] = 'n'
	end
	str = str .. itemLink(result, args)
	if amount ~= '1' then
		str = str .. ' <span class="note-text">('..amount..')</span>'
	end
	if not noVersion and version ~= '' then
		-- {{version icons}} is a slow template, so cache its result:
		local vstr = cache.get(lang..':recipes:versionicons:'..version) -- cache for current lang
		if not vstr then
			vstr = ' (' ..currentFrame:expandTemplate{ title = 'version icons', args = {version} }..')'
			cache.set(lang..':recipes:versionicons:'..version, vstr, 3600*24) -- cache 24hr.
		end
		str = str .. vstr
	end
	if template then
		local template_str = currentFrame:expandTemplate{ title = template, args = {
				link = needLink, showid = showResultId, noversion = noVersion,
				resultid=resultid, resultimage=resultimage, resulttext=resulttext,
				result=result, amount=amount, versions=version,
		} }
		str = template_str:gsub('@@@@', str)
	end
	return str
end

local ingredientsCell = function(args)
	local str = '<ul>'
	for _, v in ipairs(explode('^', args)) do
		str = str .. '<li>'
		local item, amount = v:match('^(.-)¦(.-)$')
		local s
		for _, itemname in ipairs(split(item)) do
			if s then
				s = s .. l10n('ingredients_sep') .. itemLink(itemname)
			else
				s = itemLink(itemname)
			end
		end
		str = str .. s
		if amount ~= '1' then
			str = str .. ' <span class="note-text">('..amount..')</span>'
		end
		str = str .. '</li>'
	end
	str = str .. '</ul>'
	return str
end

local stationCell = function(station, options)
	options = options or {wrap = 'y'}
	if station == 'By Hand' then
		return l10n('station_by_hand')
	elseif station == 'Furnace' or station == 'Work Bench' or station == 'Sawmill' or station == "Tinkerer's Workshop" or station == 'Dye Vat'
	  or station == 'Loom' or station == 'Keg' or station == 'Hellforge' or station == 'Bookcase' or station == 'Imbuing Station' or station == 'Lava'
	  or station == 'Honey' or station == 'Glass Kiln' or station == 'Flesh Cloning Vat' or station == 'Autohammer' or station == 'Crystal Ball'
	  or station == 'Ice Machine' or station == 'Meat Grinder' or station == 'Living Loom' or station == 'Heavy Work Bench' or station == 'Sky Mill'
	  or station == 'Solidifier' or station == 'Honey Dispenser' or station == 'Bone Welder' or station == 'Blend-O-Matic' or station == 'Steampunk Boiler'
	  or station == 'Ancient Manipulator' or station == 'Lihzahrd Furnace' or station == 'Living Wood' or station == 'Decay Chamber' or station == 'Teapot' or station == 'Campfire' then
		return itemLink(station, options)
	elseif station == 'Iron Anvil' then
		return itemLink('Iron Anvil', options) .. l10n('station_sep_or') .. itemLink('Lead Anvil', options)
	elseif station == 'Iron Anvil and Ecto Mist' then
		return itemLink('Iron Anvil', options) .. l10n('station_sep_or') .. itemLink('Lead Anvil', options) .. l10n('station_sep_and').. itemLink('Ecto Mist', {mode = 'text'})
	elseif station == 'Adamantite Forge' then
		return itemLink('Adamantite Forge', options) .. l10n('station_sep_or') .. itemLink('Titanium Forge', options)
	elseif station == 'Mythril Anvil' then
		return itemLink('Mythril Anvil', options) .. l10n('station_sep_or') .. itemLink('Orichalcum Anvil', options)
	elseif station == 'Demon Altar' then
		return itemLink('Demon Altar', options) .. l10n('station_sep_or') .. itemLink('Crimson Altar', options)
	elseif station == 'Cooking Pot' then
		return itemLink('Cooking Pot', options) .. l10n('station_sep_or') .. itemLink('Cauldron', options)
	elseif station == 'Placed Bottle' then
		return itemLink('Placed Bottle', options) .. l10n('station_sep_or') .. itemLink('Alchemy Table', options)
	elseif station == 'Water' then
		return itemLink('Water', options) .. l10n('station_sep_or') .. itemLink('Sink', options)
	elseif station == 'Table and Chair' then
		return itemLink('Table', options) .. l10n('station_sep_and') .. itemLink('Chair', options)
	elseif station == 'Work Bench and Chair' then
		return itemLink('Work Bench', options) .. l10n('station_sep_and') .. itemLink('Chair', options)
	elseif station == 'Crystal Ball and Lava' then
		return itemLink('Crystal Ball', options) .. l10n('station_sep_and') .. itemLink('Lava', options)
	elseif station == 'Crystal Ball and Honey' then
		return itemLink('Crystal Ball', options) .. l10n('station_sep_and') .. itemLink('Honey', options)
	elseif station == 'Crystal Ball and Water' then
		return itemLink('Crystal Ball', options) .. l10n('station_sep_and').. '<span class="water">' .. itemLink('Water', options) .. l10n('station_sep_or') .. itemLink('Sink', options) .. '</span>'
	elseif station == 'Sky Mill and Water' then
		return itemLink('Sky Mill', options) .. l10n('station_sep_and').. '<span  class="water">' .. itemLink('Water', options) .. l10n('station_sep_or') .. itemLink('Sink', options) .. '</span>'
	elseif station == 'Sky Mill and Snow Biome' then
		return itemLink('Sky Mill', options) .. l10n('station_sep_and').. l10n('snow_biome')
	elseif station == 'Placed Bottle only' then
		return itemLink('Placed Bottle', options)
	elseif station == 'Heavy Work Bench and Ecto Mist' then
		return itemLink('Heavy Work Bench', options) .. l10n('station_sep_and').. itemLink('Ecto Mist', {mode = 'text'})
	elseif station == 'Work Bench and Ecto Mist' then
		return itemLink('Work Bench', options) .. l10n('station_sep_and').. itemLink('Ecto Mist', {mode = 'text'})
	elseif station == "Tinkerer's Workshop and Ecto Mist" then
		return itemLink("Tinkerer's Workshop", options) .. l10n('station_sep_and').. itemLink('Ecto Mist', {mode = 'text'})
	else
		return station
	end
end
-- for extract.
local compactStation = function(station)
	if station == 'By Hand' then
		return ''
	elseif station == 'Furnace' or station == 'Work Bench' or station == 'Sawmill' or station == "Tinkerer's Workshop" or station == 'Dye Vat'
	  or station == 'Loom' or station == 'Keg' or station == 'Hellforge' or station == 'Bookcase' or station == 'Imbuing Station' or station == 'Lava'
	  or station == 'Honey' or station == 'Glass Kiln' or station == 'Flesh Cloning Vat' or station == 'Autohammer' or station == 'Crystal Ball'
	  or station == 'Ice Machine' or station == 'Meat Grinder' or station == 'Living Loom' or station == 'Heavy Work Bench' or station == 'Sky Mill'
	  or station == 'Solidifier' or station == 'Honey Dispenser' or station == 'Bone Welder' or station == 'Blend-O-Matic' or station == 'Steampunk Boiler'
	  or station == 'Ancient Manipulator' or station == 'Lihzahrd Furnace' or station == 'Living Wood' or station == 'Decay Chamber' or station == 'Teapot' or station == 'Campfire' then
		return l10n('compact_before') .. itemLink(station, {mode = 'image'}) .. l10n('compact_after')
	elseif station == 'Iron Anvil' then
		return l10n('compact_before') .. itemLink('Iron Anvil', {mode = 'image'}) .. "&thinsp;/&thinsp;" .. itemLink('Lead Anvil', {mode = 'image'}) .. l10n('compact_after')
	elseif station == 'Iron Anvil and Ecto Mist' then
		return l10n('compact_before') .. itemLink('Iron Anvil', {mode = 'image'}) .. "&thinsp;/&thinsp;" .. itemLink('Lead Anvil', {mode = 'image'}) .. "&thinsp;&amp;&thinsp;".. itemLink('Ecto Mist', {mode = 'text'}) .. l10n('compact_after')
	elseif station == 'Adamantite Forge' then
		return l10n('compact_before') .. itemLink('Adamantite Forge', {mode = 'image'}) .. "&thinsp;/&thinsp;" .. itemLink('Titanium Forge', {mode = 'image'}) .. l10n('compact_after')
	elseif station == 'Mythril Anvil' then
		return l10n('compact_before') .. itemLink('Mythril Anvil', {mode = 'image'}) .. "&thinsp;/&thinsp;" .. itemLink('Orichalcum Anvil', {mode = 'image'}) .. l10n('compact_after')
	elseif station == 'Demon Altar' then
		return l10n('compact_before') .. itemLink('Demon Altar', {mode = 'image'}) .. "&thinsp;/&thinsp;" .. itemLink('Crimson Altar', {mode = 'image'}) .. l10n('compact_after')
	elseif station == 'Cooking Pot' then
		return l10n('compact_before') .. itemLink('Cooking Pot', {mode = 'image'}) .. "&thinsp;/&thinsp;" .. itemLink('Cauldron', {mode = 'image'}) .. l10n('compact_after')
	elseif station == 'Placed Bottle' then
		return l10n('compact_before') .. itemLink('Placed Bottle', {mode = 'image'}) .. "&thinsp;/&thinsp;" .. itemLink('Alchemy Table', {mode = 'image'}) .. l10n('compact_after')
	elseif station == 'Water' then
		return l10n('compact_before') .. itemLink('Water', {mode = 'image'}) .. "&thinsp;/&thinsp;" .. itemLink('Sink', {mode = 'image'}) .. l10n('compact_after')
	elseif station == 'Table and Chair' then
		return l10n('compact_before') .. itemLink('Table', {mode = 'image'}) .. "&thinsp;&amp;&thinsp;" .. itemLink('Chair', {mode = 'image'}) .. l10n('compact_after')
	elseif station == 'Work Bench and Chair' then
		return l10n('compact_before') .. itemLink('Work Bench', {mode = 'image'}) .. "&thinsp;&amp;&thinsp;" .. itemLink('Chair', {mode = 'image'}) .. l10n('compact_after')
	elseif station == 'Crystal Ball and Lava' then
		return l10n('compact_before') .. itemLink('Crystal Ball', {mode = 'image'}) .. "&thinsp;&amp;&thinsp;" .. itemLink('Lava', {mode = 'image'}) .. l10n('compact_after')
	elseif station == 'Crystal Ball and Honey' then
		return l10n('compact_before') .. itemLink('Crystal Ball', {mode = 'image'}) .. "&thinsp;&amp;&thinsp;" .. itemLink('Honey', {mode = 'image'}) .. l10n('compact_after')
	elseif station == 'Crystal Ball and Water' then
		return l10n('compact_before') .. itemLink('Crystal Ball', {mode = 'image'}) .. "&thinsp;&amp;&thinsp;".. itemLink('Water', {mode = 'image'}) .. " / " ..
		itemLink('Crystal Ball', {mode = 'image'}) .. "&thinsp;&amp;&thinsp;" .. itemLink('Sink', {mode = 'image'}) .. l10n('compact_after')
	elseif station == 'Sky Mill and Water' then
		return l10n('compact_before') .. itemLink('Sky Mill', {mode = 'image'}) .. "&thinsp;&amp;&thinsp;".. itemLink('Water', {mode = 'image'}) .. " / " .. 
		itemLink('Sky Mill', {mode = 'image'}) .. "&thinsp;&amp;&thinsp;"..  itemLink('Sink', {mode = 'image'}) .. l10n('compact_after')
	elseif station == 'Sky Mill and Snow Biome' then
		return l10n('compact_before') .. itemLink('Sky Mill', {mode = 'image'}) .. "&thinsp;&amp;&thinsp;".. l10n('compact_snow_biome') .. l10n('compact_after')
	elseif station == 'Placed Bottle only' then
		return l10n('compact_before') .. itemLink('Placed Bottle', {mode = 'image'}) .. l10n('compact_after')
	elseif station == 'Heavy Work Bench and Ecto Mist' then
		return l10n('compact_before') .. itemLink('Heavy Work Bench', {mode = 'image'}) .. "&thinsp;&amp;&thinsp;".. itemLink('Ecto Mist', {mode = 'text'}) .. l10n('compact_after')
	elseif station == 'Work Bench and Ecto Mist' then
		return l10n('compact_before') .. itemLink('Work Bench', {mode = 'image'}) .. "&thinsp;&amp;&thinsp;".. itemLink('Ecto Mist', {mode = 'text'}) .. l10n('compact_after')
	elseif station == "Tinkerer's Workshop and Ecto Mist" then
		return l10n('compact_before') .. itemLink("Tinkerer's Workshop", {mode = 'image'}) .. "&thinsp;&amp;&thinsp;".. itemLink('Ecto Mist', {mode = 'text'}) .. l10n('compact_after')
	else
		return l10n('compact_before') .. station .. l10n('compact_after')
	end
end

local getFlags = function(args)
	local needCate = 1
	local needLink = true
	local _cate = trim(args['cate'] or '')
	if _cate == 'force' or _cate == 'all' then
		needCate = 2
	elseif _cate == 'n' or _cate == 'no' then
		needCate = nil
	end
	local _link = trim(args['link'] or '')
	if _link == 'y' or _link == 'yes' or _link == 'force' then
		needLink = true
	elseif _link == 'n' or _link == 'no' then
		needLink = false
	end
	return needCate, needLink
end

local addCate, cateStr -- for table body. init in p.query

local tableStart = function(title, withStation)
	local header_
	-- table wrap to make both border-radius and fandom's wild table workaround work.
	local str = '<table class="crafts"><tr><td><table class="'.. (getArg('class') or '')
	if (getArg('sortable') or 'y'):sub(1,1) ~= 'n' then
		str = str .. ' sortable '
	end
	local _id = (getArg('id') or '')
	if _id ~= '' then
		str = str .. '" id="'.. _id
	end
	local _css = (getArg('css') or getArg('style') or '')
	if _css ~= '' then
		str = str .. '" style="'.. _css
	end
	str = str .. '" cellpadding="0" cellspacing="0">'
	if title ~= '' then
		str = str .. '<caption>' .. title .. '</caption>'
	end
	local _i, _field
	str = str .. '<tr>'
	_i = 1
	_field = 'col-A-1'
	while getArg(_field) do
		if not extCols_A then
			extCols_A = {}
		end
		table.insert(extCols_A, _field)
		str = str .. '<th>'.. getArg(_field) ..'</th>'
		_i = _i + 1
		_field = 'col-A-' .. _i
	end
	str = str .. '<th class="result">' .. (getArg('header-result') or l10n('header_result')) .. '</th>'
	_i = 1
	_field = 'col-B-1'
	while getArg(_field) do
		if not extCols_B then
			extCols_B = {}
		end
		table.insert(extCols_B, _field)
		str = str .. '<th>'.. getArg(_field) ..'</th>'
		_i = _i + 1
		_field = 'col-B-' .. _i
	end
	str = str .. '<th class="ingredients">' .. (getArg('header-ingredients') or l10n('header_ingredients')) .. '</th>'
	_i = 1
	_field = 'col-C-1'
	while getArg(_field) do
		if not extCols_C then
			extCols_C = {}
		end
		table.insert(extCols_C, _field)
		str = str .. '<th>'.. getArg(_field) ..'</th>'
		_i = _i + 1
		_field = 'col-C-' .. _i
	end
	if withStation then
		_i = 1
		_field = 'station-col-before-1'
		while getArg(_field) do
			if not extCols_stationBefore then
				extCols_stationBefore = {}
			end
			table.insert(extCols_stationBefore, _field)
			str = str .. '<th class="station">'.. getArg(_field) ..'</th>'
			_i = _i + 1
			_field = 'station-col-before-' .. _i
		end
		str = str .. '<th class="station">' .. (getArg('header-station') or l10n('header_station')) .. '</th>'
		_i = 1
		_field = 'station-col-after-1'
		while getArg(_field) do
			if not extCols_stationAfter then
				extCols_stationAfter = {}
			end
			table.insert(extCols_stationAfter, _field)
			str = str .. '<th class="station">'.. getArg(_field) ..'</th>'
			_i = _i + 1
			_field = 'station-col-after-' .. _i
		end
	end
	_i = 1
	_field = 'col-D-1'
	while getArg(_field) do
		if not extCols_D then
			extCols_D = {}
		end
		table.insert(extCols_D, _field)
		str = str .. '<th>'.. getArg(_field) ..'</th>'
		_i = _i + 1
		_field = 'col-D-' .. _i
	end
	str = str .. '</tr>'
	return str
end

local tableEnd = function(rows_count, expectedrows)
	local str = '</table><div style="display: none">total: '..rows_count..' row(s)</div></td></tr></table>'
	if expectedrows and rows_count ~= expectedrows then
		str = str .. '[[Category:'.. l10n('cate_unexpected_rows_count') .. ']]'
	end
	if not expectedrows and rows_count == 0 then
		str = str .. '[[Category:'.. l10n('cate_no_row') .. ']]'
	end
	return str
end

local tableRow = function(str, row, current_station, station_count, rows_count, showResultId, withStation, needCate, needLink, needGroup, current_result, result_count, current_result_ext, result_ext_count, template, stationGroup)
	local str_w = '' -- before result col
	local str_x = '' -- between result and ingredients cols
	local str_y = '' -- between ingredients and station cols
	local str_z = '' -- after station
	local str_resultCell = ''

	local result_index = getArg('result-index-#'..rows_count) or getArg('result-index-'..row['result']..'-'..row['version']) or getArg('result-index-'..row['result'])

	str = str .. '<tr data-rowid="'..tostring(rows_count)..'">'

	if needGroup then
		local result = row['result']..'|'..row['resultid']..'|'..row['resultimage']..'|'..row['resulttext']..'|'..row['amount']..'|'..row['version']
		-- grouping result col
		if current_result == result then -- is same group ??
			result_count = result_count + 1
		else
			--new group:
			-- rowspan value for prev group, if needed.
			if result_count then
				str = str:gsub("yyyrowspanyyy", tostring(result_count))
			end
			-- begin this group
			current_result = result
			result_count = 1
			str_resultCell = '<td class="result" rowspan="yyyrowspanyyy">'.. resultCell(row, showResultId, needLink, false, template).. '</td>'
		end
		-- grouping ext cols
		if result_index and (current_result_ext == result_index) then -- is same group ??
			result_ext_count = result_ext_count + 1
		else
			--new group:
			-- rowspan value for prev group, if needed.
			if result_ext_count then
				str = str:gsub("zzzrowspanzzz", tostring(result_ext_count))
			end
			-- begin this group
			current_result_ext = result_index
			result_ext_count = 1
			if extCols_A then
				for _, v in ipairs(extCols_A) do
					if result_index then
						str_w = str_w .. '<td class="'..v..'" rowspan="zzzrowspanzzz">' .. (getArg(result_index .. '-row-' .. v) or '') .. '</td>'
					else
						str_w = str_w .. '<td class="'..v..'" rowspan="zzzrowspanzzz"></td>'
					end
				end
			end
			if extCols_B then
				for _, v in ipairs(extCols_B) do
					if result_index then
						str_x = str_x .. '<td class="'..v..'" rowspan="zzzrowspanzzz">' .. (getArg(result_index .. '-row-' .. v) or '') .. '</td>'
					else
						str_x = str_x .. '<td class="'..v..'" rowspan="zzzrowspanzzz"></td>'
					end
				end
			end
			if extCols_C then
				for _, v in ipairs(extCols_C) do
					if result_index then
						str_y = str_y .. '<td class="'..v..'" rowspan="zzzrowspanzzz">' .. (getArg(result_index .. '-row-' .. v) or '') .. '</td>'
					else
						str_y = str_y .. '<td class="'..v..'" rowspan="zzzrowspanzzz"></td>'
					end
				end
			end
			if extCols_D then
				for _, v in ipairs(extCols_D) do
					if result_index then
						str_z = str_z .. '<td class="'..v..'" rowspan="zzzrowspanzzz">' .. (getArg(result_index .. '-row-' .. v) or '') .. '</td>'
					else
						str_z = str_z .. '<td class="'..v..'" rowspan="zzzrowspanzzz"></td>'
					end
				end
			end
		end
	else
		if extCols_A then
			for _, v in ipairs(extCols_A) do
				if result_index then
					str_w = str_w .. '<td class="'..v..'">' .. (getArg(result_index .. '-row-' .. v) or '') .. '</td>'
				else
					str_w = str_w .. '<td class="'..v..'"></td>'
				end
			end
		end
		if extCols_B then
			for _, v in ipairs(extCols_B) do
				if result_index then
					str_x = str_x .. '<td class="'..v..'">' .. (getArg(result_index .. '-row-' .. v) or '') .. '</td>'
				else
					str_x = str_x .. '<td class="'..v..'"></td>'
				end
			end
		end
		if extCols_C then
			for _, v in ipairs(extCols_C) do
				if result_index then
					str_y = str_y .. '<td class="'..v..'">' .. (getArg(result_index .. '-row-' .. v) or '') .. '</td>'
				else
					str_y = str_y .. '<td class="'..v..'"></td>'
				end
			end
		end
		if extCols_D then
			for _, v in ipairs(extCols_D) do
				if result_index then
					str_z = str_z .. '<td class="'..v..'">' .. (getArg(result_index .. '-row-' .. v) or '') .. '</td>'
				else
					str_z = str_z .. '<td class="'..v..'"></td>'
				end
			end
		end
		str_resultCell = '<td class="result">'.. resultCell(row, showResultId, needLink, false, template).. '</td>'
	end

	str = str .. str_w .. str_resultCell .. str_x .. '<td class="ingredients">' .. ingredientsCell(row['args']).. '</td>' .. str_y

	if withStation then
		local station = row['station']
		if stationGroup then
			if current_station == station then -- is same group ??
				station_count = station_count + 1
			else
				--new group:
				-- rowspan value for prev group, if needed.
				if station_count then
					str = str:gsub("xxxrowspanxxx", tostring(station_count))
				end
				-- begin this group
				current_station = station
				station_count = 1
				local station_index = getArg('station-index-'..station)
				-- station before:
				if extCols_stationBefore then
					for _, v in ipairs(extCols_stationBefore) do
						if station_index then
							str = str .. '<td class="station '..v..'" rowspan="xxxrowspanxxx">' .. (getArg(station_index .. '-row-' .. v) or '') .. '</td>'
						else
							str = str .. '<td class="station '..v..'" rowspan="xxxrowspanxxx"></td>'
						end
					end
				end
				str = str .. '<td class="station" rowspan="xxxrowspanxxx">'.. stationCell(station) ..'</td>'
				-- station after:
				if extCols_stationAfter then
					for _, v in ipairs(extCols_stationAfter) do
						if station_index then
							str = str .. '<td class="station '..v..'" rowspan="xxxrowspanxxx">' .. (getArg(station_index .. '-row-' .. v) or '') .. '</td>'
						else
							str = str .. '<td class="station '..v..'" rowspan="xxxrowspanxxx"></td>'
						end
					end
				end
			end
		else
			if current_station == station then -- is same group ??
				station_count = station_count + 1
			else
				current_station = station
				station_count = 1
			end
			local station_index = getArg('station-index-'..station)
			-- station before:
			if extCols_stationBefore then
				for _, v in ipairs(extCols_stationBefore) do
					if station_index then
						str = str .. '<td class="station '..v..'">' .. (getArg(station_index .. '-row-' .. v) or '') .. '</td>'
					else
						str = str .. '<td class="station '..v..'"></td>'
					end
				end
			end
			str = str .. '<td class="station">'.. stationCell(station) ..'</td>'
			-- station after:
			if extCols_stationAfter then
				for _, v in ipairs(extCols_stationAfter) do
					if station_index then
						str = str .. '<td class="station '..v..'">' .. (getArg(station_index .. '-row-' .. v) or '') .. '</td>'
					else
						str = str .. '<td class="station '..v..'"></td>'
					end
				end
			end
		end
	end

	str = str .. str_z ..'</tr>'
	return str, current_station, station_count, current_result, result_count, current_result_ext, result_ext_count
end

local extRows = function(withStation, isTop)
	local prefix
	if isTop then
		prefix = 'topextrow-'
	else
		prefix = 'extrow-'
	end
	local returnstr = ''
	local valid = true
	local p
	local str
	local _i = 1
	local temp
	while valid do
		local i = tostring(_i) .. '-'
		p = prefix .. i
		valid = false
		str = '<tr data-'..prefix..'id="'..tostring(_i)..'">'
		if extCols_A then
			for _, v in ipairs(extCols_A) do
				temp = getArg(p..v)
				if temp then
					valid = true
					str = str .. '<td class="'..v..'">' .. temp .. '</td>'
				else
					str = str .. '<td class="'..v..'"></td>'
				end
			end
		end
		temp = getArg(p..'col-result')
		if temp then
			valid = true
			str = str .. '<td class="result">' .. temp .. '</td>'
		else
			str = str .. '<td class="result"></td>'
		end
		if extCols_B then
			for _, v in ipairs(extCols_B) do
				temp = getArg(p..v)
				if temp then
					valid = true
					str = str .. '<td class="'..v..'">' .. temp .. '</td>'
				else
					str = str .. '<td class="'..v..'"></td>'
				end
			end
		end
		temp = getArg(p..'col-ingredients')
		if temp then
			valid = true
			str = str .. '<td class="ingredients">' .. temp .. '</td>'
		else
			str = str .. '<td class="ingredients"></td>'
		end
		if extCols_C then
			for _, v in ipairs(extCols_C) do
				temp = getArg(p..v)
				if temp then
					valid = true
					str = str .. '<td class="'..v..'">' .. temp .. '</td>'
				else
					str = str .. '<td class="'..v..'"></td>'
				end
			end
		end
		if withStation then
			-- station before:
			if extCols_stationBefore then
				for _, v in ipairs(extCols_stationBefore) do
					temp = getArg(p..v)
					if temp then
						valid = true
						str = str .. '<td class="station '..v..'">' .. temp .. '</td>'
					else
						str = str .. '<td class="station '..v..'"></td>'
					end
				end
			end
			temp = getArg(p..'col-station')
			if temp then
				valid = true
				str = str .. '<td class="station">' .. temp .. '</td>'
			else
				str = str .. '<td class="station"></td>'
			end
			-- station after:
			if extCols_stationAfter then
				for _, v in ipairs(extCols_stationAfter) do
					temp = getArg(p..v)
					if temp then
						valid = true
						str = str .. '<td class="station '..v..'">' .. temp .. '</td>'
					else
						str = str .. '<td class="station '..v..'"></td>'
					end
				end
			end
		end
		if extCols_D then
			for _, v in ipairs(extCols_D) do
				temp = getArg(p..v)
				if temp then
					valid = true
					str = str .. '<td class="'..v..'">' .. temp .. '</td>'
				else
					str = str .. '<td class="'..v..'"></td>'
				end
			end
		end
		str = str .. '</tr>'

		if valid then
			_i = _i + 1
			returnstr = returnstr .. str
		end
	end
	return returnstr
end


local tableBody = function(result, showResultId, withStation, needGroup, needCate, needLink, rootpagename, title, expectedrows, template, stationGroup)
		local str = tableStart(title, withStation)
		-- top ext rows:
		str = str .. extRows(withStation, true)
		-- main rows:
		local current_station
		local station_count
		local rows_count = 0
		local current_result
		local result_count
		local current_result_ext
		local result_ext_count
		for _, row in ipairs(result) do
			rows_count = rows_count + 1
			-- table row:
			str, current_station, station_count, current_result, result_count, current_result_ext, result_ext_count = tableRow(str, row, current_station, station_count, rows_count, showResultId, withStation, needCate, needLink, needGroup, current_result, result_count, current_result_ext, result_ext_count, template, stationGroup)
			-- cate:
			if needCate then
				if needCate == 2 or rootpagename == currentFrame:expandTemplate{ title = 'tr', args = {row['result'], lang=lang} } then
					addCate(row['station'])
				end
			end
		end
		-- rowspan value for last station group and result group
		if withStation and station_count and stationGroup then
			str = str:gsub("xxxrowspanxxx", tostring(station_count))
		end
		if needGroup then
			str = str:gsub("yyyrowspanyyy", tostring(result_count))
			str = str:gsub("zzzrowspanzzz", tostring(result_ext_count))
		end
		-- ext rows:
		str = str .. extRows(withStation)
		-- table end
		str = str .. tableEnd(rows_count, expectedrows)

		-- cate
		if needCate then
			str = str .. cateStr()
		end

		return str
end
----------------------------------------------------------------------------------

local p = {}

-- for {{recipes/register}}
p.register = function(frame)
	local args = frame:getParent().args

	-- {{{ingredients}}}
	local ingredients = {} -- list of {index, itemname, amount}
	for k, v in pairs(args) do
		if(type(k) == 'number') then
			if k % 2 == 1 then  -- 2n-1, nth item
				local index, item, amount = (k+1)/2, trim(v), trim(args[k+1])
				ingredients[index] = {item, amount}
			end
		end
	end

	local serialized = '' -- serialized ingredients list
	for _, v in ipairs(ingredients) do
		serialized = serialized .. '^' .. v[1] .. '¦' .. v[2]
	end
	serialized = mw.ustring.sub(serialized, 2)

	table.sort(ingredients, function(a , b) return a[1] < b[1] end) -- sort by ingredient item name
	local ingredients_string = ''
	local ingredients_string_full = ''
	for _, v in ipairs(ingredients) do
		local name, amount = unpack(v)
		local ingstr = normalize(name)
		ingredients_string = ingredients_string .. '^' .. ingstr
		ingredients_string_full = ingredients_string_full .. '^' .. ingstr .. amount
	end

	--{{{version}}}, normalize
	version = normalizeVersion(args['version'] or '')

	--store
	frame:callParserFunction('#cargo_store:_table=Recipes',{
		result = trim(args['result'] or ''),
		resultid = trim(args['resultid'] or ''),
		resultimage = trim(args['image'] or ''),
		resulttext = trim(args['text'] or ''),
		amount = trim(args['amount'] or ''),
		version = version,
		station = normalizeStation(trim(args['station'] or '')),
		ingredients = mw.ustring.sub(ingredients_string, 2),
		ings = mw.ustring.sub(ingredients_string_full, 2),
		args = serialized,
	})
end -- p.register



-- for {{recipes}}
p.query = function(frame)
	currentFrame = frame -- global frame cache
	local args = frame:getParent().args
	inputArgs = args

	lang = frame.args['lang'] or 'en'
	l10n_table = l10n_info[lang] or l10n_info['en']
	
	resultanchor = trim(args['resultanchor'] or '')

	local result_order = trim(args['orderbyid'] or '')
	if result_order == 'y' or result_order == 'yes' then
		result_order = 'resultid'
	else
		result_order = 'result'
	end

	addCate, cateStr = (function()
		local cate = l10n('station_cate')
		local cateCache = {}
		local addCate = function(station)
			cateCache[station] = true
		end
		local cateStr = function()
			local str = ''
			for station, _ in pairs(cateCache) do
				str = str .. '[[Category:'..(cate[station] or frame:expandTemplate{ title = 'tr', args = {station, lang=lang, link='y'}})..']]'
			end
			if str ~= '' then
				str = '[[Category:'.. l10n('cate_craftable').. ']]' .. str
			end
			return str
		end
		return addCate, cateStr
	end)()

	local where = trim(args['where'] or '')
	if where == '' then
		where = criStr(args)
	end

	-- no constraint no result.
	if where == '' then
		return frame:expandTemplate{ title='error', args={ "Recipes: No constraint", from = 'Recipes', inline = 'y'}}
	end

	-- format:
	local needCate, needLink = getFlags(args)
	local needGroup = true
	if (getArg('grouping') or 'y'):sub(1,1) == 'n' then
		needGroup = false
	end
	local showResultId = false
	if trim(args['showresultid'] or '') ~= '' then
		showResultId = true
	end
	local _title = trim(args['title'] or '')
	local _expectedrows = trim(args['expectedrows'] or '')
	if _expectedrows ~= '' then
		_expectedrows = tonumber(_expectedrows)
	else
		_expectedrows = nil
	end
	local rootpagename = mw.title.getCurrentTitle().rootText

	if trim(args['nostation'] or '') ~= '' then
		-- no station
		-- query, still need contain station field for cate.
		local result = mw.ext.cargo.query('Recipes', 'result, resultid, resultimage, resulttext, amount, version, station, args', {
			where = where,
			groupBy = "resultid, result, amount, version, ings, station",
			orderBy = result_order .. ", amount DESC, version", -- Don't order by station
			limit = 2000,
		})
		return tableBody(result, showResultId, false, needGroup, needCate, needLink, rootpagename, _title, _expectedrows, getArg('resulttemplate'), false)
	else
		-- with station
		local stationGroup = true
		if (getArg('stationgrouping') or 'y'):sub(1,1) == 'n' then
			stationGroup = false
		end
		-- query
		local result = mw.ext.cargo.query('Recipes', 'result, resultid, resultimage, resulttext, amount, version, station, args', {
			where = where,
			groupBy = "resultid, result, amount, ings, version, station",
			orderBy = "station, ".. result_order .. ", amount DESC, version, ings", -- order by station first for station grouping.
			limit = 2000,
		})
		return tableBody(result, showResultId, true, needGroup, needCate, needLink, rootpagename, _title, _expectedrows, getArg('resulttemplate'), stationGroup)
	end
end -- p.query

-- for {{recipes/extract}}
p.extract = function(frame)
	currentFrame = frame -- global frame cache

	local args = frame:getParent().args
	inputArgs = args

	local result_order = trim(args['orderbyid'] or '')
	if result_order == 'y' or result_order == 'yes' then
		result_order = 'resultid'
	else
		result_order = 'result'
	end

	lang = frame.args['lang'] or 'en'
	l10n_table = l10n_info[lang] or l10n_info['en']

	local where = trim(args['where'] or '')
	if where == '' then
		where = criStr(args)
	end

	-- no constraint no result.
	if where == '' then
		return frame:expandTemplate{ title='error', args={ "Recipes/extract: Invalid mode", from = 'Recipes', inline = 'y'}}
	end

	-- query:
	local result = mw.ext.cargo.query('Recipes', 'result, resultid, resultimage, resulttext, amount, version, station, args', {
		where = where,
		groupBy = "resultid, result, amount, version, ings",
		orderBy = result_order .. ", amount DESC, version", -- Don't order by station
		limit = 20, -- enough.
	})

	-- output
	local mode = getArg('mode')
	local sep = getArg('sep') or getArg('seperator')
	if not mode or mode =='compact' or mode == '' then
		--default mode = compact
		local sep = sep or l10n('default_sep_compact')
		local withResult = getArg('withresult')
		local withStation = not getArg('nostation')
		local withVersion = not getArg('noversion')
		local str = nil
		local withOne = getArg('full')
		for _, row in ipairs(result) do
			if str then
				str = str .. sep
			else
				str = ''
			end
			str = str .. '<span class="recipe compact">'
			if withVersion then
				if row['version'] ~= '' then
					str = str ..currentFrame:expandTemplate{ title = 'version icons', args = {row['version']} }..l10n(':')
				end
			end
			local ingFlag = nil
			for _, v in ipairs(explode('^', row['args'])) do
				if ingFlag then
					str = str .. ' + '
				else
					ingFlag = true
				end
				local item, amount = v:match('^(.-)¦(.-)$')
				if amount ~= '1' or withOne then
					str = str .. amount .. ' '
				end
				local s
				for _, itemname in ipairs(split(item)) do
					if s then
						s = s .. "&thinsp;/&thinsp;" .. itemLink(itemname, {mode='image'})
					else
						s = itemLink(itemname, {mode='image'})
					end
				end
				str = str .. s
			end
			if withResult then
				str = str .. ' = '
				if row['amount'] ~= '1' or withOne then
					str = str .. row['amount'] .. ' '
				end
				local args = {mode='image'}
				if row['resultimage'] then
					args['image'] = row['resultimage']
				end
				str = str .. itemLink(row['result'], args)
			end
			if withStation then
				str = str .. compactStation(row['station'])
			end
			str = str..'</span>'
		end
		return str
	elseif mode == 'ingredients' then
		local sep = sep or l10n('default_sep_ingredients') 
		local str = ''
		for _, row in ipairs(result) do
			if str ~= '' then
				str = str .. sep
			end
			str = str .. ingredientsCell(row['args'])
		end
		return '<div class="crafting-ingredients">'..str..'</div>'
	elseif mode == 'station' then
		-- only return first row.
		for _, row in ipairs(result) do
			return stationCell(row['station'], {})
		end
	elseif mode == 'result' then
		-- only return first row.
		local needCate, needLink = getFlags(args)
		for _, row in ipairs(result) do
			return resultCell(row, getArg('showresultid'), needLink, true, getArg('resulttemplate'))
		end
	elseif mode == 'ingredients-buy' then
		-- only process first row.
		for _, row in ipairs(result) do
			local value = 0
			for _, v in ipairs(explode('^', row['args'])) do
				local item, amount = v:match('^(.-)¦(.-)$')
				value = value + require('Module:Iteminfo').getItemStat( tonumber(currentFrame:expandTemplate{ title = 'itemIdFromName', args = {item, lang='en'} }) or 0, 'value' ) * amount
			end
			return value
		end
	elseif mode == 'ingredients-sell' then
		-- only process first row.
		for _, row in ipairs(result) do
			local value = 0
			for _, v in ipairs(explode('^', row['args'])) do
				local item, amount = v:match('^(.-)¦(.-)$')
				value = value + math.floor(require('Module:Iteminfo').getItemStat( tonumber(currentFrame:expandTemplate{ title = 'itemIdFromName', args = {item, lang='en'} }) or 0, 'value' )/5) * amount
			end
			return value
		end
	else
		return frame:expandTemplate{ title='error', args={ "Recipes/extract: Invalid mode", from = 'Recipes', inline = 'y'}}
	end
end -- p.extract

-- count
p.count = function(frame)
	local args = frame:getParent().args
	local where = trim(args['where'] or '')
	if where == '' then
		where = criStr(args)
	end
	-- no constraint no result.
	if where == '' then
		return 
	end
	-- query: since we must use group by to eliminate duplicates, so we can not use COUNT() to get row count directly.
	local result = mw.ext.cargo.query('Recipes', 'result, resultid, resultimage, resulttext, amount, version, station, args', {
		where = where,
		groupBy = "resultid, result, amount, ings, version",
		limit = 2000,
	})
	-- count
	local count = 0
	for _, row in ipairs(result) do
		count = count + 1
	end
	return count
end -- p.count

-- return "yes" or "" 
p.exist = function(frame)
	local args = frame:getParent().args
	local where = trim(args['where'] or '')
	if where == '' then
		where = criStr(args)
	end
	-- no constraint no result.
	if where == '' then
		return 
	end
	-- query:
	local result = mw.ext.cargo.query('Recipes', 'result', {
		where = where,
		limit = 1, -- enough.
	})
	-- output
	for _, row in ipairs(result) do
		return 'yes'
	end
end -- p.exist

return p
