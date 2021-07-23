
-- TODO: should be functional for 1.2.
-- However, mines are now technically not dangerous; so warning icon when moving to mines will not show up.
-- Ice will also stay destroyed after undoing move to ice with a mine on it.
-- Mines will remain if terrain changes to water or chasm(unconfirmed)

local mod = mod_loader.mods[modApi.currentMod]
local resourcePath = mod.resourcePath
local scriptPath = mod.scriptPath

local modApiExt = require(scriptPath .."modApiExt/modApiExt")
local armorDetection = require(scriptPath .."libs/armorDetection")
local shop = require(scriptPath .."libs/shop")

modApi:appendAsset("img/weapons/lmn_minelayer_mine.png", resourcePath .."img/weapons/mine.png")
modApi:appendAsset("img/combat/lmn_minelayer_mine_small.png", resourcePath .."img/combat/mine_small.png")
modApi:appendAsset("img/combat/lmn_minelayer_mark_mine_small.png", resourcePath .."img/combat/mark_mine_small.png")
modApi:appendAsset("img/combat/icons/lmn_minelayer_minesweeper.png", resourcePath .."img/combat/icons/icon_minesweeper_glow.png")
modApi:appendAsset("img/combat/icons/lmn_minelayer_icon_strikeout.png", resourcePath .."img/combat/icons/icon_strikeout.png")

Location["combat/lmn_minelayer_mine_small.png"] = Point(-8,3)
Location["combat/lmn_minelayer_mark_mine_small.png"] = Point(-8,3)
Location["combat/icons/lmn_minelayer_minesweeper.png"] = Location["combat/icons/icon_mine_glow.png"]
Location["combat/icons/lmn_minelayer_icon_strikeout.png"] = Point(-13,10)

lmn_Minelayer_Mine = Skill:new{
	Name = "Proximity Mines",
	Class = "Ranged",
	Icon = "weapons/lmn_minelayer_mine.png",
	Description = "Passive Effect\n\nLeave a mine after moving.",
	Damage = 3,
	PowerCost = 0,
	Upgrades = 1,
	MineImmunity = false,
	UpgradeCost = {1},
	UpgradeList = {"Minesweeper"},
	GetTargetArea = function () return PointList() end,
	CustomTipImage = "lmn_Minelayer_Mine_Tip",
	TipImage = {
		CustomPawn = "lmn_MinelayerMech",
		Unit = Point(2,3),
		Target = Point(2,1),
	}
}

lmn_Minelayer_Mine_A = lmn_Minelayer_Mine:new{
	UpgradeDescription = "All allies gain immunity to mines.",
	MineImmunity = true,
	CustomTipImage = "lmn_Minelayer_Mine_Tip_A",
}

local function IsMinelayer(pawn)
	return
		armorDetection.HasPoweredWeapon(pawn, "lmn_Minelayer_Mine") or
		armorDetection.HasPoweredWeapon(pawn, "lmn_Minelayer_Mine_A")
end

local function HasMinesweeper(pawn)
	if pawn:IsEnemy() or not pawn:IsMech() then
		return false
	end
	
	for _, id in ipairs(extract_table(Board:GetPawns(TEAM_MECH))) do
		if armorDetection.HasPoweredWeapon(Board:GetPawn(id), "lmn_Minelayer_Mine_A") then
			return true
		end
	end
	
	return false
end

