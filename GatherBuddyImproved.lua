-----------------------------------------------------------------------------------------------
-- GatherBuddyImproved
-- Copyright (c) SpaceWalker <ddv@qubitlogic.net> - GPLv3
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Unit"
require "GameLib"
require "ChatSystemLib"
require "Apollo"
require "math"
require "CraftingLib"
require "PlayerPathLib"

 
-----------------------------------------------------------------------------------------------
-- GatherBuddyImproved Module Definition
-----------------------------------------------------------------------------------------------
local GatherBuddyImproved = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon(
	"GatherBuddyImproved",
	"GBI",
	{ 
		"Gemini:Logging-1.2",
		"Gemini:Locale-1.0",
		"Gemini:DB-1.0"
	}
)


-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

-- Use constants to keep from having magic strings and numbers spread around.

local SETTLER_RACE_ID = 269 -- This is the RaceID identified for settler resources.
local SETTLER_PATH_ID = 1 -- Value returned by PlayerPathLib:GetPlayerPathType() for settlers.
local SETTLER_AFFILIATION = '<Settler Resource>'

local SETTLER = 'Collectible' 
local HARVEST = 'Harvest'

local FARMING 	  = 20
local SURVIVALIST = 15
local RELICHUNTER = 18
local MINING 	  = 13
local FISHING 	  = 19
local ARROW_BELOW = 99 --non colliding placeholder value
local ARROW_ABOVE = 88 --''

local CFG_FARMER_BTN 	  = 'FarmingBtn'
local CFG_MINER_BTN 	  = 'MiningBtn'
local CFG_SURVIVALIST_BTN = 'SurvivalistBtn'
local CFG_RELICHUNTER_BTN = 'RelicHunterBtn'
local CFG_SETTLER_BTN 	  = 'SettlerBtn'
local CFG_ARROWS_BTN 	  = 'ArrowsBtn'

local CFG_TIER1_BTN = 'Tier1Btn'
local CFG_TIER2_BTN = 'Tier2Btn'
local CFG_TIER3_BTN = 'Tier3Btn'
local CFG_TIER4_BTN = 'Tier4Btn'
local CFG_TIER5_BTN = 'Tier5Btn'

local CFG_HIDEALL_BTN = 'HideAllBtn'
local CFG_COLOR_WND   = 'ChangeColorWnd'
local CFG_COLOR_BTN   = 'ChangeColorBtn'

local CFG_COLOR_ARROW_ABOVE_BTN = 'ChangeColorArrowAboveBtn'
local CFG_COLOR_ARROW_ABOVE_WND = 'ChangeColorArrowAboveWnd'
local CFG_COLOR_ARROW_BELOW_BTN = 'ChangeColorArrowBelowBtn'
local CFG_COLOR_ARROW_BELOW_WND = 'ChangeColorArrowBelowWnd'

local CFG_RESOURCE_NODE 	= 'ResourceNode'
local CFG_RESOURCE_NODE_BTN = 'ResourceNodeBtn'

local CFG_LIST_CHECKALL_BTN  = 'ListCheckAllBtn'
local CFG_LIST_CHECKNONE_BTN = 'ListCheckNoneBtn'

local tierRelation = {
	[CFG_TIER1_BTN] = 1,
	[CFG_TIER2_BTN] = 2,
	[CFG_TIER3_BTN] = 3,
	[CFG_TIER4_BTN] = 4,
	[CFG_TIER5_BTN] = 5
}

local sectionRelation = {
	[CFG_FARMER_BTN] 	  = FARMING,
	[CFG_MINER_BTN]       = MINING,
	[CFG_SURVIVALIST_BTN] = SURVIVALIST,
	[CFG_RELICHUNTER_BTN] = RELICHUNTER,
	[CFG_SETTLER_BTN] 	  = SETTLER
}

local btnSectionRelation = {
	[FARMING] 	  = CFG_FARMER_BTN,
	[MINING] 	  = CFG_MINER_BTN,
	[SURVIVALIST] = CFG_SURVIVALIST_BTN,
	[RELICHUNTER] = CFG_RELICHUNTER_BTN,
	[SETTLER] 	  = CFG_SETTLER_BTN
}

