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
local GatherBuddyImproved = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("GatherBuddyImproved", "GBI",
																							{ 
																								"Gemini:DB-1.0"
																							}
)


-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------


local DEBUG = false
local SETTLER_RACE_ID = 269 -- This is the RaceID identified for settler resources.

-- Use constants to keep from having magic strings and numbers spread around.
local FARMING = 'Farmer'
local SETTLER = 'Collectible' 
local SURVIVALIST = 'Survivalist'
local RELICHUNTER = 'Relic Hunter'
local MINING = 'Mining'
local FISHING = 'Fishing'

local colorCodeTradeskill = {
	[FARMING] = ApolloColor.new("bbddd400"),
	[SURVIVALIST] = ApolloColor.new("bb37dd00"),
	[RELICHUNTER] = ApolloColor.new("bbdb00dd"),
	[MINING] = ApolloColor.new("bbdd6a00"),
	[FISHING] = ApolloColor.new("bb3052dc"),
	[SETTLER] = ApolloColor.new("bb3052dc") -- Since there's no fishing nodes, i'll use the same color.
}

local dbDefaults = {
	char = {
    	hideFarming = false,
		hideSettler = true,
		tradeskills = {},
		offsets = {}	 
  }
}

local GeminiLocale
local L


-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------

function GatherBuddyImproved:OnInitialize()
	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, dbDefaults)
	GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
	L = GeminiLocale:GetLocale("GatherBuddyImproved", true)
	self:UpdateTranslations()

	Apollo.RegisterSlashCommand("gbi", "OnGatherBuddyImprovedOn", self)
	self.xmlDoc = XmlDoc.CreateFromFile("GatherBuddyImproved.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function GatherBuddyImproved:UpdateTranslations()
	colorCodeTradeskill[L[FARMING]] 	= colorCodeTradeskill[FARMING]
	colorCodeTradeskill[L[SETTLER]] 	= colorCodeTradeskill[SETTLER]
	colorCodeTradeskill[L[SURVIVALIST]] = colorCodeTradeskill[SURVIVALIST]
	colorCodeTradeskill[L[RELICHUNTER]] = colorCodeTradeskill[RELICHUNTER]
	colorCodeTradeskill[L[MINING]] 		= colorCodeTradeskill[MINING]
	colorCodeTradeskill[L[FISHING]] 	= colorCodeTradeskill[FISHING]


	
	SETTLER 	= L[SETTLER]
	SURVIVALIST = L[SURVIVALIST]
	RELICHUNTER = L[RELICHUNTER]
	MINING 		= L[MINING]
	FISHING 	= L[FISHING]
	FARMING 	= L[FARMING]
end


-----------------------------------------------------------------------------------------------
-- GatherBuddyImproved OnLoad
-----------------------------------------------------------------------------------------------



function GatherBuddyImproved:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "GatherBuddyImprovedForm", nil, self)
		self.wndCFG = Apollo.LoadForm(self.xmlDoc, "GatherBuddyImprovedConfigForm", nil, self)	
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
		self:AddTradeskills()
			
	    self.unitList = {}
	    self.wndMain:Show(true)
	    self.wndCFG:Show(false)
	    self.wndBuddy = self.wndMain:FindChild("Buddy")
		if self.db.char.offsets.nOL then
			self.wndBuddy:SetAnchorOffsets(self.db.char.offsets.nOL, self.db.char.offsets.nOT, self.db.char.offsets.nOR, self.db.char.offsets.nOB)
		end
		self.wndInternal = self.wndBuddy:FindChild("Internal")

		self.timer = ApolloTimer.Create(1.0, true, "OnTimer", self)
		self.cleanupTimer = ApolloTimer.Create(30.0, true, "OnCleanupTimer", self)

		--Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
		self.db.RegisterCallback(self, "OnDatabaseShutdown", "SaveConfig")
		
		Apollo.RegisterEventHandler("UnitCreated", "newUnitCreated", self)

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

function GatherBuddyImproved:OnCleanupTimer() 
	self:AddTradeskills()
end

function GatherBuddyImproved:debug(msg)
	if DEBUG then
		self:Announce(msg)
	end
end
function GatherBuddyImproved:Announce(msg)
	ChatSystemLib.PostOnChannel(2, 'GBI: ' .. msg)
end

function GatherBuddyImproved:OnConfigure(sCommand, sArgs)
	self.wndCFG:Show(false)
	self:ToggleWindow()
end

