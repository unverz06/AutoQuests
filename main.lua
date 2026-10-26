--[[
    Importation de la table de localisation
]]
local ADDON_NAME, L = ...

local playerName = UnitName("player")
local defaultRewardIndex = 1

local HandleGossipShow, HandleQuestGreeting, HandleQuestCompletion

--[[
    Réglages par défaut (fusionnés avec AutoQuestsDB au chargement)
]]
L.defaults = {
    enabled = true,
    gps = false,
}

--[[
    Fonction d'affichage de message
]]
local function printMessage(message)
    DEFAULT_CHAT_FRAME:AddMessage(message, 1.0, 1.0, 0.0)
end
L.printMessage = printMessage

--[[
    Initialisation de la base de données persistante
]]
local function InitDB()
    AutoQuestsDB = AutoQuestsDB or {}
    for key, value in pairs(L.defaults) do
        if AutoQuestsDB[key] == nil then
            AutoQuestsDB[key] = value
        end
    end
    L.db = AutoQuestsDB
end

--[[
    Active/désactive l'addon (panneau d'options synchronisé si présent)
]]
function L.SetEnabled(value)
    value = value and true or false
    local setting = L.settings and L.settings.enabled
    if setting then
        if setting:GetValue() ~= value then
            setting:SetValue(value) -- le callback du panneau affiche le message
            return
        end
    else
        L.db.enabled = value
    end
    L.PrintStatus()
end

function L.PrintStatus()
    printMessage(L.TITLE .. (L.db.enabled and L.ENABLE or L.DISABLE))
end

--[[
    Fonction principale pour gérer les événements liés aux quêtes
]]
local function AutoQuestsHandler(self, event, ...)
    if not L.db or not L.db.enabled or IsShiftKeyDown() or IsControlKeyDown() or IsAltKeyDown() then
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
function HandleGossipShow()
    local nActive = C_GossipInfo.GetNumActiveQuests()
    local activeQuests = C_GossipInfo.GetActiveQuests()
    local nAvailable = C_GossipInfo.GetNumAvailableQuests()
    local availableQuests = C_GossipInfo.GetAvailableQuests()
    local gossipOptions = C_GossipInfo.GetOptions()

    if #gossipOptions == 1 and gossipOptions[1].flags == 1 then
        C_GossipInfo.SelectOption(gossipOptions[1].gossipOptionID)
    else
        local questOptionsCount = 0
        local firstQuestOption = nil
        for _, option in ipairs(gossipOptions) do
            if option.flags == 1 then
                questOptionsCount = questOptionsCount + 1
                if firstQuestOption == nil then
                    firstQuestOption = option
                end
            end
        end
        if questOptionsCount > 1 then
            printMessage(L.TITLE .. playerName .. L.GOSSIP)
            PlaySound(5274, "master")
            if firstQuestOption then
                C_GossipInfo.SelectOption(firstQuestOption.gossipOptionID)
            end
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
        if availableQuests[1] then
            if availableQuests[1].repeatable and nAvailable > 1 then
                C_GossipInfo.SelectAvailableQuest(availableQuests[1].questID)
            end
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
function HandleQuestGreeting()
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
function HandleQuestCompletion()
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
    L.PrintStatus()

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
        L.SetEnabled(true)
    elseif exec == "off" then
        L.SetEnabled(false)
    elseif exec == "config" or exec == "options" then
        L.OpenOptions()
    else
        local statusMessage = L.db.enabled and L.ENABLE or L.DISABLE
        printMessage(L.TITLE .. L.STATE .. statusMessage)
    end
end

--[[
    Gestionnaire des événements de chargement de l'addon et de connexion du joueur
]]
local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("ADDON_LOADED")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == ADDON_NAME then
        InitDB()
        L.InitOptions()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        RegisterAutoQuestsEvents()
    end
end)
