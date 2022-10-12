-- Cmd "/"
SLASH_AQ2 = "/autoquest-help"

-- Var
local function AutoQuestHelper()
  PlaySound(5274, "master")
  print(" ")
  print("AutoQuest — Commands")
  print("- Help : /autoquest-help")
  print("- Abandon all quests : /autoquest-abandon")
  print(" ")
end

SlashCmdList['AQ'] =  AutoQuestHelper