local dbDefaults = {
	char = {
		initialized = false,
		enabled = true,
		colors = {
			[FARMING] 	  = "bbddd400",
			[SURVIVALIST] = "bb37dd00",
			[RELICHUNTER] = "bbdb00dd",
			[MINING] 	  = "bbdd6a00",
			[SETTLER] 	  = "bb3052dc",
			[ARROW_ABOVE] = "bbddd400",
			[ARROW_BELOW] = "bbdd6a00"
		},
		offsets = {},
		cfgWinState = {
			[CFG_FARMER_BTN] = {
				all = {
					[1] = false,
					[2] = false,
					[3] = false,
					[4] = false,
					[5] = false
				},
				none = {
					[1] = true,
					[2] = true,
					[3] = true,
					[4] = true,
					[5] = true
				},
				tier = CFG_TIER1_BTN,
			},
			[CFG_MINER_BTN] = {
				all = {
					[1] = false,
					[2] = false,
					[3] = false,
					[4] = false,
					[5] = false
				},
				none = {
					[1] = true,
					[2] = true,
					[3] = true,
					[4] = true,
					[5] = true
				},
				tier = CFG_TIER1_BTN,
			},
			[CFG_SURVIVALIST_BTN] = {
				all = {
					[1] = false,
					[2] = false,
					[3] = false,
					[4] = false,
					[5] = false
				},
				none = {
					[1] = true,
					[2] = true,
					[3] = true,
					[4] = true,
					[5] = true
				},
				tier = CFG_TIER1_BTN,
			},
			[CFG_RELICHUNTER_BTN] = {
				all = {
					[1] = false,
					[2] = false,
					[3] = false,
					[4] = false,
					[5] = false
				},
				none = {
					[1] = true,
					[2] = true,
					[3] = true,
					[4] = true,
					[5] = true
				},
				tier = CFG_TIER1_BTN,
			},
			[CFG_SETTLER_BTN] = {
				all = {
					[1] = false,
					[2] = false,
					[3] = false,
					[4] = false,
					[5] = false
				},
				none = {
					[1] = true,
					[2] = true,
					[3] = true,
					[4] = true,
					[5] = true
				},
				tier = CFG_TIER1_BTN,
			},
			current = {
				btn = CFG_FARMER_BTN,
				section = FARMING
			}
		},
		filters = {
			[FARMING] = {
				whitelist = {}
			},
			[SURVIVALIST] = {
				whitelist = {}
			},
			[RELICHUNTER] = {
				whitelist = {}
			},
			[MINING] = {
				whitelist = {}
			},
			[SETTLER] = {
				whitelist = {}
			}
		}
  },
  global = {
		tradeskills = {
			[FARMING] = {
				[1] = {
					['Yellowbell'] = true,
					['Spirovine'] = true,
					['Bladeleaf'] = true,
					['Pummelgranate'] = true
				},
				[2] = {
					['Serpentlily'] = true,
					['Crowncorn'] = true,
					['Goldleaf'] = true,
					['Honeywheat'] = true
				},
				[3] = {
					['Coralscale'] = true,
					['Glowmelon'] = true,
					['Logicleaf'] = true,
					['Stoutroot'] = true
				},
				[4] = {
					['Faerybloom'] = true,
					['Witherwood'] = true,
					['Flamefrond'] = true,
					['Grimgourd'] = true
				},
				[5] = {
					['Mourningstar'] = true,
					['Bloodbriar'] = true,
					['Octopod'] = true,
					['Heartichoke'] = true
				}
			},
			[SURVIVALIST] = {
				[1] = {
					['Algoroc Tree'] = true,
					['Celestion Tree'] = true,
					['Deradune Tree'] = true
				},
				[2] = {
					['Galeras Tree'] = true,
					['Ellevar Tree'] = true
				},
				[3] = {
					['Farside Tree'] = true,
					['Whitevale Tree'] = true
				},
				[4] = {
					['Malgrave Tree'] = true
				},
				[5] = {
					['Grimvault Tree'] = true
				}
			},
			[RELICHUNTER] = {
				[1] = {
					['Standard Relic Node'] = true
				},
				[2] = {
					['Accelerated Relic Node'] = true
				},
				[3] = {
					['Advanced Relic Node'] = true
				},
				[4] = {
					['Dynamic Relic Node'] = true
				},
				[5] = {
					['Kinetic Relic Node'] = true
				}
			},
			[MINING] = {
				[1] = {
					['Iron Node'] = true
				},
				[2] = {
					['Titanium Node'] = true,
					['Zephyrite Node'] = true
				},
				[3] = {
					['Hydrogem Node'] = true,
					['Platinum Node'] = true
				},
				[4] = {
					['Shadeslate Node'] = true,
					['Xenocite Node'] = true
				},
				[5] = {
					['Galactium Node'] = true,
					['Novacite Node'] = true
				}
			},
			[SETTLER] = { -- Special thanks to ßombshell@Avatus for providing the bulk of this list.
				[1] = {
					['Triple-Arc Batteries'] = true,
					['Pulsating Power Crystal'] = true,
					['Structural Carbon Rod'] = true,
				},
				[2] = {
					['Steel Stem Stalks'] = true,
					['Nexus Polymorphic Clay'] = true,
				},
				[3] = {
					['Bio-Memetic Mud'] = true,
					['Survival Supply Stash'] = true,
					['Energized Heavy Water'] = true,
				},
				[4] = {
					['Resonating Isotopic Rock'] = true,
					['Warped Exoplating'] = true,
					['Regenerative Fuelcell'] = true,
					['Heavy Fused Bone'] = true,
					['Ancestral Force-Stone'] = true,
					['Iron-Coil Vine'] = true,
				},
				[5] = {
					['Residual Mega-Freezon'] = true,
					['Lustrous Xenolithic Stone'] = true,
					['Anti-Entropic Fluid'] = true,
					['Eldan Power Fragment'] = true,
					['Uncorruptable Soul Stone'] = true,
					['Annihilite Ingot'] = true,
				}
			},
		},
		nodes_found = {
		}
  }
}

