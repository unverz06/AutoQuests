local _, L = ...;

if GetLocale() == "frFR" then

  L.WELCOME = {
    HI = "Hi ",
    LOADED = ", AutoQuests is loaded.",
  }
  
  L.TITLE = "AutoQuests — "
  L.REWARD = ", Choose your reward and complete your quest."
  L.BACK = "\n"
  
  L.OPTIONS = {
    THANKS = "Thanks to use Autoquests.",
    TICKET = "If you have bug, please create ticket in my github hors comment on curseforge",
    SUPPORT = "Use paypal donation for support this project"
  }
  
  L.DEBUG = {
    LOG = "AutoQuests Log: ",
    AVAILABLE = "Available Quests: ",
    PROGRESS = "Quests in progress: ",
    OPTION = "Available Options: ",
    REWARDCOUNT = "Reward count: ",
    ISDETAIL = "Is QUEST_DETAIL event",
    ISPROGRESS = "Is QUEST_PROGRESS event",
  }

end