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
    C_GossipInfo.SelectAvailableQuest(npcGossipQuestAvailableCount)
    C_GossipInfo.SelectActiveQuest(npcGossipQuestCompleteCount)
	end
    --[[
    Start Event QUEST_*
  ]]
  if (event=="QUEST_GREETING") then
    local npcQuestCount = GetNumAvailableQuests()
    SelectAvailableQuest(npcQuestCount)
	end

  if (event=="QUEST_DETAIL") then
    AcceptQuest()
	end

  if (event=="QUEST_PROGRESS") then
    CompleteQuest()
	end

  if (event=="QUEST_COMPLETE") then
    GetQuestReward(1)
  end

  if (event=="QUEST_AUTOCOMPLETE") then
    message("quest auto complete are not available at the moment :(")
	end

end)



-- /run AcceptQuest() -- prend la quest
-- /run CompleteQuest() -- continue la quest 
-- /run GetQuestReward() -- fin de quest
-- /run CloseQuest() -- ferme ta quest