local TradeSkills = {}

local GeminiLogging
local glog
local GeminiLocale
local L
local GeminiColor
--local Rover

-- Thank you so much to Aytherine and Ayth_Quest for providing this preload algorithm. This is what allows us
-- to grab items on screen refresh. Without this a reloadui will produce an empty unitList thanks to bad event timing
-- (the units are spawned before our eventhandler is registered)
GBI_Preload = {}
GBI_Preload.units = {}

function GBI_Preload_Event(unit)
	if GBI_Preload then
		table.insert(GBI_Preload.units, unit)
	else
		Apollo.RemoveEventHandler("UnitCreated", self)
	end
end


Apollo.RegisterEventHandler("UnitCreated", "GBI_Preload_Event")


-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------

function GatherBuddyImproved:OnInitialize()
	GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
	glog = GeminiLogging:GetLogger({
		level = GeminiLogging.FATAL,
		pattern = "%d [%n] %l - %m",
		appender = "GeminiConsole"
	})

	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, dbDefaults)
	GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
	L = GeminiLocale:GetLocale("GatherBuddyImproved", true)
	
	GeminiColor = Apollo.GetPackage("GeminiColor").tPackage

	Apollo.RegisterSlashCommand("gbi", "OnGatherBuddyImprovedOn", self)
	self.xmlDoc = XmlDoc.CreateFromFile("GatherBuddyImproved.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	
	--Rover = Apollo.GetAddon("Rover")
end

-----------------------------------------------------------------------------------------------
-- GatherBuddyImproved OnLoad
-----------------------------------------------------------------------------------------------



function GatherBuddyImproved:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "GatherBuddyImprovedForm", nil, self)
		self.wndCFG = Apollo.LoadForm(self.xmlDoc, "GBIConfigForm", nil, self)	
		
		self.wndCFGNode = self.wndCFG:FindChild("NodeSelection")
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
		self:AddTradeskills()

		self.unitList = {}
		self.windowList = {}
		self.wndMain:Show(self.db.char.enabled)
	    self.wndCFG:Show(false)
	    self.wndBuddy = self.wndMain:FindChild("Buddy")
		if self.db.char.offsets.nOL then
			self.wndBuddy:SetAnchorOffsets(self.db.char.offsets.nOL, self.db.char.offsets.nOT, self.db.char.offsets.nOR, self.db.char.offsets.nOB)
		end
		self.wndInternal = self.wndBuddy:FindChild("Internal")

		self.timer = ApolloTimer.Create(1.0, true, "OnTimer", self)

		--Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
		self.db.RegisterCallback(self, "OnDatabaseShutdown", "SaveConfig")
		
		Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
		Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)	

		self.delayStartTime = ApolloTimer.Create(0.5, true, "OnDelayedStart", self)
		
		for name, color in pairs(self.db.char.colors) do
			glog:debug('%s color is %s', name, color)
		end
		
		--local sectionRelationRev = sectionRelation:swapped()
		--Rover:AddWatch('Swap example', sectionRelation)

		--GeminiLocale:TranslateWindow(L, self.wndCFG)
		--Rover:AddWatch('db', self.db)
	end
end

function GatherBuddyImproved:SaveConfig(db)
	self.db.char.offsets.nOL, self.db.char.offsets.nOT, self.db.char.offsets.nOR, self.db.char.offsets.nOB = self.wndBuddy:GetAnchorOffsets()
end


-----------------------------------------------------------------------------------------------
-- GatherBuddyImproved Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

function GatherBuddyImproved:OnDelayedStart()
	if not GameLib.GetPlayerUnit() then return end
	
	self.delayStartTime:Stop()

	for idx, unit in ipairs(GBI_Preload.units) do
		self:OnUnitCreated(unit)
		--Print(unit:GetName())
	end
	GBI_Preload = nil
end

