--[[
    Variable
]]

local _, L = ...;

local player = UnitName("player")
local default = 1;

--[[
    Misc function
]]

local function selfMessage(v)
  DEFAULT_CHAT_FRAME:AddMessage(v, 1.0, 1.0, 0.0);
end

--[[
    AutoQuests
]]

local function RegisterAutoQuestsEvents()

  local function Autoquests(self, event, key, down, ...)

    if IsShiftKeyDown() or IsControlKeyDown() or IsAltKeyDown() then
      -- nothing ... deactivate Autoquests
    else
    
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
        local autoquestsRepeatable

        if nAvailable > 0 then
          for i = 1, nAvailable do
            if type(availableQuests) == "table" then
              autoquestsQuestID = availableQuests[i].questID
              autoquestsRepeatable = availableQuests[i].repeatable
              if nAvailable >= 2 and autoquestsRepeatable == true then
                -- nothing ... deactivate Autoquests
              else
                C_GossipInfo.SelectAvailableQuest(autoquestsQuestID)
              end
            end
          end
          if autoquestsRepeatable == true then
            selfMessage(L.TITLE .. player .. L.REPEATABLE);
          end
        elseif nActive > 0 then
          for i = 1, nActive do
            if type(activeQuests) == "table" then
              autoquestsIsComplete = activeQuests[i].isComplete
              autoquestsQuestID = activeQuests[i].questID
              if autoquestsIsComplete == true then
                C_GossipInfo.SelectActiveQuest(autoquestsQuestID)
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

  end

  local f = CreateFrame("Frame")
    f:RegisterEvent ("MODIFIER_STATE_CHANGED")
    f:RegisterEvent ("GOSSIP_SHOW")
    f:RegisterEvent ("QUEST_PROGRESS")
    f:RegisterEvent ("QUEST_DETAIL")
    f:RegisterEvent ("QUEST_COMPLETE")
    f:RegisterEvent ("QUEST_GREETING")
    f:SetScript("OnEvent", Autoquests)
end

--[[
    Load 
]]

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
      RegisterAutoQuestsEvents()
    end
end)