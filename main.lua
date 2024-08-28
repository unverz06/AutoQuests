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
  L.status = true
  selfMessage(L.TITLE .. L.ENABLE)
  local function Autoquests(self, event, key, down, ...)

    if L.status == false or IsShiftKeyDown() or IsControlKeyDown() or IsAltKeyDown() then
      -- Nothing ... Disabled Autoquests
    else
    
      if (event=="GOSSIP_SHOW") then

        -- GetactiveQuetes
        local nActive = C_GossipInfo.GetNumActiveQuests()
        local activeQuests = C_GossipInfo.GetActiveQuests()
        -- GetavailableQuests
        local nAvailable = C_GossipInfo.GetNumAvailableQuests()
        local availableQuests = C_GossipInfo.GetAvailableQuests()
        -- GetOptions
        local nOptions = #C_GossipInfo.GetOptions()
        local options = C_GossipInfo.GetOptions()
        -- specificVar
        local autoquestsQuestID = 0
        local autoquestsIsComplete = 0
        local autoquestsRepeatable = false
        local autoquestsOptions = 0

        --[[ Gossip event with the flag "💬(quest)" ]]
        if nOptions == 1 then
          -- local options = C_GossipInfo.GetOptions()
          if options[1].flags == 1 then -- If it's a conversation with a quest (always choose the first one)
            C_GossipInfo.SelectOption(options[1].gossipOptionID)
          else
            -- Nothing ... just reading the conversation
          end
        end
        if nOptions > 1 then
          for i = 1, nOptions do
            if options[i].flags == 1 then -- If it's a conversation with a quest (always choose the first one)
              autoquestsOptions = autoquestsOptions + 1;
            end
          end
          if autoquestsOptions > 1 then
            selfMessage(L.TITLE .. player .. L.GOSSIP);
            PlaySound(5274, "master")
          else
            -- Nothing ... just reading the conversation
          end
        end

        --[[ Gossip event with real quest "?!" ]]
        if nAvailable > 0 then
          for i = 1, nAvailable do
            if type(availableQuests) == "table" then
              autoquestsQuestID = availableQuests[i].questID
              autoquestsRepeatable = availableQuests[i].repeatable
              if nAvailable >= 2 and autoquestsRepeatable == true then
                -- Nothing ... 
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

SLASH_AUTOQUEST1 = "/autoquest";
SLASH_AUTOQUEST2 = "/aq";

SlashCmdList["AUTOQUEST"] = function(msg)
  msg = string.lower(msg)
  --	selfMessage(L.TITLE .. msg)
	msg = { string.split(" ", msg) }
	local exec
	if #msg >= 1 then
	  exec = table.remove(msg, 1)
	end
	if exec == "on" then
		L.status = true
		selfMessage(L.TITLE .. L.ENABLE)
	elseif exec == "off" then
		L.status = false
		selfMessage(L.TITLE .. L.DISABLE)
	else
    if L.status == true then
      L.statusReturn = L.ENABLE
    else
      L.statusReturn = L.DISABLE
    end
		selfMessage(L.TITLE .. L.STATE .. L.statusReturn)
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
      RegisterAutoQuestsEvents()
    end
end)