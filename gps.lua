--[[
    GPS de quête : flèche + distance vers l'objectif de la quête suivie (super-track Blizzard)

    Repère monde : UnitPosition("player") renvoie (nord, ouest, z, instanceID) et le vecteur de
    C_Map.GetWorldPosFromMapPos est exprimé dans le même repère. Le cap est mesuré dans le
    sens antihoraire depuis le nord, comme GetPlayerFacing().
]]
local _, L = ...

local GPS = {}
L.GPS = GPS

local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local TWO_PI = 2 * math.pi
local YARDS_TO_METERS = 0.9144
local YARDS_TO_FEET = 3
local IMPERIAL_LOCALES = { enUS = true, enGB = true }
local TARGET_REFRESH_SECONDS = 1
local ARROW_TEXTURE = "Interface\\AddOns\\AutoQuests\\Icons\\GPSArrow.tga"
local CHECK_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-Ready"
local NO_INFO = "—"
local FRAME_WIDTH = 280
local TITLE_WIDTH = 216
local ARROW_SIZE = 30 -- la texture a des marges transparentes : ~23 px visibles
local CHECK_SIZE = 22 -- visuellement équilibrée avec la flèche
local ARRIVAL_DISTANCE = 10 -- dans l'unité choisie (m, ft ou yd)
local ARRIVAL_EXIT_FACTOR = 1.2 -- hystérésis pour éviter le clignotement en bordure
local ARRIVAL_HIDE_DELAY = 5
local DEMO_DURATION = 13
local FRAME_FADE_SECONDS = 0.5
local CHECK_FADE_SECONDS = 0.3
local ARROW_SMOOTHING = 20

--[[
    Fonctions pures (sans dépendance à l'interface du jeu)
]]
function GPS.ResolveUnit(unit, locale)
    if unit == "m" or unit == "ft" or unit == "yd" then
        return unit
    end
    return IMPERIAL_LOCALES[locale] and "yd" or "m"
end

function GPS.FormatDistance(yards, unit)
    if unit == "ft" then
        local feet = yards * YARDS_TO_FEET
        if feet >= 5280 then
            return string.format("%.1f mi", feet / 5280)
        end
        return string.format("%d ft", math.floor(feet + 0.5))
    elseif unit == "yd" then
        if yards >= 1760 then
            return string.format("%.1f mi", yards / 1760)
        end
        return string.format("%d yd", math.floor(yards + 0.5))
    end
    local meters = yards * YARDS_TO_METERS
    if meters >= 1000 then
        return string.format("%.1f km", meters / 1000)
    end
    return string.format("%d m", math.floor(meters + 0.5))
end

-- Cap (radians, sens antihoraire depuis le nord) et distance (yards) du joueur vers la cible
function GPS.Bearing(playerA, playerB, targetA, targetB)
    local deltaA, deltaB = targetA - playerA, targetB - playerB
    return atan2(deltaB, deltaA) % TWO_PI, math.sqrt(deltaA * deltaA + deltaB * deltaB)
end

-- Rotation à appliquer à une flèche pointant vers le haut (SetRotation est antihoraire)
function GPS.ArrowRotation(bearing, facing)
    return (bearing - facing) % TWO_PI
end

-- Distance (yards) sous laquelle l'objectif est considéré atteint : 5 dans l'unité choisie
function GPS.ArrivalThreshold(unit)
    if unit == "ft" then
        return ARRIVAL_DISTANCE / YARDS_TO_FEET
    elseif unit == "yd" then
        return ARRIVAL_DISTANCE
    end
    return ARRIVAL_DISTANCE / YARDS_TO_METERS
end

-- Rapproche un angle de sa cible par le chemin le plus court (lissage exponentiel)
function GPS.SmoothAngle(current, goal, delta, speed)
    local diff = ((goal - current + math.pi) % TWO_PI) - math.pi
    return (current + diff * math.min(1, delta * speed)) % TWO_PI
end

-- Distance (yards) simulée par /aq gps test : approche, arrivée, attente, éloignement
function GPS.DemoDistance(t)
    if t < 3 then
        return 30 * (1 - t / 3)
    elseif t < 9 then
        return 0
    end
    return math.min(30, (t - 9) * 10)
end

local function Approach(current, goal, step)
    if current < goal then
        return math.min(goal, current + step)
    end
    return math.max(goal, current - step)
end

local function usable(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if value == nil or (issecretvalue and issecretvalue(value)) then
            return false
        end
    end
    return true
end

--[[
    Objectif de la quête suivie, converti en coordonnées monde (nil si aucune information)
]]
-- Position (mapID, x, y normalisés) de l'objectif d'une quête, avec plusieurs sources de repli
local function GetWaypoint(questID)
    local mapID, x, y = C_QuestLog.GetNextWaypoint(questID)
    if usable(mapID, x, y) then
        return mapID, x, y, "waypoint"
    end

    local playerMap = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not usable(playerMap) then
        return nil
    end

    if C_QuestLog.GetNextWaypointForMap then
        x, y = C_QuestLog.GetNextWaypointForMap(questID, playerMap)
        if usable(x, y) then
            return playerMap, x, y, "waypointForMap"
        end
    end

    if C_QuestLog.GetQuestsOnMap then
        for _, poi in ipairs(C_QuestLog.GetQuestsOnMap(playerMap) or {}) do
            if usable(poi.questID, poi.x, poi.y) and poi.questID == questID then
                return playerMap, poi.x, poi.y, "questPOI"
            end
        end
    end
    return nil
end

function GPS.GetTarget()
    if not (C_SuperTrack and C_QuestLog and C_QuestLog.GetNextWaypoint and C_Map and C_Map.GetWorldPosFromMapPos) then
        return nil
    end
    if C_SuperTrack.IsSuperTrackingQuest and not C_SuperTrack.IsSuperTrackingQuest() then
        return nil
    end

    local questID = C_SuperTrack.GetSuperTrackedQuestID()
    if not usable(questID) or questID == 0 then
        return nil
    end

    local mapID, x, y = GetWaypoint(questID)
    if not mapID then
        return nil
    end

    local instance, position = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x, y))
    if not usable(instance, position) then
        return nil
    end

    local a, b = position:GetXY()
    if not usable(a, b) then
        return nil
    end
    local title = C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)
    return { questID = questID, instance = instance, a = a, b = b, title = usable(title) and title or nil }
