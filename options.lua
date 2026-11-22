--[[
    Panneau d'options (Options > AddOns > AutoQuests)
]]
local _, L = ...

L.settings = {}

--[[
    Registre des fonctionnalités : ajouter une entrée pour exposer un nouveau réglage.
    key      : clé dans AutoQuestsDB (et valeur par défaut dans L.defaults)
    type     : "checkbox" (défaut), "dropdown", "slider" ou "button"
    label    : clé de locale du libellé
    tooltip  : clé de locale de l'infobulle
    section  : clé de locale d'un titre de section affiché avant le réglage
    parent   : clé du réglage dont dépend celui-ci (grisé si la case parente est décochée)
    choices  : (dropdown) liste { valeur, clé de locale }
    min, max, step : (slider)
    onClick  : (button) action
    onChange : appelé quand la valeur change depuis le panneau
    available : (optionnel) fonction ; le réglage est ignoré si elle renvoie false
]]
local function RefreshGPS()
    if L.GPS then L.GPS.ApplySettings() end
end

local features = {
    {
        key = "enabled",
        label = "OPT_ENABLE",
        tooltip = "OPT_ENABLE_TIP",
        onChange = function() L.PrintStatus() end,
    },
    {
        key = "gps",
        label = "OPT_GPS",
        tooltip = "OPT_GPS_TIP",
        section = "OPT_GPS_SECTION",
        onChange = RefreshGPS,
    },
    {
        key = "gpsUnit",
        type = "dropdown",
        label = "OPT_GPS_UNIT",
        tooltip = "OPT_GPS_UNIT_TIP",
        parent = "gps",
        choices = {
            { "auto", "OPT_UNIT_AUTO" },
            { "m", "OPT_UNIT_M" },
            { "ft", "OPT_UNIT_FT" },
            { "yd", "OPT_UNIT_YD" },
        },
        onChange = RefreshGPS,
    },
    {
        key = "gpsLocked",
        label = "OPT_GPS_LOCK",
        tooltip = "OPT_GPS_LOCK_TIP",
        parent = "gps",
        onChange = RefreshGPS,
    },
    {
        key = "gpsScale",
        type = "slider",
        label = "OPT_GPS_SCALE",
        tooltip = "OPT_GPS_SCALE_TIP",
        parent = "gps",
        min = 0.5, max = 2, step = 0.1,
        onChange = RefreshGPS,
    },
    {
        key = "gpsHideNative",
        label = "OPT_GPS_HIDE_NATIVE",
        tooltip = "OPT_GPS_HIDE_NATIVE_TIP",
        parent = "gps",
        available = function() return L.GPS.NativeMarkerAvailable() end,
        onChange = RefreshGPS,
    },
    {
        key = "gpsReset",
        type = "button",
        label = "OPT_GPS_RESET",
        tooltip = "OPT_GPS_RESET_TIP",
        parent = "gps",
        onClick = function() L.GPS.ResetPosition() end,
    },
}

local VAR_TYPES = { checkbox = "Boolean", dropdown = "String", slider = "Number" }

local function CreateDropdownOptions(feature)
    return function()
        local container = Settings.CreateControlTextContainer()
        for _, choice in ipairs(feature.choices) do
            container:Add(choice[1], L[choice[2]])
        end
        return container:GetData()
    end
end

function L.InitOptions()
    if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnSetting) then
        return
    end

    local category = Settings.RegisterVerticalLayoutCategory("AutoQuests")
    L.category = category
    local initializers = {}

    -- Réglages non disponibles sur ce client (ex. CVar absent) : ignorés
    local active = {}
    for _, feature in ipairs(features) do
        if not feature.available or feature.available() then
            active[#active + 1] = feature
        end
    end

    for _, feature in ipairs(active) do
        local kind = feature.type or "checkbox"

        if feature.section and CreateSettingsListSectionHeaderInitializer then
            local layout = SettingsPanel:GetLayout(category)
            layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L[feature.section]))
        end

        local initializer
        if kind == "button" then
            if CreateSettingsButtonInitializer then
                initializer = CreateSettingsButtonInitializer(
                    L[feature.label], L[feature.label], feature.onClick, L[feature.tooltip], true)
                SettingsPanel:GetLayout(category):AddInitializer(initializer)
            end
        else
            local setting = Settings.RegisterAddOnSetting(
                category,
                "AUTOQUESTS_" .. string.upper(feature.key),
                feature.key,
                L.db,
                Settings.VarType[VAR_TYPES[kind]],
                L[feature.label],
                L.defaults[feature.key]
            )
            L.settings[feature.key] = setting

            if feature.onChange then
                setting:SetValueChangedCallback(function(_, value)
                    feature.onChange(value)
                end)
            end

            if kind == "dropdown" then
                initializer = Settings.CreateDropdown(category, setting, CreateDropdownOptions(feature), L[feature.tooltip])
            elseif kind == "slider" then
                local options = Settings.CreateSliderOptions(feature.min, feature.max, feature.step)
                if MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then
                    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
                end
                initializer = Settings.CreateSlider(category, setting, options, L[feature.tooltip])
            else
                initializer = Settings.CreateCheckbox(category, setting, L[feature.tooltip])
            end
        end

        initializers[feature.key] = initializer
        local parent = feature.parent and initializers[feature.parent]
        if initializer and parent and initializer.SetParentInitializer then
            initializer:SetParentInitializer(parent, function() return L.db[feature.parent] end)
        end
    end

    Settings.RegisterAddOnCategory(category)
end

function L.OpenOptions()
    if L.category then
        Settings.OpenToCategory(L.category:GetID())
    else
        L.printMessage(L.TITLE .. L.OPT_UNAVAILABLE)
    end
end
