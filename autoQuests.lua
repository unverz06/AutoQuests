-- Var
local player = UnitName("player")
local default = 1;
local color = "cffF08080";
local msg_aq_reward = "\124" .. color .. "AutoQuests — " .. player .. ", Choose your reward and complete your quest!\124r"


-- Event
AQ_EventFrame = CreateFrame("Frame")

AQ_EventFrame:RegisterEvent ("GOSSIP_SHOW")
AQ_EventFrame:RegisterEvent ("QUEST_PROGRESS")
AQ_EventFrame:RegisterEvent ("QUEST_DETAIL")
AQ_EventFrame:RegisterEvent ("QUEST_COMPLETE")
AQ_EventFrame:RegisterEvent ("QUEST_GREETING")

AQ_EventFrame:SetScript("OnEvent", function(self, event, ...)

  --[[
    Start Event GOSSIP_*
  ]]

  if (event=="GOSSIP_SHOW") then
    local npcGossipQuestAvailableCount = C_GossipInfo.GetNumAvailableQuests()
    local npcGossipQuestCompleteCount = C_GossipInfo.GetNumActiveQuests()

    -- print("AutoQuests Log — Available: " .. npcGossipQuestAvailableCount .. ". In progress: " .. npcGossipQuestCompleteCount ..".") -- DEBUG

    if (npcGossipQuestAvailableCount > 0) then
      for i = 1, C_GossipInfo.GetNumAvailableQuests() do
        C_GossipInfo.SelectAvailableQuest(i)
      end
    elseif (npcGossipQuestCompleteCount > 0) then
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

    -- print("AutoQuests Log — Available: " .. npcAvailableQuestCount .. ". In progress: " .. npcActiveQuestCount ..".") -- DEBUG

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

  if (event=="QUEST_FINISHED") then
    -- print("AutoQuests Log — Is QUEST_FINISHED event.") -- DEBUG
  end

  if (event=="QUEST_DETAIL") then
    -- print("AutoQuests Log — Is QUEST_DETAIL event.") -- DEBUG
    AcceptQuest()
  end

  if (event=="QUEST_PROGRESS") then
    -- print("AutoQuests Log — Is QUEST_PROGRESS event.") -- DEBUG
    CompleteQuest()
  end

  if (event=="QUEST_COMPLETE") then
    local npcQuestRewardsCount = GetNumQuestChoices()

    -- print("AutoQuests Log — Reward count: " .. npcQuestRewardsCount .. ".") -- DEBUG

    if (npcQuestRewardsCount > 1) then
      print(msg_aq_reward)
      PlaySound(5274, "master")
    else
      GetQuestReward(default)
    end
  end

end)