function GatherBuddyImproved:AddTradeskills()
	for idx, value in pairs(CraftingLib.GetKnownTradeskills()) do
		if type(value) == "table" then
	    	for k, ts in pairs(value) do
				if type(ts) == 'string' then
					self:Announce('Tradeskill Found: ' .. ts)
		        	if ts == SURVIVALIST  then
						self.db.char.tradeskills[SURVIVALIST] = true
					elseif ts == MINING then
						self.db.char.tradeskills[MINING] = true
					elseif ts == RELICHUNTER then
						self.db.char.tradeskills[RELICHUNTER] = true
					end
		      	end
			end
	    end
	end
end

function GatherBuddyImproved:CheckTradeSkill(ts)
	if self.db.char.tradeskills[ts] then
		return true
	end
	return false
end

function GatherBuddyImproved:SetHideSettler(value)
	if self.db.char.hideSettler == value then
		return
	end	
	
	self.db.char.hideSettler = value
	
	if value then
		self:Announce(L['Hiding settler resources.'])
		if self.unitList then
			for idx, v in pairs(self.unitList) do
				local madeUnit = GameLib.GetUnitById(idx)
				local iType = madeUnit:GetType()
				if iType == SETTLER then
					v.wnd:Destroy()
					self.unitList[idx] = nil
				end
			end
			self.wndInternal:ArrangeChildrenVert(0, SortTableByDist)
		end
	else
		self:Announce(L['Showing new settler resources. (move around)'])
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
		if self.unitList then
			for idx, v in pairs(self.unitList) do
				local madeUnit = GameLib.GetUnitById(idx)
				local harvestable = madeUnit:GetHarvestRequiredTradeskillName()
				if harvestable == FARMING then
					v.wnd:Destroy()
					self.unitList[idx] = nil
				end
			end
			self.wndInternal:ArrangeChildrenVert(0, SortTableByDist)
		end
	else
		self:Announce(L['Showing new farming resources. (move around)'])
	end
end

function GatherBuddyImproved:GetHideFarming()
	return self.db.char.hideFarming
end

function GatherBuddyImproved:InitializeForm()
	if not self.wndCFG then
		return
	end
	
	self.wndCFG:FindChild("HideFarmingCheckbox"):SetCheck(self:GetHideFarming())
	self.wndCFG:FindChild("HideSettlerCheckbox"):SetCheck(self:GetHideSettler())
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

--function GatherBuddyImproved:dump(name, val)
--	if type(val) == 'table' then
--		self:debug(name)
--		for k,v in pairs(val) do
--			self:debug(k .. '|' .. v)
--		end
--		self:debug('-----' .. name .. '-----')
--	else
--		self:debug(name .. ': ' .. tostring(val))
--	end
--end

function GatherBuddyImproved:IsSettlerResource(unit)
	if unit:GetName() ~= nil and unit:GetType() == SETTLER and unit:GetUnitRaceId() == SETTLER_RACE_ID then
		return true
	end
	return false
end

function GatherBuddyImproved:Displayable(unit)
	local harvestable = unit:GetHarvestRequiredTradeskillName()
	if harvestable ~= nil and harvestable ~= false then
		self:debug('Farming?: ' .. tostring(FARMING))
		self:debug('Relics?: ' .. tostring(RELICHUNTER))
		if harvestable == FARMING then
			self:debug('Farming node found: ' .. tostring(self:GetHideFarming()))
		end
		if (self:CheckTradeSkill(harvestable)) or 
		(harvestable == FISHING) or
		(harvestable == FARMING and self:GetHideFarming() == false) then
			return true
		end
	elseif self:IsSettlerResource(unit) and self:GetHideSettler() == false then
		self:debug('Settler: ' .. unit:GetType())
		return true
	end
	return false
end

-- on timer
function GatherBuddyImproved:OnTimer()
	if self.unitList then
		for idx, v in pairs(self.unitList) do
			local madeUnit = GameLib.GetUnitById(idx)
			if madeUnit then
				v.dist = self:CalculateInfo(madeUnit, v.wnd)
			else v.wnd:Destroy()
				self.unitList[idx] = nil
			end
		end
		self.wndInternal:ArrangeChildrenVert(0, SortTableByDist)
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
	else
		newInner:SetBGColor(colorCodeTradeskill[FISHING])
	end
	return distToP
end

function GatherBuddyImproved:newUnitCreated(madeUnit)
    if self.unitList[madeUnit:GetId()] == nil then
        if GatherBuddyImproved:Displayable(madeUnit) then
            local newInner = Apollo.LoadForm(self.xmlDoc, "Inner", self.wndInternal, self)
            newInner:Show(true)
            local distToP = self:CalculateInfo(madeUnit, newInner)
            self.unitList[madeUnit:GetId()] = {wnd = newInner; dist = distToP;}
            newInner:SetData(self.unitList[madeUnit:GetId()])
            self.wndInternal:ArrangeChildrenVert(0, SortTableByDist)
        end
    end
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