end

--[[
    Diagnostic : /aq gps debug affiche chaque étape du calcul
]]
local function show(...)
    local parts = {}
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        parts[i] = (issecretvalue and issecretvalue(value)) and "<secret>" or tostring(value)
    end
    return table.concat(parts, ", ")
end

function GPS.Debug()
    local function out(text) L.printMessage("|cff03befc[GPS]|r " .. text) end

    out("db.gps=" .. show(L.db.gps) .. " locked=" .. show(L.db.gpsLocked) .. " unit=" .. show(L.db.gpsUnit))
    out("API: SuperTrack=" .. show(C_SuperTrack ~= nil) .. " NextWaypoint=" .. show(C_QuestLog and C_QuestLog.GetNextWaypoint ~= nil)
        .. " WorldPos=" .. show(C_Map and C_Map.GetWorldPosFromMapPos ~= nil))
    if not (C_SuperTrack and C_QuestLog and C_Map) then
        return
    end

    out("IsSuperTrackingQuest=" .. show(C_SuperTrack.IsSuperTrackingQuest and C_SuperTrack.IsSuperTrackingQuest()))
    local questID = C_SuperTrack.GetSuperTrackedQuestID()
    out("questID=" .. show(questID))
    out("UnitPosition=" .. show(UnitPosition("player")))
    out("playerMap=" .. show(C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")) .. " facing=" .. show(GetPlayerFacing()))

    if usable(questID) and questID ~= 0 then
        out("GetNextWaypoint=" .. show(C_QuestLog.GetNextWaypoint(questID)))
        local mapID, x, y, source = GetWaypoint(questID)
        out("waypoint(" .. show(source) .. ")=" .. show(mapID, x, y))
        if usable(mapID, x, y) then
            local instance, position = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x, y))
            out("GetWorldPosFromMapPos instance=" .. show(instance) .. " pos=" .. (position and show(position:GetXY()) or "nil"))
        end
    end

    if C_Navigation then
        out("C_Navigation state=" .. show(C_Navigation.GetTargetState and C_Navigation.GetTargetState())
            .. " distance=" .. show(C_Navigation.GetDistance and C_Navigation.GetDistance()))
    end
    local current = GPS.GetTarget()
    out("target=" .. show(current and current.instance, current and current.a, current and current.b))
end

--[[
    Interface
]]
local frame, arrow, check, distanceText, titleText, driver
local target
local targetTimer = 0

-- État d'animation
local arrived = false
local arrivedTime = 0
local frameAlpha = 1
local checkAlpha = 0
local arrowAngle
local demoTime
local function ResetState()
    arrived, arrivedTime, arrowAngle, demoTime = false, 0, nil, nil
    frameAlpha, checkAlpha = 1, 0
    if frame then
        frame:SetAlpha(1)
        check:SetAlpha(0)
    end
end

