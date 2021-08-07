
---------------------------------------------------------------------
-- Tutorial Tips v1.2 - code library
--
-- by Lemonymous
---------------------------------------------------------------------
-- small helper lib to manage tutorial tips that will only display once per profile.
-- can be reset, and would likely be done via a mod option.
--
-- Note: Each mod using this library must each have their unique instance of it.

local mod = mod_loader.mods[modApi.currentMod]
local tips = {}
local cachedTips

sdlext.config(
	modApi:getCurrentModcontentPath(),
	function(obj)
		obj.tutorialTips = obj.tutorialTips or {}
		obj.tutorialTips[mod.id] = obj.tutorialTips[mod.id] or {}
		cachedTips = obj.tutorialTips
	end
)

-- writes tutorial tips data.
local function writeData(id, obj)
	sdlext.config(
		modApi:getCurrentModcontentPath(),
		function(readObj)
			readObj.tutorialTips[mod.id][id] = obj
			cachedTips = readObj.tutorialTips
		end
	)
end

-- reads tutorial tips data.
local function readData(id)
	local result = nil

	if cachedTips then
		result = cachedTips[mod.id][id]
	else
		sdlext.config(
			modApi:getCurrentModcontentPath(),
			function(readObj)
				cachedTips = readObj.tutorialTips
				result = cachedTips[mod.id][id]
			end
		)
	end

	return result
end

function tips:resetAll()
	sdlext.config(
		modApi:getCurrentModcontentPath(),
		function(obj)
			obj.tutorialTips = obj.tutorialTips or {}
			obj.tutorialTips[mod.id] = {}
			cachedTips = obj.tutorialTips
		end
	)
end

function tips:reset(id)
	Assert.Equals('string', type(id), "Argument #1")
	writeData(id, nil)
end

function tips:add(tip)
	Assert.Equals('table', type(tip), "Argument #1")
	Assert.Equals('string', type(tip.id))
	Assert.Equals('string', type(tip.title))
	Assert.Equals('string', type(tip.text))

	Global_Texts[mod.id .. tip.id .."_Title"] = tip.title
	Global_Texts[mod.id .. tip.id .."_Text"] = tip.text
end

function tips:trigger(id, loc)
	Assert.Equals('string', type(id), "Argument #1")
	Assert.TypePoint(loc, "Argument #2")

	if not readData(id) then
		Game:AddTip(mod.id .. id, loc)
		writeData(id, true)
	end
end

-- backwards compatibility
tips.ResetAll = tips.resetAll
tips.Reset = tips.reset
tips.Add = tips.add
tips.Trigger = tips.trigger

return tips
