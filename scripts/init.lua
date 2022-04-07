
-- initialize easyEdit
local function scriptPath()
	return debug.getinfo(2, "S").source:sub(2):match("(.*[/\\])")
end
require(scriptPath().."easyEdit/easyEdit")


-- initialize modpack
local mod =  {
	id = "lmn_mods",
	name = "Lemonymous' Mods",
	version = "0.6.8",
	modApiVersion = "2.6.4",
	icon = "scripts/icon.png",
	description = "A Collection of mods made by Lemonymous",
	submodFolders = {"mods/"}
}

function mod:metadata()
end

function mod:init(options)
	require(self.scriptPath.."LApi/LApi")
	require(self.scriptPath.."ITB-ModUtils/modApiExt/modApiExt"):init()
	require(self.scriptPath.."libs/modloaderfixes")
	require(self.scriptPath.."libs/artilleryArc")
	require(self.scriptPath.."libs/detectDeployment")
	require(self.scriptPath.."libs/blockDeathByDeployment")
end

function mod:load(options, version)
	require(self.scriptPath.."ITB-ModUtils/modApiExt/modApiExt"):load(options, version)
end

return mod