function GatherBuddyImproved:Announce(msg)
	ChatSystemLib.PostOnChannel(2, 'GBI: ' .. msg)
end

function GatherBuddyImproved:ClearUnit(unit)
	glog:debug('ClearUnit %s %s', unit:GetName(), tostring(nuke))
	local uId = unit:GetId()
	if self.unitList[uId] then self.unitList[uId] = nil
	end
	if self.windowList[uId] then 
		self.windowList[uId].wnd:Destroy()
		self.windowList[uId] = nil
	end
end

function GatherBuddyImproved:OnConfigure(sCommand, sArgs)
	self.wndCFG:Show(false)
	self:ToggleWindow()
end

function GatherBuddyImproved:AddTradeskills()
	for code, id in pairs(CraftingLib.CodeEnumTradeskill) do
		--Normally we'd build this array in the opposite direction but for speed of lookup, it was done this way.
		TradeSkills[CraftingLib.GetTradeskillInfo(id).strName] = id
	end
	
	for _,ts in pairs(CraftingLib.GetKnownTradeskills()) do
		glog:debug('Tradeskill %s with id %d', ts.strName, ts.eId)
		-- we only want to autoshow based on user tradeskills if the user hasn't hidden it manually
		if self.db.char.filters[ts.eId] and self.db.char.initialized == false then
			self:InitializeFilter(ts.eId)
		end
	end
	self.db.char.initialized = true
end

function GatherBuddyImproved:InitializeFilter(ts)
	local tsData = self.db.global.tradeskills[ts]
	local cState = {
		currentBtn = btnSectionRelation[ts]
	}
	
	self:CheckAllNone(cState, true, true)
	
	for tier,tData in pairs(tsData) do
		for name,_ in pairs(tData) do
			self.db.char.filters[ts].whitelist[name] = true
		end
	end
end

local function SortTableByName(a, b)
	return a:GetData().nodeName < b:GetData().nodeName
end

function GatherBuddyImproved:GetCurrentCFGWinState()
	local _cfgWinState = self.db.char.cfgWinState
	
	local _currentBtn = _cfgWinState.current.btn
	local _currentSection = _cfgWinState.current.section
	local _tierBtn = _cfgWinState[_currentBtn].tier
	local _tier = tierRelation[_tierBtn]
	local _checkAll = _cfgWinState[_currentBtn].all[_tier]
	local _checkNone = _cfgWinState[_currentBtn].none[_tier]
	
	return {
		currentBtn = _currentBtn,
		currentSection = _currentSection,
		tierBtn = _tierBtn,
		tier = _tier,
		checkAll = _checkAll,
		checkNone = _checkNone
	}
end

function GatherBuddyImproved:InitializeForm()
	if not self.wndCFG then
		return
	end
	self:DrawForm()
end

function GatherBuddyImproved:DrawForm()
	--Do cleanup
	self.wndCFGNode:DestroyChildren()
	
	for btn,_ in pairs(tierRelation) do
		self.wndCFG:FindChild(btn):SetCheck(false)
	end
	
	
	--Display current state
	local cState = self:GetCurrentCFGWinState()
	
	self.wndCFG:FindChild(cState.currentBtn):SetCheck(true)
	self.wndCFG:FindChild(cState.tierBtn):SetCheck(true)
	self.wndCFG:FindChild(CFG_COLOR_WND):SetBGColor(self.db.char.colors[cState.currentSection])
	self.wndCFG:FindChild(CFG_COLOR_BTN):SetData({ color = self.db.char.colors[cState.currentSection] })
	self.wndCFG:FindChild(CFG_COLOR_ARROW_ABOVE_BTN):SetData({ color = self.db.char.colors[ARROW_ABOVE] })
	self.wndCFG:FindChild(CFG_COLOR_ARROW_ABOVE_WND):SetBGColor(self.db.char.colors[ARROW_ABOVE])
	self.wndCFG:FindChild(CFG_COLOR_ARROW_BELOW_BTN):SetData({ color = self.db.char.colors[ARROW_BELOW] })
	self.wndCFG:FindChild(CFG_COLOR_ARROW_BELOW_WND):SetBGColor(self.db.char.colors[ARROW_BELOW])
	self.wndCFG:FindChild(CFG_LIST_CHECKALL_BTN):SetCheck(cState.checkAll)
	self.wndCFG:FindChild(CFG_LIST_CHECKNONE_BTN):SetCheck(cState.checkNone)
	
	for name,_ in pairs(self.db.global.tradeskills[cState.currentSection][cState.tier]) do
		local wlNodeSelect = Apollo.LoadForm(self.xmlDoc, CFG_RESOURCE_NODE, self.wndCFGNode, self)
		local nodeData = { nodeName = name, section = cState.currentSection, tier = cState.tier }

	    wlNodeSelect:Show(true)
		wlNodeSelect:SetData(nodeData)
		
		if self:IsInWhitelist(nodeData) then
			glog:debug('%s is in whitelist, checking', name)
			wlNodeSelect:FindChild(CFG_RESOURCE_NODE_BTN):SetCheck(true)
		else
			wlNodeSelect:FindChild(CFG_RESOURCE_NODE_BTN):SetCheck(false)
		end
		
	    wlNodeSelect:FindChild(CFG_RESOURCE_NODE_BTN):SetText(name)
	end
	
	self.wndCFGNode:ArrangeChildrenVert(0, SortTableByName)
