-- EVENTS: COMBAT_LOG_EVENT_UNFILTERED
function (event, ...)
    if event == "OPTIONS" then
        return false
    end
    local EVENTS = {
        OPTIONS="OPTIONS",
        COMBAT_LOG_EVENT_UNFILTERED="COMBAT_LOG_EVENT_UNFILTERED",
        WA_TW_EVENT="WA_TW_EVENT",
        SPELL_CAST_SUCCESS="SPELL_CAST_SUCCESS"
    }
    local TW_EVENTS = {
        WA_TW_TOTEM_REMOVED="WA_TW_TOTEM_REMOVED"
    }

    local SPELLS = {
        TOTEMIC_CALL="Totemic Call"
    }
    local subEvent = select(2, ...)
    local casterGUID = select(4, ...)

    -- BASE PARAMS --
    local BP_DESTGUID = 8
    -- PREFIX and SUFFIX PARAMS --
    local PSP_SPELL_SPELL_NAME = 13

    if subEvent == EVENTS.SPELL_CAST_SUCCESS then
        if casterGUID == WeakAuras.myGUID then
            local spellName = select(PSP_SPELL_SPELL_NAME, ...)
            if spellName == SPELLS.TOTEMIC_CALL then
                for schoolId, _ in ipairs({"FIRE", "EARTH", "WATER", "AIR"}) do
                    WeakAuras.ScanEvents(EVENTS.WA_TW_EVENT,
                                         TW_EVENTS.WA_TW_TOTEM_REMOVED,
                                         tostring(schoolId))
                end
            end
        end
    end
end