-----------------------
-- move skill override
-----------------------
local oldMoveGetSkillEffect = Move.GetSkillEffect
function Move:GetSkillEffect(p1, p2, ...)
	origMove = extract_table(oldMoveGetSkillEffect(self, p1, p2, ...).effect)
	local ret = SkillEffect()
	
	if IsMinelayer(Pawn) then
		local damage = SpaceDamage(p1)
		damage.sItem = "lmn_Minelayer_Item_Mine"
		damage.sImageMark = "combat/lmn_minelayer_mark_mine_small.png"
		damage.sSound = "/impact/generic/grapple"
		ret:AddDamage(damage)
	end
	
	local item_at_destination = Board:GetItemName(p2)
	if HasMinesweeper(Pawn) and item_at_destination then
		lmn_Minelayer_Item_Mine_Dummy = shallow_copy(_G[item_at_destination])
		lmn_Minelayer_Item_Mine_Dummy.Damage = SpaceDamage()
		
		local replace_mine = SpaceDamage(p2)
		replace_mine.sItem = "lmn_Minelayer_Item_Mine_Dummy"
		replace_mine.sImageMark = "combat/icons/lmn_minelayer_icon_strikeout.png"
		
		ret:AddDamage(replace_mine)
	end
	
	-- reinsert all effect from original SkillEffect
	for _, v in ipairs(origMove) do
		ret.effect:push_back(v)
	end
    
    return ret
end

------------
-- TipImage
------------
lmn_Minelayer_Mine_Tip = lmn_Minelayer_Mine:new{}
lmn_Minelayer_Mine_Tip_A = lmn_Minelayer_Mine_A:new{}

function lmn_Minelayer_Mine_Tip:GetTargetArea(point)
	return Board:GetReachable(point, Pawn:GetMoveSpeed(), Pawn:GetPathProf())
end

function lmn_Minelayer_Mine_Tip:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	
	local damage = SpaceDamage(p1)
	damage.sItem = "lmn_Minelayer_Item_Mine_Tip"
	damage.sImageMark = "combat/lmn_minelayer_mark_mine_small.png"
	ret:AddDamage(damage)
	
	if self.MineImmunity then
		damage = SpaceDamage(p2)
		damage.sItem = "lmn_Minelayer_Item_Mine_Tip_Explode"
		damage.sImageMark = "combat/lmn_minelayer_mine_small.png"
		Board:DamageSpace(damage)
		
		damage = SpaceDamage(p2)
		damage.sImageMark = "combat/icons/lmn_minelayer_minesweeper.png"
		ret:AddDamage(damage)
	end
	ret:AddMove(Board:GetPath(p1, p2, Pawn:GetPathProf()), FULL_DELAY)
	
	return ret
end

lmn_Minelayer_Mine_Tip_A.GetTargetArea = lmn_Minelayer_Mine_Tip.GetTargetArea
lmn_Minelayer_Mine_Tip_A.GetSkillEffect = lmn_Minelayer_Mine_Tip.GetSkillEffect

---------
-- items
---------

lmn_Minelayer_Item_Mine = { Image = "combat/lmn_minelayer_mine_small.png", Damage = SpaceDamage(0), Tooltip = "old_earth_mine", Icon = "combat/icons/icon_mine_glow.png"}
lmn_Minelayer_Item_Mine_Dummy = {} -- modified dynamically
lmn_Minelayer_Item_Mine_Tip = shallow_copy(lmn_Minelayer_Item_Mine)
lmn_Minelayer_Item_Mine_Tip_Explode = shallow_copy(lmn_Minelayer_Item_Mine)

local damage = SpaceDamage(0)
damage.sAnimation = "ExploAir1"

lmn_Minelayer_Item_Mine_Tip_Explode.Damage = damage

shop:addWeapon{ id = "lmn_Minelayer_Mine", desc = "Adds Proximity Mines to the store." }

track_items:addItemRemovedHook(function(mission, loc, removed_item)
	if removed_item == "lmn_Minelayer_Item_Mine"  then
		
		local pawn = Board:GetPawn(loc)
		local undo_pawn = track_undo_move:GetPawn()
		
		if pawn and undo_pawn and pawn:GetId() == undo_pawn:GetId() then
			-- do nothing
		else
			local mine_damage = SpaceDamage(loc, 3)
			mine_damage.sSound = "/impact/generic/explosion"
			mine_damage.sAnimation = "ExploAir1"
			
			Board:DamageSpace(mine_damage)
		end
	end
end)

local function init() end
local function load() end

return { init = init, load = load }