end

function GatherBuddyImproved:ToggleWindow()
	if self.wndCFG:IsVisible() then
		self.wndCFG:Close()
		self:ToggleOptionsWindow(false)
	else
		self:InitializeForm()
	
		self.wndCFG:Show(true)
		self.wndCFG:ToFront()
	end
end

-- on SlashCommand "/gbi"
function GatherBuddyImproved:OnGatherBuddyImprovedOn()
	self.wndMain:Show(not self.wndBuddy:IsVisible())

	if self.wndMain:IsVisible() then
		self:Announce(L['Enabled'])
		self.db.char.enabled = true
	else
		self:Announce(L['Disabled'])
		self.db.char.enabled = false
	end

end

local function SortTableByDist(a, b)
	return a:GetData().dist < b:GetData().dist
end


function GatherBuddyImproved:IsSettlerResource(unit)
	if unit:GetName() ~= nil and unit:GetType() == SETTLER and unit:GetUnitRaceId() == SETTLER_RACE_ID and unit:GetAffiliationName() == SETTLER_AFFILIATION then
		return true
	end
	return false
end

local function CleanName(name)
	local cleanName
	
	cleanName = name:gsub('Overgrown ', '')
	cleanName = cleanName:gsub('Active ', '')
	cleanName = cleanName:gsub(' Wurm', '')

	return cleanName
end

-- Disabling this function as we no longer need to build the base node database.
--function GatherBuddyImproved:AddNewResourceNode(unit)
	
--	local uName = CleanName(unit:GetName())
--	local harvestable
--	local tier
--	local ts
	
--	if not self.db.global.nodes_found[uName] then
--		self.db.global.nodes_found[uName] = true
		
--		if unit:GetType() == HARVEST then
--			harvestable= unit:GetHarvestRequiredTradeskillName()
--			tier = unit:GetHarvestRequiredTradeskillTier()
--			ts = TradeSkills[harvestable]
--		elseif unit:GetType() == SETTLER then
--			tier = 1
--			ts = SETTLER
--		end
		
--		if not self.db.global.tradeskills[ts][tier][uName] then
--			self.db.global.tradeskills[ts][tier][uName] = true
--		end
--	end
--end

--Disambiguation: This function is purely to decide if GBI should handle this unit or not.
--				  it does not filter based on the players choices. That's done in IsHidden
function GatherBuddyImproved:Displayable(unit)
	if GameLib.GetPlayerUnit() then
		if unit:GetType() == HARVEST then
			--self:AddNewResourceNode(unit)
			--if unit:CanBeHarvestedBy(GameLib.GetPlayerUnit()) then
			if unit:GetHarvestRequiredTradeskillName() then
				return true
			end
		elseif self:IsSettlerResource(unit) then
			--self:AddNewResourceNode(unit)
			
			glog:debug('Found Settler Resource: %s|%d|%s',unit:GetName(), unit:GetUnitRaceId(), unit:GetAffiliationName())
			
			--Rover:AddWatch(unit:GetName(), unit)
			return true
		end
	end
	
	return false
end

function GatherBuddyImproved:Identify(unit)
	local harvestible = unit:GetHarvestRequiredTradeskillName()
	local data = {
		nodeName = unit:GetName()
	}
		
	if harvestible then
		data.section = TradeSkills[harvestible]
	elseif self:IsSettlerResource(unit) then
		data.section = SETTLER
	end

	return data
end

function GatherBuddyImproved:IsInWhitelist(data)
	local filter = self.db.char.filters[data.section]
	if filter.whitelist[data.nodeName] then
		return true
	end
	return false
end

function GatherBuddyImproved:ShouldDisplayUnknownNode(unit)
	local name = unit:GetName()
	local harvestable = unit:GetHarvestRequiredTradeskillName()
	local tsID = TradeSkills[harvestable]

	if unit:CanBeHarvestedBy(GameLib.GetPlayerUnit()) and self.db.global.tradeskills[tsID][name] then
		glog:debug('Displaying unknown node: %s|%s', name, self.db.global.tradeskills[tsID][name])
		return true
	end
	return false
