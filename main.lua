--[[
    Variable
]]

local _, L = ...;

local CHARACTER_DEFAULTS = {
    AutoQuests = true,
    -- AbandonAllQuests = false,
}
local player = UnitName("player")
local default = 1;

--[[
    Messages
]]

local function selfMessage(v)
  DEFAULT_CHAT_FRAME:AddMessage(v, 0.19, 0.55, 1.0);
end

local function debugMessage(v)
  DEFAULT_CHAT_FRAME:AddMessage(v, 	1.0, 1.0, 0.0);
end

--[[
    Settings
]]

local function LoadSettings()
    
  if autoquests_settings == nil then
      autoquests_settings = {}
  end

  local function CopyDefaults(src, dst)
      if type(src) ~= "table" then
          return {}
      end
      if type(dst) ~= "table" then
          dst = {}
      end

      for k, v in pairs(src) do
          if type(v) == "table" then
              dst[k] = CopyDefaults(v, dst[k])
          elseif type(v) ~= type(dst[k]) then
              dst[k] = v
          end
      end

      return dst
  end

  CopyDefaults(CHARACTER_DEFAULTS, autoquests_settings)
end

--[[
    AutoQuests & AbandonAllQuests
]]

local function RegisterAutoQuestsEvents()

  local function Autoquests(self, event, ...)

    if (event=="GOSSIP_SHOW") then
      local npcGossipQuestAvailableCount = C_GossipInfo.GetNumAvailableQuests()
      local npcGossipQuestCompleteCount = C_GossipInfo.GetNumActiveQuests()
      local npcGossipOptionsNumbers = #C_GossipInfo.GetOptions() -- Shadowlands and more
      local npcGossipOptionsNumbersClassic = C_GossipInfo.GetNumOptions() -- Retro compatibility (Classic)
  
      -- debugMessage(L.DEBUG.LOG .. L.BACK .. L.DEBUG.AVAILABLE .. npcGossipQuestAvailableCount .. L.BACK .. L.DEBUG.PROGRESS .. npcGossipQuestCompleteCount .. L.BACK .. L.DEBUG.OPTION .. npcGossipOptionsNumbers .. L.BACK .. L.DEBUG.OPTIONC .. npcGossipOptionsNumbersClassic); -- DEBUG
  
      if (npcGossipOptionsNumbers > 0 or npcGossipOptionsNumbersClassic > 0) then 

        -- if Gossip have choice (banker, battlemaster, binder, gossip, healer, petition, tabard, taxi, trainer, unlearn, or vendor)

      elseif (npcGossipQuestAvailableCount > 0) then
        for i = 1, C_GossipInfo.GetNumAvailableQuests() do
          C_GossipInfo.SelectAvailableQuest(i)
        end
      elseif (npcGossipQuestCompleteCount > 0) then
        for i = 1, C_GossipInfo.GetNumActiveQuests() do
          C_GossipInfo.SelectActiveQuest(i)
        end
      end
    end
  
    if (event=="QUEST_GREETING") then
      local npcAvailableQuestCount = GetNumAvailableQuests()
      local npcActiveQuestCount = GetNumActiveQuests()
  
      -- debugMessage(L.DEBUG.LOG .. L.BACK .. L.DEBUG.AVAILABLE .. npcAvailableQuestCount .. L.BACK .. L.DEBUG.PROGRESS .. npcActiveQuestCount); -- DEBUG
  
      if (npcAvailableQuestCount > 0) then
        for i = 1, GetNumAvailableQuests() do
          SelectAvailableQuest(i)
        end
      elseif (npcActiveQuestCount > 0) then
        for i = 1, GetNumActiveQuests() do
          SelectActiveQuest(i)
        end
      end
    end
  
    if (event=="QUEST_DETAIL") then
    
      -- debugMessage(L.DEBUG.LOG .. L.BACK .. L.DEBUG.ISDETAIL); -- DEBUG
      AcceptQuest()

    end
  
    if (event=="QUEST_PROGRESS") then

      -- debugMessage(L.DEBUG.LOG .. L.BACK .. L.DEBUG.ISPROGRESS); -- DEBUG

      CompleteQuest()
    end
  
    if (event=="QUEST_COMPLETE") then
      local npcQuestRewardsCount = GetNumQuestChoices()
  
      -- debugMessage(L.DEBUG.LOG .. L.BACK .. L.DEBUG.REWARDCOUNT .. npcQuestRewardsCount); -- DEBUG
  
      if (npcQuestRewardsCount > 1) then
        selfMessage(L.TITLE .. player .. L.REWARD);
        PlaySound(5274, "master")
      else
        GetQuestReward(default)
      end
    end
  end

  local f = CreateFrame("Frame")
    f:RegisterEvent ("GOSSIP_SHOW")
    f:RegisterEvent ("QUEST_PROGRESS")
    f:RegisterEvent ("QUEST_DETAIL")
    f:RegisterEvent ("QUEST_COMPLETE")
    f:RegisterEvent ("QUEST_GREETING")
    f:SetScript("OnEvent", Autoquests)
end

--[[
    Options panel
]]

local configurationPanelCreated = false

function CreateConfigurationPanel()
    if configurationPanelCreated then
        return nil
    end
    configurationPanelCreated = true

    local pre = _ .. "Config_"

    local ConfigurationPanel = CreateFrame("Frame", pre .. "MainFrame");
	ConfigurationPanel.name = _
    InterfaceOptions_AddCategory(ConfigurationPanel)

    -- Title
    local IntroMessageHeader = ConfigurationPanel:CreateFontString(nil, "ARTWORK","GameFontNormalLarge")
	IntroMessageHeader:SetPoint("TOPLEFT", 10, -10)
    IntroMessageHeader:SetText(_ .. " " .. GetAddOnMetadata(_, "Version"))
    
    -- AutoQuests
    local AutoQuestsBtn = CreateFrame("CheckButton", pre .. "AutoQuestsBtn", ConfigurationPanel, "ChatConfigCheckButtonTemplate")
    AutoQuestsBtn:SetPoint("TOPLEFT", 10, -40)
    getglobal(AutoQuestsBtn:GetName().."Text"):SetText(L.AutoQuestsBtn.text)
    
    -- save
    ConfigurationPanel.okay = function(self)
        autoquests_settings.AutoQuests = AutoQuestsBtn:GetChecked()
    end

    -- cancel
    ConfigurationPanel.cancel = function(self)
        AutoQuestsBtn:SetChecked(autoquests_settings.AutoQuests)
    end

    -- init
    ConfigurationPanel.cancel()
end

--[[
    Load 
]]

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event)
    if event == "ADDON_LOADED" then
        LoadSettings()
        CreateConfigurationPanel()
    elseif event == "PLAYER_LOGIN" then
      RegisterAutoQuestsEvents()
      selfMessage(L.WELCOME.TEXT_1 .. player .. L.WELCOME.TEXT_2);
    end
end)