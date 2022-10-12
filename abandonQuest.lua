-- Cmd "/"
SLASH_AQ1 = "/autoquest-abandon"

-- Var
local msg_aq_abandon = "AutoQuest — All Quests have been abandoned"

-- Function
local function getMaxQuests()
  return select(1, C_QuestLog.GetNumQuestLogEntries())
end

local function AbandonAllQuestsHandler()
  for i = 0,getMaxQuests(),1 do 
  local id = C_QuestLog.GetQuestIDForLogIndex(i)
    if(id > 0 )then
      if(C_QuestLog.CanAbandonQuest(id)) then
        C_QuestLog.SetSelectedQuest(id)
        C_QuestLog.SetAbandonQuest()
        C_QuestLog.AbandonQuest()
      end
    end
  end
  print(msg_aq_abandon)
end

SlashCmdList['AQ'] =  AbandonAllQuestsHandler