end

--Filter display based on users choices
function GatherBuddyImproved:IsHidden(unit)
	local data = self:Identify(unit)
	
	if unit:IsValid() then
		if self:IsInWhitelist(data) or self:ShouldDisplayUnknownNode(unit) then
			return false
		end
	end
	return true
end

-- on timer
function GatherBuddyImproved:OnTimer()
	if self.unitList and GameLib.GetPlayerUnit() then
		for _, unit in pairs(self.unitList) do
			local rShow = true
			local uId = unit:GetId()
			if self.windowList[uId] == nil then
				if self:IsHidden(unit) then
					rShow = false
				end

	            local newInner = Apollo.LoadForm(self.xmlDoc, "Inner", self.wndInternal, self)
	            newInner:Show(rShow)
	            local distToP = self:CalculateInfo(unit, newInner)
	            self.windowList[uId] = {wnd = newInner; dist = distToP; display = rShow; unit = uId; }
	            newInner:SetData(self.windowList[uId])
	        else	      
	        	local win = self.windowList[uId]
				
				if self:IsHidden(unit) then
					rShow = false
				end
				
	        	win.wnd:Show(rShow)
	        	win.dist = self:CalculateInfo(unit, win.wnd)
	       	end
	       	self.wndInternal:ArrangeChildrenVert(0, SortTableByDist)
		end
	end
end

function GatherBuddyImproved:OnUnitCreated(unit)
	if not unit or not unit:IsValid() then return end
	if self:Displayable(unit) then
		--Rover:AddWatch(unit:GetName(), unit)
		self.unitList[unit:GetId()] = unit
	end
end

function GatherBuddyImproved:OnUnitDestroyed(unit)
	if self:Displayable(unit) then
		self:ClearUnit(unit)
	end
end


function GatherBuddyImproved:CalculateInfo(madeUnit, newInner)
	local harvestable = madeUnit:GetHarvestRequiredTradeskillName()
	local itype = madeUnit:GetType()
	local unitPos = madeUnit:GetPosition()
	local unitName = string.sub(madeUnit:GetName(), 0, 30)
	local playerPos = GameLib:GetPlayerUnit():GetPosition()
	local arrowWnd = newInner:FindChild("Window")
	local rotX, rotY = playerPos.z - unitPos.z, unitPos.x - playerPos.x
	local wndRot = math.deg(math.atan2(rotY, rotX))
	local tFacing = GameLib:GetPlayerUnit():GetFacing()
	local pRot = math.deg(math.atan2(tFacing.x, - tFacing.z))
	if math.floor(unitPos.y) < math.floor(playerPos.y) then arrowWnd:SetBGColor(self.db.char.colors[ARROW_BELOW])
	elseif math.floor(unitPos.y) > math.floor(playerPos.y) then arrowWnd:SetBGColor(self.db.char.colors[ARROW_ABOVE])
	end
	local distToP = math.sqrt((playerPos.x-unitPos.x)^2+(playerPos.y-unitPos.y)^2+(playerPos.z-unitPos.z)^2)
	if type(wndRot) == "number" then
		newInner:FindChild("Window"):SetRotation(wndRot - pRot)
	end
	newInner:SetText(unitName .. " - " .. math.floor(distToP) .. "m")
	if harvestable then
		newInner:SetBGColor(self.db.char.colors[TradeSkills[harvestable]])
	elseif itype == SETTLER then
		newInner:SetBGColor(self.db.char.colors[SETTLER])
	end
	return distToP
end

function GatherBuddyImproved:CheckAllNodes(doCheck)
	local cState = self:GetCurrentCFGWinState()
	local nodeWindows = self.wndCFGNode:GetChildren()
	
	glog:debug('%s all nodes..', doCheck and 'Checking' or 'Unchecking')
	
	if doCheck then
		self.db.char.cfgWinState[cState.currentBtn].all[cState.tier] = true
		self.db.char.cfgWinState[cState.currentBtn].none[cState.tier] = false
	else
		self.db.char.cfgWinState[cState.currentBtn].all[cState.tier] = false
		self.db.char.cfgWinState[cState.currentBtn].none[cState.tier] = true
	end
	
	if nodeWindows then
		for _,wnd in pairs(nodeWindows) do
			local data = wnd:GetData()
			
			wnd:FindChild(CFG_RESOURCE_NODE_BTN):SetCheck(doCheck)
			self:ModifyWhitelistItem(data.nodeName, doCheck)	
		end
	end
end

