-- Cmd "/"
SLASH_HELP1 = "/aq-help"

-- Var
local function AutoQuestHelper()
  PlaySound(5274, "master")
  print(" ")
  print("AutoQuests — Commands")
  print("- Help : /aq-help")
  print("- Abandon all quests : /aq-abandon")
  print(" ")
end

SlashCmdList['HELP'] =  AutoQuestHelper