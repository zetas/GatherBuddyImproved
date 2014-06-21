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

local SETTLER_RACE_ID = 269 -- This is the RaceID identified for settler resources.

-- Use constants to keep from having magic strings and numbers spread around.
local SETTLER = 'Collectible' 

local FARMING 	  = 20
local SURVIVALIST = 15
local RELICHUNTER = 18
local MINING 	  = 13
local FISHING 	  = 19
local ARROW_BELOW = 99
local ARROW_ABOVE = 88

local CFG_FARMER_BTN = 'FarmingBtn'
local CFG_MINER_BTN = 'MiningBtn'
local CFG_SURVIVALIST_BTN = 'SurvivalistBtn'
local CFG_RELICHUNTER_BTN = 'RelicHunterBtn'
local CFG_SETTLER_BTN = 'SettlerBtn'
local CFG_ARROWS_BTN = 'ArrowsBtn'

local CFG_TIER1_BTN = 'Tier1Btn'
local CFG_TIER2_BTN = 'Tier2Btn'
local CFG_TIER3_BTN = 'Tier3Btn'
local CFG_TIER4_BTN = 'Tier4Btn'
local CFG_TIER5_BTN = 'Tier5Btn'

local CFG_HIDEALL_BTN = 'HideAllBtn'
local CFG_COLOR_BTN = 'ChangeColorBtn'

local tierRelation = {
	[CFG_TIER1_BTN] = 1,
	[CFG_TIER2_BTN] = 2,
	[CFG_TIER3_BTN] = 3,
	[CFG_TIER4_BTN] = 4,
	[CFG_TIER5_BTN] = 5
}

