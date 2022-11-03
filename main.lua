--[[
    Variable
]]

local _, L = ...;

local player = UnitName("player")
local default = 1;

--[[
    Messages
]]

local function selfMessage(v)
  DEFAULT_CHAT_FRAME:AddMessage(v, 1.0, 1.0, 0.0);
end

--[[
    AutoQuests
]]

local function RegisterAutoQuestsEvents()

  local function Autoquests(self, event, ...)

    if (event=="GOSSIP_SHOW") then
      
      -- activeQuetes
      local nActive = C_GossipInfo.GetNumActiveQuests()
      local activeQuests = C_GossipInfo.GetActiveQuests()
      
      -- availableQuests
      local nAvailable = C_GossipInfo.GetNumAvailableQuests()
      local availableQuests = C_GossipInfo.GetAvailableQuests()
      
      -- specificVar
      local autoquestsQuestID
      local autoquestsIsComplete

      if nAvailable > 0 then
        for i = 1, nAvailable do
          if type(availableQuests) == "table" then
            autoquestsQuestID = availableQuests[i].questID
            C_GossipInfo.SelectAvailableQuest(autoquestsQuestID)
          end
        end
      elseif nActive > 0 then
        for i = 1, nActive do
          if type(activeQuests) == "table" then
            autoquestsIsComplete = activeQuests[i].isComplete
            autoquestsQuestID = activeQuests[i].questID
            if autoquestsIsComplete == true then
              C_GossipInfo.SelectAvailableQuest(autoquestsQuestID)
            end
          end
        end
      end

    end
  
    if (event=="QUEST_GREETING") then
      local npcAvailableQuestCount = GetNumAvailableQuests()
      local npcActiveQuestCount = GetNumActiveQuests()
  
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
      AcceptQuest()
    end
  
    if (event=="QUEST_PROGRESS") then
      CompleteQuest()
    end
  
    if (event=="QUEST_COMPLETE") then
      local npcQuestRewardsCount = GetNumQuestChoices()
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

    -- Message thanks
    local MessageContent1 = ConfigurationPanel:CreateFontString(nil, "ARTWORK","GameFontNormal")
  MessageContent1:SetPoint("TOPLEFT", 10, -50)
    MessageContent1:SetText(L.OPTIONS.THANKS)
  
    -- Message ticket
    local MessageContent1 = ConfigurationPanel:CreateFontString(nil, "ARTWORK","GameFontNormal")
    MessageContent1:SetPoint("TOPLEFT", 10, -65)
      MessageContent1:SetText(L.OPTIONS.TICKET)

    -- Message support
    local MessageContent1 = ConfigurationPanel:CreateFontString(nil, "ARTWORK","GameFontNormal")
    MessageContent1:SetPoint("TOPLEFT", 10, -95)
      MessageContent1:SetText(L.OPTIONS.SUPPORT)

end

--[[
    Load 
]]

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event)
    if event == "ADDON_LOADED" then
        CreateConfigurationPanel()
    elseif event == "PLAYER_LOGIN" then
      RegisterAutoQuestsEvents()
    end
end)