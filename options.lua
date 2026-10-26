--[[
    Panneau d'options (Options > AddOns > AutoQuests)
]]
local _, L = ...

L.settings = {}

--[[
    Registre des fonctionnalités : ajouter une entrée pour exposer un nouveau réglage.
    key      : clé dans AutoQuestsDB (et valeur par défaut dans L.defaults)
    label    : clé de locale du libellé
    tooltip  : clé de locale de l'infobulle
    disabled : true tant que la fonctionnalité n'est pas disponible
    onChange : appelé quand la valeur change depuis le panneau
]]
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
        disabled = true,
        section = "OPT_SOON",
    },
}

function L.InitOptions()
    if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnSetting) then
        return
    end

    local category = Settings.RegisterVerticalLayoutCategory("AutoQuests")
    L.category = category

    for _, feature in ipairs(features) do
        if feature.section and CreateSettingsListSectionHeaderInitializer then
            local layout = SettingsPanel:GetLayout(category)
            layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L[feature.section]))
        end

        local setting = Settings.RegisterAddOnSetting(
            category,
            "AUTOQUESTS_" .. string.upper(feature.key),
            feature.key,
            L.db,
            Settings.VarType.Boolean,
            L[feature.label],
            L.defaults[feature.key]
        )
        L.settings[feature.key] = setting

        if feature.onChange then
            setting:SetValueChangedCallback(function(_, value)
                feature.onChange(value)
            end)
        end

        local initializer = Settings.CreateCheckbox(category, setting, L[feature.tooltip])
        if feature.disabled and initializer and initializer.AddModifyPredicate then
            initializer:AddModifyPredicate(function() return false end)
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
