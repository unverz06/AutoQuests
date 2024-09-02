--[[ 
    Importation de la table de localisation 
]]
local _, L = ...

local playerName = UnitName("player")
local defaultRewardIndex = 1

--[[ 
    Fonction d'affichage de message 
]]
local function printMessage(message)
    DEFAULT_CHAT_FRAME:AddMessage(message, 1.0, 1.0, 0.0)
end

--[[ 
    Fonction principale pour gérer les événements liés aux quêtes 
]]
local function AutoQuestsHandler(self, event, ...)
    if not L.status or IsShiftKeyDown() or IsControlKeyDown() or IsAltKeyDown() then
        return -- AutoQuests est désactivé ou une touche de modification est enfoncée
    end

    if event == "GOSSIP_SHOW" then
        HandleGossipShow()
    elseif event == "QUEST_GREETING" then
        HandleQuestGreeting()
    elseif event == "QUEST_DETAIL" then
        AcceptQuest()
    elseif event == "QUEST_PROGRESS" then
        CompleteQuest()
    elseif event == "QUEST_COMPLETE" then
        HandleQuestCompletion()
    end
end

--[[ 
    Fonction pour gérer l'événement GOSSIP_SHOW
]]
local function HandleGossipShow()
    local nActive = C_GossipInfo.GetNumActiveQuests()
    local activeQuests = C_GossipInfo.GetActiveQuests()
    local nAvailable = C_GossipInfo.GetNumAvailableQuests()
    local availableQuests = C_GossipInfo.GetAvailableQuests()
    local gossipOptions = C_GossipInfo.GetOptions()

    if #gossipOptions == 1 and gossipOptions[1].flags == 1 then
        C_GossipInfo.SelectOption(gossipOptions[1].gossipOptionID)
    else
        local questOptionsCount = 0
        for _, option in ipairs(gossipOptions) do
            if option.flags == 1 then
                questOptionsCount = questOptionsCount + 1
            end
        end
        if questOptionsCount > 1 then
            printMessage(L.TITLE .. playerName .. L.GOSSIP)
            PlaySound(5274, "master")
        elseif questOptionsCount == 1 then
            C_GossipInfo.SelectOption(gossipOptions[1].gossipOptionID)
        end
    end

    if nAvailable > 0 then
        for i, quest in ipairs(availableQuests) do
            if not quest.repeatable or nAvailable < 2 then
                C_GossipInfo.SelectAvailableQuest(quest.questID)
            end
        end
        if availableQuests[1].repeatable then
            printMessage(L.TITLE .. playerName .. L.REPEATABLE)
        end
    elseif nActive > 0 then
        for i, quest in ipairs(activeQuests) do
            if quest.isComplete then
                C_GossipInfo.SelectActiveQuest(quest.questID)
            end
        end
    end
end

--[[ 
    Fonction pour gérer l'événement QUEST_GREETING 
]]
local function HandleQuestGreeting()
    local availableQuestsCount = GetNumAvailableQuests()
    local activeQuestsCount = GetNumActiveQuests()

    if availableQuestsCount > 0 then
        for i = 1, availableQuestsCount do
            SelectAvailableQuest(i)
        end
    elseif activeQuestsCount > 0 then
        for i = 1, activeQuestsCount do
            SelectActiveQuest(i)
        end
    end
end

--[[ 
    Fonction pour gérer l'événement QUEST_COMPLETE 
]]
local function HandleQuestCompletion()
    local rewardCount = GetNumQuestChoices()
    if rewardCount > 1 then
        printMessage(L.TITLE .. playerName .. L.REWARD)
        PlaySound(5274, "master")
    else
        GetQuestReward(defaultRewardIndex)
    end
end

--[[ 
    Enregistrement des événements de quêtes 
]]
local function RegisterAutoQuestsEvents()
    L.status = true
    printMessage(L.TITLE .. L.ENABLE)

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("GOSSIP_SHOW")
    frame:RegisterEvent("QUEST_PROGRESS")
    frame:RegisterEvent("QUEST_DETAIL")
    frame:RegisterEvent("QUEST_COMPLETE")
    frame:RegisterEvent("QUEST_GREETING")
    frame:SetScript("OnEvent", AutoQuestsHandler)
end

--[[ 
    Commandes slash pour activer/désactiver l'addon 
]]
SLASH_AUTOQUEST1 = "/autoquest"
SLASH_AUTOQUEST2 = "/aq"

SlashCmdList["AUTOQUEST"] = function(msg)
    msg = string.lower(msg)
    local exec = msg:match("^(%S*)") -- Extraire la première partie de la commande

    if exec == "on" then
        L.status = true
        printMessage(L.TITLE .. L.ENABLE)
    elseif exec == "off" then
        L.status = false
        printMessage(L.TITLE .. L.DISABLE)
    else
        local statusMessage = L.status and L.ENABLE or L.DISABLE
        printMessage(L.TITLE .. L.STATE .. statusMessage)
    end
end

--[[ 
    Gestionnaire de l'événement de connexion du joueur 
]]
local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        RegisterAutoQuestsEvents()
    end
end)