local dbDefaults = {
	char = {
		colors = {
			[FARMING] 	  = ApolloColor.new("bbddd400"),
			[SURVIVALIST] = ApolloColor.new("bb37dd00"),
			[RELICHUNTER] = ApolloColor.new("bbdb00dd"),
			[MINING] 	  = ApolloColor.new("bbdd6a00"),
			[SETTLER] 	  = ApolloColor.new("bb3052dc"),
			[ARROW_ABOVE] = ApolloColor.new("bbddd400"),
			[ARROW_BELOW] = ApolloColor.new("bbdd6a00")
		},
		offsets = {},
		cfgWinState = {
			[CFG_FARMER_BTN] = {
				tier = CFG_TIER1_BTN,
			},
			[CFG_MINER_BTN] = {
				tier = CFG_TIER1_BTN,
			},
			[CFG_SURVIVALIST_BTN] = {
				tier = CFG_TIER1_BTN,
			},
			[CFG_RELICHUNTER_BTN] = {
				tier = CFG_TIER1_BTN,
			},
			[CFG_SETTLER_BTN] = {
				tier = CFG_TIER1_BTN,
			},
			current = {
				btn = CFG_FARMER_BTN,
				section = FARMING
			}
		},
		filters = {
			[FARMING] = {
				hide = false,
				whitelist = {}
			},
			[SURVIVALIST] = {
				hide = 1,
				whitelist = {}
			},
			[RELICHUNTER] = {
				hide = 1,
				whitelist = {}
			},
			[MINING] = {
				hide = 1,
				whitelist = {}
			},
			[SETTLER] = {
				hide = 1,
				whitelist = {}
			}
		}
  },
  global = {
		tradeskills = {
			[FARMING] = {
				[1] = {
				},
				[2] = {
				},
				[3] = {
				},
				[4] = {
				},
				[5] = {
				}
			},
			[SURVIVALIST] = {
				[1] = {
				},
				[2] = {
				},
				[3] = {
				},
				[4] = {
				},
				[5] = {
				}
			},
			[RELICHUNTER] = {
				[1] = {
				},
				[2] = {
				},
				[3] = {
				},
				[4] = {
				},
				[5] = {
				}
			},
			[MINING] = {
				[1] = {
				},
				[2] = {
				},
				[3] = {
				},
				[4] = {
				},
				[5] = {
				}
			},
			[SETTLER] = {
				[1] = {
				},
				[2] = {
				},
				[3] = {
				},
				[4] = {
				},
				[5] = {
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
local Rover

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
		level = GeminiLogging.DEBUG,
		pattern = "%d [%n] %l - %m",
		appender = "GeminiConsole"
	})

	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, dbDefaults)
	GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
	L = GeminiLocale:GetLocale("GatherBuddyImproved", true)

	Apollo.RegisterSlashCommand("gbi", "OnGatherBuddyImprovedOn", self)
	self.xmlDoc = XmlDoc.CreateFromFile("GatherBuddyImproved.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	
	Rover = Apollo.GetAddon("Rover")
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
		self.wndMain:Show(true)
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

		GeminiLocale:TranslateWindow(L, self.wndCFG)
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

function GatherBuddyImproved:SetHide(prof, hide)
end

function GatherBuddyImproved:SetHideSettler(value)
	if self.db.char.hideSettler == value then
		return
	end	
	
	self.db.char.hideSettler = value
	
	if value then
		self:Announce(L['Hiding settler resources.'])
		self:ToggleResourceType(SETTLER, false)
	else
		self:ToggleResourceType(SETTLER, true)
		self:Announce(L['Showing new settler resources.'])
	end
end

function GatherBuddyImproved:GetHideSettler()
	return self.db.char.hideSettler
end

function GatherBuddyImproved:SetHideFarming(value)
	if self.db.char.hideFarming == value then
		return
	end	

	self.db.char.hideFarming = value

	if value then
		self:Announce(L['Hiding farming resources.'])
		self:ToggleResourceType(FARMING, false)
	else
		self:ToggleResourceType(FARMING, true)
		self:Announce(L['Showing new farming resources.'])
	end
end

function GatherBuddyImproved:GetHideFarming()
	return self.db.char.hideFarming
end

function GatherBuddyImproved:AddTradeskills()
	for code, id in pairs(CraftingLib.CodeEnumTradeskill) do
		--Normally we'd build this array in the opposite direction but for speed of lookup, it was done this way.
		TradeSkills[CraftingLib.GetTradeskillInfo(id).strName] = id
	end
	
	for _,ts in pairs(CraftingLib.GetKnownTradeskills()) do
		glog:debug('Tradeskill %s with id %d', ts.strName, ts.eId)
		-- we only want to autoshow based on user tradeskills if the user hasn't hidden it manually
		if self.db.char.filters[ts.eId] and self.db.char.filters[ts.eId].hide == 1 then
			self.db.char.filters[ts.eId].hide = false
		end
	end
	
	local pathlibinfo = PlayerPathLib.GetPlayerPathType()
	glog:debug('Player path type: %d', pathlibinfo)
	
	local tsinfo = CraftingLib.GetKnownTradeskills()
	Rover:AddWatch('ts info', tsinfo)
end

function GatherBuddyImproved:ToggleResourceType(rType, rDisplay)
	local condition = false
	if self.unitList and self.windowList then
		for _, unit in pairs(self.unitList) do
			if rType == FARMING then
				condition = (unit:GetHarvestRequiredTradeskillName() == rType)
			elseif rType == SETTLER then
				condition = (unit:GetType() == SETTLER)
			end
			if condition then
				glog:debug('%s %s', rDisplay and "Showing" or "Hiding", unit:GetName())
				local win = self.windowList[unit:GetId()]
				if win then
					win.display = rDisplay
				end
			end
		end
		self.wndInternal:ArrangeChildrenVert(0, SortTableByDist)
	end
end

function GatherBuddyImproved:InitializeForm()
	if not self.wndCFG then
		return
	end
	self.wndCFGNode:DestroyChildren()
	local cfgWinState = self.db.char.cfgWinState
	
	local currentBtn = cfgWinState.current.btn
	local currentSection = cfgWinState.current.section
	local tierBtn = cfgWinState[currentBtn].tier
	local tier = tierRelation[tierBtn]
	local hideAll = self.db.char.filters[currentSection].hide
	
	self.wndCFG:FindChild(currentBtn):SetCheck(true)
	self.wndCFG:FindChild(tierBtn):SetCheck(true)
	self.wndCFG:FindChild(CFG_HIDEALL_BTN):SetCheck(hideAll)
	
	for name,_ in pairs(self.db.global.tradeskills[currentSection][tier]) do
		local wlNodeSelect = Apollo.LoadForm(self.xmlDoc, "CustomizeFlairItem", self.wndCFGNode, self)
		local nodeData = { nodeName = name }
	    wlNodeSelect:Show(true)
		wlNodeSelect:SetData(nodeData)
	    wlNodeSelect:FindChild('CustomizeFlairBtn'):SetText(name)
		self.wndCFGNode:ArrangeChildrenVert()
	end	
end

function GatherBuddyImproved:ToggleWindow()
	if self.wndCFG:IsVisible() then
		self.wndCFG:Close()
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
	else
		self:Announce(L['Disabled'])
	end

end

local function SortTableByDist(a, b)
	return a:GetData().dist < b:GetData().dist
end


function GatherBuddyImproved:IsSettlerResource(unit)
	if unit:GetName() ~= nil and unit:GetType() == SETTLER and unit:GetUnitRaceId() == SETTLER_RACE_ID then
		return true
	end
	return false
end

function GatherBuddyImproved:AddNewResourceNode(unit)
	Rover:AddWatch('db', self.db)
	
	if not self.db.global.nodes_found[unit:GetName()] then
		self.db.global.nodes_found[unit:GetName()] = true
		
		local harvestable = unit:GetHarvestRequiredTradeskillName()
		local tier = unit:GetHarvestRequiredTradeskillTier()
		local name = unit:GetName()
		
		if not self.db.global.tradeskills[TradeSkills[harvestable]][tier][name] then
			self.db.global.tradeskills[TradeSkills[harvestable]][tier][name] = true
		end
	end
end

--Disambiguation: This function is purely to decide if GBI should handle this unit or not.
--				  it does not filter based on the players choices. That's done in IsHidden
function GatherBuddyImproved:Displayable(unit)
	if GameLib.GetPlayerUnit() then
		if unit:GetType() == 'Harvest' then
			self:AddNewResourceNode(unit)
			if unit:CanBeHarvestedBy(GameLib.GetPlayerUnit()) then
				return true
			end
		elseif self:IsSettlerResource(unit) then
			return true
		end
	end
	
	return false
end

--Filter display based on users choices
function GatherBuddyImproved:IsHidden(unit)
	return false
end

-- on timer
function GatherBuddyImproved:OnTimer()
	if self.unitList and GameLib.GetPlayerUnit() then
		for _, unit in pairs(self.unitList) do
			local uId = unit:GetId()
			if self.windowList[uId] == nil then
				local rShow = true

				if self:IsHidden(unit) then
					rShow = false
				end

	            local newInner = Apollo.LoadForm(self.xmlDoc, "Inner", self.wndInternal, self)
	            newInner:Show(rShow)
	            local distToP = self:CalculateInfo(unit, newInner)
	            self.windowList[uId] = {wnd = newInner; dist = distToP; display = rShow;}
	            newInner:SetData(self.windowList[uId])
	        else	      
	        	local win = self.windowList[uId]
	        	win.wnd:Show(win.display)
	        	win.dist = self:CalculateInfo(unit, win.wnd)
	       	end
	       	self.wndInternal:ArrangeChildrenVert(0, SortTableByDist)
		end
	end
end

function GatherBuddyImproved:OnUnitCreated(unit)
	if not unit or not unit:IsValid() then return end
	if self:Displayable(unit) then
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

---------------------------------------------------------------------------------------------------
-- GatherBuddyImprovedConfigForm Functions
---------------------------------------------------------------------------------------------------

function GatherBuddyImproved:OnFarmingHideCheck( wndHandler, wndControl, eMouseButton )
	self:SetHideFarming(wndControl:IsChecked())
end

function GatherBuddyImproved:OnSettlerHideCheck( wndHandler, wndControl, eMouseButton )
	self:SetHideSettler(wndControl:IsChecked())
end