local function SetDistanceText(text)
    if distanceText:GetText() ~= text then
        distanceText:SetText(text)
    end
end

local function Render(delta)
    local db = L.db
    local hasInfo = false
    local bearing, yards
    local locked = db.gpsLocked or demoTime ~= nil -- la démo teste aussi le fondu de sortie

    if demoTime then
        demoTime = demoTime + delta
        if demoTime > DEMO_DURATION then
            demoTime = nil
        end
    end

    if demoTime then
        hasInfo, bearing, yards = true, demoTime, GPS.DemoDistance(demoTime)
    elseif target then
        local playerA, playerB, _, instance = UnitPosition("player")
        if usable(playerA, playerB, instance) and instance == target.instance then
            hasInfo = true
            bearing, yards = GPS.Bearing(playerA, playerB, target.a, target.b)
        end
    end

    -- Arrivée : sous le seuil on affiche la coche, au-delà (avec hystérésis) on réaffiche le GPS
    if hasInfo then
        local threshold = GPS.ArrivalThreshold(GPS.ResolveUnit(db.gpsUnit, GetLocale()))
        if arrived then
            if yards > threshold * ARRIVAL_EXIT_FACTOR then
                arrived = false
            end
        elseif yards < threshold then
            arrived, arrivedTime = true, 0
        end
    elseif not (arrived and locked) then
        -- Si le jeu retire l'objectif à l'arrivée, on laisse le fondu de sortie se terminer
        arrived = false
    end
    if arrived then
        arrivedTime = arrivedTime + delta
    end

    if hasInfo then
        local unit = GPS.ResolveUnit(db.gpsUnit, GetLocale())
        SetDistanceText(GPS.FormatDistance(yards, unit))

        local facing = demoTime and 0 or GetPlayerFacing()
        if usable(facing) and not arrived then
            local rotation = GPS.ArrowRotation(bearing, facing)
            arrowAngle = arrowAngle and GPS.SmoothAngle(arrowAngle, rotation, delta, ARROW_SMOOTHING) or rotation
            arrow:SetRotation(arrowAngle)
            arrow:Show()
        else
            arrowAngle = nil
            arrow:Hide()
        end
    else
        arrowAngle = nil
        arrow:Hide()
        if not arrived then
            SetDistanceText(NO_INFO)
        end
    end
    if demoTime then
        titleText:SetText(L.GPS_DEMO_TITLE)
    elseif target or not arrived then
        titleText:SetText(target and target.title or "")
    end

    -- Fondus : coche à l'arrivée, puis le cadre disparaît après quelques secondes (position verrouillée)
    local frameGoal = (locked and arrived and arrivedTime >= ARRIVAL_HIDE_DELAY) and 0 or 1
    frameAlpha = Approach(frameAlpha, frameGoal, delta / FRAME_FADE_SECONDS)
    checkAlpha = Approach(checkAlpha, arrived and 1 or 0, delta / CHECK_FADE_SECONDS)
    frame:SetAlpha(frameAlpha)
    check:SetAlpha(checkAlpha)

    -- Verrouillé : le cadre n'apparaît que s'il y a une information à donner
    if hasInfo or not locked or (arrived and frameAlpha > 0) then
        frame:Show()
    else
        frame:Hide()
    end
end

local function RefreshTarget()
    if not (frame and L.db.gps) then
        return
    end
    target = GPS.GetTarget()
    Render(0)
end

local function ApplyPosition()
    local pos = L.db.gpsPos
    frame:ClearAllPoints()
    if pos then
        frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        frame:SetPoint("TOP", UIParent, "TOP", 0, -160)
    end
end

