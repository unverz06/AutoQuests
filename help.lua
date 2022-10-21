-- Cmd "/"
SLASH_HELP1 = "/aq"

local color = "cffF08080";
local msg_help = "\124" .. color .. "AutoQuests — Commands\124r"
local cmd_help = "\124" .. color .. "Help : /aq\124r"
local cmd_aaq = "\124" .. color .. "Abandon all quests : /aq-aaq\124r"

-- Var
local function AutoQuestHelper()
  PlaySound(5274, "master")
  print(msg_help .. "\n" .. cmd_help .. "\n" .. cmd_aaq)
end

SlashCmdList['HELP'] =  AutoQuestHelper