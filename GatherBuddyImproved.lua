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

local FARMING = 20
local SETTLER = 'Collectible' 
local SURVIVALIST = 15
local RELICHUNTER = 18
local MINING = 13
local FISHING = 19
local ARROW_BELOW = 99
local ARROW_ABOVE = 88

local dbDefaults = {
	char = {
		hide = {
			settler = true,
			farming = false,
			relichunter = false,
			mining = false,
			fishing = false,
			survivalist = false
		},
		colors = {
			[FARMING] = ApolloColor.new("bbddd400"),
			[SURVIVALIST] = ApolloColor.new("bb37dd00"),
			[RELICHUNTER] = ApolloColor.new("bbdb00dd"),
			[MINING] = ApolloColor.new("bbdd6a00"),
			[FISHING] = ApolloColor.new("bb3052dc"),
			[SETTLER] = ApolloColor.new("bb3052dc"),
			[ARROW_ABOVE] = ApolloColor.new("bbddd400"),
			[ARROW_BELOW] = ApolloColor.new("bbdd6a00")
		},
		offsets = {}	 
  }
}

local TradeSkills = {}

local GeminiLogging
local glog
local GeminiLocale
local L

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
end

-----------------------------------------------------------------------------------------------
-- GatherBuddyImproved OnLoad
-----------------------------------------------------------------------------------------------



function GatherBuddyImproved:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "GatherBuddyImprovedForm", nil, self)
		self.wndCFG = Apollo.LoadForm(self.xmlDoc, "GBIConfigForm", nil, self)	
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
	
	--self.wndCFG:FindChild("HideFarmingCheckbox"):SetCheck(self:GetHideFarming())
	--self.wndCFG:FindChild("HideSettlerCheckbox"):SetCheck(self:GetHideSettler())
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

--Disambiguation: This function is purely to decide if GBI should handle this unit or not.
--				  it does not filter based on the players choices. That's done in IsHidden
function GatherBuddyImproved:Displayable(unit)
	if GameLib.GetPlayerUnit() then
		if unit:GetType() == 'Harvest' then
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
	-- This is not to set a color based on tradeskill type, it's simply changing the color if the node is above you or below you
	if math.floor(unitPos.y) < math.floor(playerPos.y) then arrowWnd:SetBGColor(colorCodeTradeskill[MINING])
	elseif math.floor(unitPos.y) > math.floor(playerPos.y) then arrowWnd:SetBGColor(colorCodeTradeskill[FARMING])
	end
	local distToP = math.sqrt((playerPos.x-unitPos.x)^2+(playerPos.y-unitPos.y)^2+(playerPos.z-unitPos.z)^2)
	if type(wndRot) == "number" then
		newInner:FindChild("Window"):SetRotation(wndRot - pRot)
	end
	newInner:SetText(unitName .. " - " .. math.floor(distToP) .. "m")
	if harvestable then
		newInner:SetBGColor(colorCodeTradeskill[harvestable])
	elseif itype == SETTLER then
		newInner:SetBGColor(colorCodeTradeskill[SETTLER])
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