local function CreateFrames()
    frame = CreateFrame("Frame", "AutoQuestsGPSFrame", UIParent)
    frame:SetSize(FRAME_WIDTH, 56)
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:Hide()

    frame.background = frame:CreateTexture(nil, "BACKGROUND")
    frame.background:SetAllPoints()
    frame.background:SetColorTexture(0, 0, 0, 0.45)

    arrow = frame:CreateTexture(nil, "ARTWORK")
    arrow:SetSize(ARROW_SIZE, ARROW_SIZE)
    arrow:SetPoint("LEFT", 12, 0)
    arrow:SetTexture(ARROW_TEXTURE)

    check = frame:CreateTexture(nil, "OVERLAY")
    check:SetSize(CHECK_SIZE, CHECK_SIZE)
    check:SetPoint("CENTER", arrow, "CENTER")
    check:SetTexture(CHECK_TEXTURE)
    check:SetAlpha(0)

    distanceText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    distanceText:SetPoint("TOPLEFT", frame, "TOPLEFT", 12 + ARROW_SIZE + 10, -14)
    distanceText:SetJustifyH("LEFT")

    titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    titleText:SetPoint("TOPLEFT", distanceText, "BOTTOMLEFT", 0, -2)
    titleText:SetWidth(TITLE_WIDTH)
    titleText:SetJustifyH("LEFT")
    titleText:SetWordWrap(false)

    frame:SetScript("OnDragStart", function(self)
        if not L.db.gpsLocked then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        L.db.gpsPos = { point, relativePoint, x, y }
    end)

    driver = CreateFrame("Frame")
    driver:Hide()
    driver:SetScript("OnUpdate", function(_, delta)
        targetTimer = targetTimer + delta
        if targetTimer >= TARGET_REFRESH_SECONDS then
            targetTimer = 0
            target = GPS.GetTarget()
        end
        Render(delta) -- à chaque image pour une flèche fluide
    end)

    for _, event in ipairs({
        "SUPER_TRACKING_CHANGED", "QUEST_LOG_UPDATE", "QUEST_POI_UPDATE",
        "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD",
    }) do
        pcall(driver.RegisterEvent, driver, event) -- événement absent sur certains clients
    end
    driver:SetScript("OnEvent", RefreshTarget)
end

--[[
    Marqueur de navigation natif du jeu (CVar showInGameNavigation) : désactivé tant que le GPS
    est actif et que l'option est cochée. La valeur d'origine est sauvegardée puis restaurée.
]]
local NATIVE_CVAR = "showInGameNavigation"

function GPS.NativeMarkerAvailable()
    return C_CVar ~= nil and C_CVar.GetCVar ~= nil and C_CVar.SetCVar ~= nil and C_CVar.GetCVar(NATIVE_CVAR) ~= nil
end

local function ApplyNativeMarker()
    if not GPS.NativeMarkerAvailable() then
        return
    end
    local db = L.db
    if db.gps and db.gpsHideNative then
        if db.nativeMarkerBackup == nil then
            db.nativeMarkerBackup = C_CVar.GetCVar(NATIVE_CVAR)
        end
        if C_CVar.GetCVar(NATIVE_CVAR) ~= "0" then
            C_CVar.SetCVar(NATIVE_CVAR, "0")
        end
    elseif db.nativeMarkerBackup ~= nil then
        C_CVar.SetCVar(NATIVE_CVAR, db.nativeMarkerBackup)
        db.nativeMarkerBackup = nil
    end
end

--[[
    Applique les réglages (activation, verrouillage, échelle, position)
]]
function GPS.ApplySettings()
    if not frame then
        return
    end
    local db = L.db

    frame:SetScale(db.gpsScale or 1)
    frame:EnableMouse(not db.gpsLocked)
    frame.background:SetShown(not db.gpsLocked)
    ApplyPosition()
    ApplyNativeMarker()

    if db.gps then
        driver:Show()
        RefreshTarget()
    else
        driver:Hide()
        target = nil
        ResetState()
        frame:Hide()
    end
end

function GPS.ResetPosition()
    L.db.gpsPos = nil
    if frame then
        ApplyPosition()
    end
end

function GPS.StartDemo()
    if not L.db.gps then
        L.printMessage(L.TITLE .. L.GPS_NEEDS_ON)
        return
    end
    ResetState()
    demoTime = 0
end

function GPS.Init()
    CreateFrames()
    GPS.ApplySettings()
end

--[[
    Commande /aq gps [on|off|lock|unlock|reset]
]]
local function SetOption(key, value)
    local setting = L.settings and L.settings[key]
    if setting then
        setting:SetValue(value) -- le callback du panneau applique les réglages
    else
        L.db[key] = value
        GPS.ApplySettings()
    end
end

function GPS.SlashCommand(arg)
    if arg == "debug" then
        GPS.Debug()
        return
    elseif arg == "test" then
        GPS.StartDemo()
        return
    end
    if arg == "" then
        arg = L.db.gps and "off" or "on"
    end

    if arg == "on" or arg == "off" then
        SetOption("gps", arg == "on")
        L.printMessage(L.TITLE .. (arg == "on" and L.GPS_ON or L.GPS_OFF))
    elseif arg == "lock" or arg == "unlock" then
        SetOption("gpsLocked", arg == "lock")
        L.printMessage(L.TITLE .. (arg == "lock" and L.GPS_LOCKED or L.GPS_UNLOCKED))
    elseif arg == "reset" then
        GPS.ResetPosition()
        L.printMessage(L.TITLE .. L.GPS_RESET)
    else
        L.printMessage(L.TITLE .. L.GPS_HELP)
    end
end
