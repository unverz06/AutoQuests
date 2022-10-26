local _, L = ...;

if GetLocale() == "frFR" then

  L.WELCOME = {
    TEXT_1 = "Salut ",
    TEXT_2 = ", AutoQuests est chargé.",
  }

  L.TITLE = "AutoQuests — "
  L.REWARD = ", Choisissez votre récompense et terminez votre quête."
  L.BACK = "\n"

  L.AutoQuestsBtn = {
    text = "Quetes Automatiques",
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