function GatherBuddyImproved:UncheckAllNone()
	local cState = self:GetCurrentCFGWinState()
	
	self.wndCFG:FindChild(CFG_LIST_CHECKALL_BTN):SetCheck(false)
	self.wndCFG:FindChild(CFG_LIST_CHECKNONE_BTN):SetCheck(false)

	self.db.char.cfgWinState[cState.currentBtn].all[cState.tier] = false
	self.db.char.cfgWinState[cState.currentBtn].none[cState.tier] = false
end

function GatherBuddyImproved:OnGeminiColor(strColor)
	local wnd = self.wndCFG:FindChild(CFG_COLOR_WND)
	local btn = self.wndCFG:FindChild(CFG_COLOR_BTN)
	local cState = self:GetCurrentCFGWinState()
	
	glog:debug('Setting section color: %s', strColor)
	
	self.db.char.colors[cState.currentSection] = strColor
	wnd:SetBGColor(strColor)
	btn:SetData({ color = strColor })
end

function GatherBuddyImproved:OnGeminiArrowAboveColor(strColor)
	local wnd = self.wndCFG:FindChild(CFG_COLOR_ARROW_ABOVE_WND)
	local btn = self.wndCFG:FindChild(CFG_COLOR_ARROW_ABOVE_BTN)
	
	glog:debug('Setting arrow above color: %s', strColor)
	
	self.db.char.colors[ARROW_ABOVE] = strColor
	wnd:SetBGColor(strColor)
	btn:SetData({ color = strColor })
end

function GatherBuddyImproved:OnGeminiArrowBelowColor(strColor)
	local wnd = self.wndCFG:FindChild(CFG_COLOR_ARROW_BELOW_WND)
	local btn = self.wndCFG:FindChild(CFG_COLOR_ARROW_BELOW_BTN)
	
	glog:debug('Setting arrow below color: %s', strColor)
	
	self.db.char.colors[ARROW_BELOW] = strColor
	wnd:SetBGColor(strColor)
	btn:SetData({ color = strColor })
end

function GatherBuddyImproved:ModifyWhitelistItem(name, add)
	local cState = self:GetCurrentCFGWinState()
	
	self.db.char.filters[cState.currentSection].whitelist[name] = add
	
	glog:debug("%s %s %s %s whitelist", add and 'Added' or 'Removed', name, add and 'to' or 'from',cState.currentSection)
end

function GatherBuddyImproved:SetCFGWinStateTier(tierBtn)
	local cState = self:GetCurrentCFGWinState()
	
	self.db.char.cfgWinState[cState.currentBtn].tier = tierBtn
end

function GatherBuddyImproved:SetCFGWinStateSection(sectionBtn, section)
	self.db.char.cfgWinState.current.btn = sectionBtn
	self.db.char.cfgWinState.current.section = section
end

function GatherBuddyImproved:ShowAllNodes()
	local cState = self:GetCurrentCFGWinState()
	
	self:InitializeFilter(cState.currentSection)	
	
	if cState.currentSection == SETTLER then
		oStr = 'Settler'
	else
		oStr = CraftingLib.GetTradeskillInfo(cState.currentSection).strName
	end

	
	self:Announce("Showing all " .. oStr .. " nodes.")
end

function GatherBuddyImproved:HideAllNodes()
	local cState = self:GetCurrentCFGWinState()

	self.db.char.filters[cState.currentSection].whitelist = {}
	
	if cState.currentSection == SETTLER then
		oStr = 'Settler'
	else
		oStr = CraftingLib.GetTradeskillInfo(cState.currentSection).strName
	end
	
	self:Announce("Hiding all " .. oStr .. " nodes.")
end


function GatherBuddyImproved:CheckAllNone(cState, allNone, global)
	
	if allNone then
		all = true
		none = false
	else
		all = false
		none = true
	end
	
	self.wndCFG:FindChild(CFG_LIST_CHECKALL_BTN):SetCheck(all)
	self.wndCFG:FindChild(CFG_LIST_CHECKNONE_BTN):SetCheck(none)
	
	if global then	
		for tier,_ in pairs(self.db.char.cfgWinState[cState.currentBtn].all) do
			self.db.char.cfgWinState[cState.currentBtn].all[tier] = all
		end
		for tier,_ in pairs(self.db.char.cfgWinState[cState.currentBtn].none) do
			self.db.char.cfgWinState[cState.currentBtn].none[tier] = none
		end
	else
		self.db.char.cfgWinState[cState.currentBtn].all[cState.tier] = all
		self.db.char.cfgWinState[cState.currentBtn].none[cState.tier] = none
	end
end

function GatherBuddyImproved:ToggleOptionsWindow(wShow)
	self.wndCFG:FindChild('OptionsContainer'):Show(wShow)
	self.wndCFG:FindChild('OptionsBtn'):SetCheck(wShow)
