AQ_EventFrame = CreateFrame("Frame")

AQ_EventFrame:RegisterEvent ("GOSSIP_SHOW")
-- AQ_EventFrame:RegisterEvent ("GOSSIP_CLOSED")
-- AQ_EventFrame:RegisterEvent ("QUEST_REMOVED")
-- AQ_EventFrame:RegisterEvent ("QUEST_ACCEPTED")
AQ_EventFrame:RegisterEvent ("QUEST_PROGRESS")
AQ_EventFrame:RegisterEvent ("QUEST_DETAIL")
AQ_EventFrame:RegisterEvent ("QUEST_COMPLETE")
AQ_EventFrame:RegisterEvent ("QUEST_FINISHED")
-- AQ_EventFrame:RegisterEvent ("MERCHANT_SHOW")
AQ_EventFrame:RegisterEvent ("QUEST_GREETING")
AQ_EventFrame:RegisterEvent ("ITEM_PUSH")
AQ_EventFrame:RegisterEvent ("QUEST_AUTOCOMPLETE")
-- AQ_EventFrame:RegisterEvent ("QUEST_ACCEPT_CONFIRM")
-- AQ_EventFrame:RegisterEvent ("UNIT_ENTERED_VEHICLE")
-- AQ_EventFrame:RegisterEvent ("CHROMIE_TIME_OPEN")
-- AQ_EventFrame:RegisterEvent ("QUEST_LOG_UPDATE")
-- AQ_EventFrame:RegisterEvent ("PLAYER_TARGET_CHANGED")
-- AQ_EventFrame:RegisterEvent ("PLAYER_REGEN_ENABLED")
-- AQ_EventFrame:RegisterEvent ("PLAYER_REGEN_DISABLED")
-- AQ_EventFrame:RegisterEvent ("CHAT_MSG_ADDON")
-- AQ_EventFrame:RegisterEvent ("CHAT_MSG_MONSTER_SAY")
-- AQ_EventFrame:RegisterEvent ("CHAT_MSG_COMBAT_XP_GAIN")
-- AQ_EventFrame:RegisterEvent ("LEARNED_SPELL_IN_TAB")
-- AQ_EventFrame:RegisterEvent ("UNIT_AURA")
-- AQ_EventFrame:RegisterEvent ("PLAYER_CHOICE_UPDATE")
-- AQ_EventFrame:RegisterEvent ("REQUEST_CEMETERY_LIST_RESPONSE")
-- AQ_EventFrame:RegisterEvent ("AJ_REFRESH_DISPLAY")
-- AQ_EventFrame:RegisterEvent ("UPDATE_UI_WIDGET")

AQ_EventFrame:SetScript("OnEvent", function(self, event, ...)
--
end)