local default = 0;

AQ_EventFrame = CreateFrame("Frame")

AQ_EventFrame:RegisterEvent ("GOSSIP_SHOW")
AQ_EventFrame:RegisterEvent ("QUEST_PROGRESS")
AQ_EventFrame:RegisterEvent ("QUEST_DETAIL")
AQ_EventFrame:RegisterEvent ("QUEST_COMPLETE")
AQ_EventFrame:RegisterEvent ("QUEST_FINISHED")
AQ_EventFrame:RegisterEvent ("QUEST_GREETING")
AQ_EventFrame:RegisterEvent ("ITEM_PUSH")
AQ_EventFrame:RegisterEvent ("QUEST_AUTOCOMPLETE")

AQ_EventFrame:SetScript("OnEvent", function(self, event, ...)
  --[[
    Start Event GOSSIP_*
  ]]
  if (event=="GOSSIP_SHOW") then
    local npcGossipQuestAvailableCount = C_GossipInfo.GetNumAvailableQuests()
    local npcGossipQuestCompleteCount = C_GossipInfo.GetNumActiveQuests()

    -- message("Available:" .. npcGossipQuestAvailableCount .. ". Complete: " .. npcGossipQuestCompleteCount ..".") -- DEBUG

    if (npcGossipQuestAvailableCount > 0) then
      for i = 1, C_GossipInfo.GetNumAvailableQuests() do
        C_GossipInfo.SelectAvailableQuest(i)
      end
    end
    if (npcGossipQuestCompleteCount > 0) then
      for i = 1, C_GossipInfo.GetNumActiveQuests() do
        C_GossipInfo.SelectActiveQuest(i)
      end
    end
	end
    --[[
    Start Event QUEST_*
  ]]
  if (event=="QUEST_GREETING") then
    local npcAvailableQuestCount = GetNumAvailableQuests()
    local npcActiveQuestCount = GetNumActiveQuests()

    -- message("Available:" .. npcAvailableQuestCount .. ". Active: " .. npcActiveQuestCount ..".") -- DEBUG

    if (npcAvailableQuestCount > 0) then
      for i = 1, GetNumAvailableQuests() do
        SelectAvailableQuest(i)
      end
    end
    if (npcActiveQuestCount > 0) then
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
    local npcQuestRewardsCount = GetNumQuestRewards()

    -- message("Reward count:" .. npcQuestRewardsCount .. ".") -- DEBUG

    if (npcQuestRewardsCount > 0) then
      for i = 1, GetNumQuestRewards() do
        GetQuestReward(i)
      end
    end
    GetQuestReward(default)
  end

  if (event=="QUEST_AUTOCOMPLETE") then
    message("quest auto complete are not available at the moment :(")
	end

end)