function(event, ...)
    if aura_env.tw ~= nil and event == "WA_TW_EVENT" then
        local subEvent = select(1, ...)
        local schoolId = tonumber(select(2, ...))
        if schoolId == aura_env.tw.schoolId and
                subEvent == "WA_TW_NOTIFICATION_HIDE" then
            return true
        end
    end
end