end

---------------------------------------------------------------------------------------------------
-- GBIConfigForm Functions
---------------------------------------------------------------------------------------------------
function GatherBuddyImproved:OnResetDB( wndHandler, wndControl, eMouseButton )
	
	self.db:ResetDB()
	ChatSystemLib.Command('/reloadui')
	
	self:Announce("Reset success, clean as a baby.")
end

function GatherBuddyImproved:OnCheckAll( wndHandler, wndControl, eMouseButton )
	if wndControl:IsChecked() then
		self:CheckAllNodes(true)
	end
end


function GatherBuddyImproved:OnCheckNone( wndHandler, wndControl, eMouseButton )
	if wndControl:IsChecked() then
		self:CheckAllNodes(false)
	end
end

function GatherBuddyImproved:OnColorChange( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl or eMouseButton ~= GameLib.CodeEnumInputMouse.Left then return end --only launch on left click
	
	local data = wndControl:GetData()
	local cColor = data.color
	
	glog:debug('Showing color picker')

	GeminiColor:ShowColorPicker(self, self.OnGeminiColor, true, cColor)
end

function GatherBuddyImproved:OnTierBtnCheck( wndHandler, wndControl, eMouseButton )
	if wndControl:IsChecked() then
		glog:debug('Showing tier %d', tierRelation[wndControl:GetName()])
		self:SetCFGWinStateTier(wndControl:GetName())	

		glog:debug('Reloading window')
		self:DrawForm()
	end
end

function GatherBuddyImproved:OnSectionBtnCheck( wndHandler, wndControl, eMouseButton )
	if wndControl:IsChecked() then
		local section = sectionRelation[wndControl:GetName()]
		glog:debug('Showing section %s', section)
		self:SetCFGWinStateSection(wndControl:GetName(), section)		
		
		glog:debug('Reloading window')
		self:DrawForm()
	end
end

function GatherBuddyImproved:OnHideAll( wndHandler, wndControl, eMouseButton )
	self:CheckAllNodes(false)
	self:HideAllNodes()
	self:CheckAllNone(self:GetCurrentCFGWinState(), false,true)
end

function GatherBuddyImproved:OnShowAll( wndHandler, wndControl, eMouseButton )
	self:CheckAllNodes(true)
	self:ShowAllNodes()
	self:CheckAllNone(self:GetCurrentCFGWinState(), true,true)
end

function GatherBuddyImproved:OnOptionsMenuToggle( wndHandler, wndControl, eMouseButton )
	if wndControl:IsChecked() then
		self:ToggleOptionsWindow(true)
	else
		self:ToggleOptionsWindow(false)
	end
end

function GatherBuddyImproved:OnOptionsCloseClick( wndHandler, wndControl, eMouseButton )
	self:ToggleOptionsWindow(false)
end

function GatherBuddyImproved:OnArrowAboveColorChange( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl or eMouseButton ~= GameLib.CodeEnumInputMouse.Left then return end --only launch on left click
	
	local data = wndControl:GetData()
	local cColor = data.color
	
	glog:debug('Showing color picker arrow above')

	GeminiColor:ShowColorPicker(self, self.OnGeminiArrowAboveColor, true, cColor)
end

function GatherBuddyImproved:OnArrowBelowColorChange( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl or eMouseButton ~= GameLib.CodeEnumInputMouse.Left then return end --only launch on left click
	
	local data = wndControl:GetData()
	local cColor = data.color
	
	glog:debug('Showing color picker arrow below')

	GeminiColor:ShowColorPicker(self, self.OnGeminiArrowBelowColor, true, cColor)
end

function GatherBuddyImproved:OnHeaderClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	--ChatSystemLib.Command("/t SpaceWalker@Avatus Your addon rocks!")
end

---------------------------------------------------------------------------------------------------
-- ResourceNodeItem Functions
---------------------------------------------------------------------------------------------------
function GatherBuddyImproved:OnResourceNodeCheck( wndHandler, wndControl, eMouseButton )
	local data = wndControl:GetParent():GetData()
	self:UncheckAllNone()
	if wndControl:IsChecked() then
		glog:debug('Activated %s', data.nodeName)
		self:ModifyWhitelistItem(data.nodeName, true)
	else
		glog:debug('Deactivated %s', data.nodeName)
		self:ModifyWhitelistItem(data.nodeName, false)
	end
end


---------------------------------------------------------------------------------------------------
-- Inner Functions
---------------------------------------------------------------------------------------------------
function GatherBuddyImproved:OnNodeClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	local data = wndControl:GetData()
	local unit = GameLib.GetUnitById(data.unit)
	
	unit:ShowHintArrow()
end

