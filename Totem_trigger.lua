-- EVENTS: COMBAT_LOG_EVENT_UNFILTERED, PLAYER_TOTEM_UPDATE, WA_TW_EVENT
function(event, ...)
    local VERSION = "0.3.5"  -- increment this everytime you add some changes
    if aura_env.tw == nil or aura_env.tw.version ~= VERSION then
        local SCHOOL = 1 -- set this to appropriate school for your totems.
                         -- 1 - Fire, 2 - Earth, 3 - Water, 4 - Air
        local NITIFCATION_TIMEOUT = 10  -- seconds
        local STATUSES = {NONE=1, SET=2, DESTROYED=3, EXPIRED=4, REMOVED=5}
        local SCHOOLS = {"FIRE", "EARTH", "WATER", "AIR"}
        local TOTEMS_LIST = {
            FIRE={
                {name="Fire Elemental Totem",   icon=135790, durable=true},
                {name="Fire Nova Totem",        icon=135824, durable=false},
                {name="Magma Totem",            icon=135826, durable=false},
                {name="Searing Totem",          icon=135825, durable=false},
                {name="Flametongue Totem",      icon=136040, durable=false},
                {name="Frost Resistance Totem", icon=135866, durable=false}
            },
            EARTH={
                {name="Earthbind Totem",         icon=136102, durable=false},
                {name="Stoneclaw Totem",         icon=136097, durable=true},
                {name="Stoneskin Totem",         icon=136098, durable=false},
                {name="Earth Elemental Totem",   icon=136024, durable=true},
                {name="Strength of Earth Totem", icon=136023, durable=false},
                {name="Tremor Totem",            icon=136108, durable=false}
            },
            WATER={
                {name="Fire Resistance Totem",   icon=135832, durable=false},
                {name="Disease Cleansing Totem", icon=136019, durable=false},
                {name="Healing Stream Totem",    icon=135127, durable=false},
                {name="Mana Spring Totem",       icon=136053, durable=false},
                {name="Poison Cleansing Totem",  icon=136070, durable=false},
                {name="Mana Tide Totem",         icon=135861, durable=false}
            },
            AIR={
                {name="Grace of Air Totem",      icon=136046, durable=false},
                {name="Grounding Totem",         icon=136039, durable=false},
                {name="Nature Resistance Totem", icon=136061, durable=false},
                {name="Sentry Totem",            icon=136082, durable=false},
                {name="Windfury Totem",          icon=136114, durable=false},
                {name="Wrath of Air Totem",      icon=136092, durable=false},
                {name="Tranquil Air Totem",      icon=136013, durable=false}
            }
        }
        local EVENTS = {
            OPTIONS="OPTIONS",
            COMBAT_LOG_EVENT_UNFILTERED="COMBAT_LOG_EVENT_UNFILTERED",
            PLAYER_TOTEM_UPDATE="PLAYER_TOTEM_UPDATE",
            WA_TW_EVENT="WA_TW_EVENT"
        }
        local TW_EVENTS = {
            WA_TW_TOTEM_SET="WA_TW_TOTEM_SET",
            WA_TW_TOTEM_DESTROYED="WA_TW_TOTEM_DESTROYED",
            WA_TW_TOTEM_REMOVED="WA_TW_TOTEM_REMOVED",
            WA_TW_TOTEM_EXPIRED="WA_TW_TOTEM_EXPIRED",
            WA_TW_NOTIFICATION_SHOW="WA_TW_NOTIFICATION_SHOW",
            WA_TW_NOTIFICATION_HIDE="WA_TW_NOTIFICATION_HIDE"
        }
        local SUB_EVENTS = {
            EVENT_SPELL_SUMMON="SPELL_SUMMON",
            SPELL_CAST_SUCCESS="SPELL_CAST_SUCCESS",
            PLAYER_TOTEM_UPDATE="PLAYER_TOTEM_UPDATE",
            SPELL_DAMAGE="SPELL_DAMAGE",
            SWING_DAMAGE="SWING_DAMAGE"
        }
        -- BASE PARAMS --
        local BP_TIMESTAMP = 1
        local BP_SUBEVENT = 2
        local BP_HIDE_CASTER = 3
        local BP_SOURCE_GUID = 4
        local BP_SOURCE_NAME = 5
        local BP_SOURCE_FLAGS = 6
        local BP_SOURCE_RAID_FLAGS = 7
        local BP_DEST_GUID = 8
        local BP_DEST_MAME = 9
        local BP_DEST_FLAGS = 10
        local BP_DEST_RAID_FLAGS = 11

        -- PREFIX and SUFFIX PARAMS --
        local PSP_SWING_DAMAGE_OVERKILL = 13
        local PSP_SPELL_SUMMON_SPELL_ID = 12
        local PSP_SPELL_SUMMON_SPELL_NAME = 13
        local PSP_SPELL_SUMMON_SPELL_SCHOOL = 14
        local PSP_SPELL_DAMAGE_OVERKILL = 13

        local TotemWatcher = {version=VERSION}
        function TotemWatcher:new(schoolId)
            -- lua --
            local instance = {}
            setmetatable(instance, self)
            self.__index = self

            -- init start --
            self.schoolId = schoolId
            self.status = STATUSES.NONE
            self.timers = {
                totemTimer=nil,
                iconTimer=nil
            }
            self.availableTotems = TOTEMS_LIST[SCHOOLS[self.schoolId]]
            self.totem = {name=nil, guid=nil, icon=nil,
                          durable=nil, duration=nil}
            -- init end --
            return self
        end

        function TotemWatcher.getTotemByNameOrNil(self, table, totemName)
            for _, totem in ipairs(table) do
                if totem.name == totemName then
                    return totem
                end
            end
        end

        function TotemWatcher.handleLogEvent(self, event, ...)
            local subEvent = select(2, ...)
            local casterGUID = select(4, ...)
            if subEvent == SUB_EVENTS.EVENT_SPELL_SUMMON then
                if casterGUID == WeakAuras.myGUID then
                    local totemName = select(PSP_SPELL_SUMMON_SPELL_NAME, ...)
                    local totem = self:getTotemByNameOrNil(self.availableTotems,
                                                           totemName)
                    if totem ~= nil then
                        self.totem.guid = select(BP_DEST_GUID, ...)
                        self.totem.name = totem.name
                        self.totem.durable = totem.durable
                        self.totem.icon = totem.icon
                        self.totem.duration = select(
                            4,GetTotemInfo(self.schoolId)
                        )
                        WeakAuras.ScanEvents(EVENTS.WA_TW_EVENT,
                                             TW_EVENTS.WA_TW_TOTEM_SET,
                                             tostring(self.schoolId))
                        return false
                    end
                end
            end
            if subEvent == SUB_EVENTS.SPELL_CAST_SUCCESS then
                local destGUID = select(BP_DEST_GUID, ...)
                if self.totem.guid == destGUID and not self.totem.durable then
                    WeakAuras.ScanEvents(EVENTS.WA_TW_EVENT,
                                         TW_EVENTS.WA_TW_TOTEM_DESTROYED,
                                         tostring(self.schoolId))
                    return false
                end
            end
            if event == SUB_EVENTS.SWING_DAMAGE or
                    event == SUB_EVENTS.SPELL_DAMAGE then
                local destGUID = select(BP_DEST_GUID, ...)
                local overkill
                if event == SUB_EVENTS.SWING_DAMAGE then
                    overkill = select(PSP_SWING_DAMAGE_OVERKILL, ...)
                elseif event == SUB_EVENTS.SPELL_DAMAGE then
                    overkill = select(PSP_SPELL_DAMAGE_OVERKILL, ...)
                end
                if self.totem.guid == destGUID and overkill >= 0 then
                    WeakAuras.ScanEvents(EVENTS.WA_TW_EVENT,
                                         TW_EVENTS.WA_TW_TOTEM_DESTROYED,
                                         tostring(self.schoolId))
                    return false
                end
            end
        end

        function TotemWatcher.handleTWEvent(self, event, ...)
            local subEvent = select(1, ...)
            local schoolId = select(2, ...)
            if schoolId == tostring(self.schoolId) then
                if subEvent == TW_EVENTS.WA_TW_TOTEM_SET then
                    self.status = STATUSES.SET
                    self:clearIconTimer()
                    self:setTotemTimer(self.totem.duration)
                    WeakAuras.ScanEvents(EVENTS.WA_TW_EVENT,
                                         TW_EVENTS.WA_TW_NOTIFICATION_HIDE,
                                         schoolId)
                elseif subEvent == TW_EVENTS.WA_TW_TOTEM_DESTROYED then
                    self.status = STATUSES.DESTROYED
                    self:clearTotemTimer()
                    self:setIconTimer(NITIFCATION_TIMEOUT)
                    WeakAuras.ScanEvents(EVENTS.WA_TW_EVENT,
                                         TW_EVENTS.WA_TW_NOTIFICATION_SHOW,
                                         schoolId)
                elseif subEvent == TW_EVENTS.WA_TW_TOTEM_REMOVED then
                    self.status = STATUSES.REMOVED
                    self:clearTotemTimer()
                    self:clearIconTimer()
                    WeakAuras.ScanEvents(EVENTS.WA_TW_EVENT,
                                         TW_EVENTS.WA_TW_NOTIFICATION_HIDE,
                                         schoolId)
                elseif subEvent == TW_EVENTS.WA_TW_TOTEM_EXPIRED then
                    self.status = STATUSES.EXPIRED
                    WeakAuras.ScanEvents(EVENTS.WA_TW_EVENT,
                                         TW_EVENTS.WA_TW_NOTIFICATION_SHOW,
                                         schoolId)
                    self:clearTotemTimer()
                    self:setIconTimer(NITIFCATION_TIMEOUT)
                elseif subEvent == TW_EVENTS.WA_TW_NOTIFICATION_SHOW then
                    return true
                elseif subEvent == TW_EVENTS.WA_TW_NOTIFICATION_HIDE then
                    return false
                end
            end
        end

        function TotemWatcher.handleTriggerEvent(self, event, ...)
            if event == EVENTS.OPTIONS then
                return false
            elseif event == EVENTS.PLAYER_TOTEM_UPDATE then
                return self:handlePlayerTotemEvent(event, ...)
            elseif event == EVENTS.COMBAT_LOG_EVENT_UNFILTERED then
                return self:handleLogEvent(event, ...)
            elseif event == EVENTS.WA_TW_EVENT then
                return self:handleTWEvent(event, ...)
            end
        end

        function TotemWatcher.handlePlayerTotemEvent(self, event)
            local schoolId = tostring(self.schoolId)
            local exists = GetTotemInfo(self.schoolId)
            if self.status == STATUSES.SET and not exists then
                WeakAuras.ScanEvents(EVENTS.WA_TW_EVENT,
                                     TW_EVENTS.WA_TW_TOTEM_EXPIRED,
                                     schoolId)
            end
        end

        function TotemWatcher.clearTotemTimer(self)
            if self.timers.totemTimer then
                self.timers.totemTimer:Cancel()
                self.timers.totemTimer = nil
            end
        end

        function TotemWatcher.setTotemTimer(self, duration)
            local schoolId = tostring(self.schoolId)
            self:clearTotemTimer()
            self.timers.totemTimer = C_Timer.NewTimer(duration - 1, function()
                    WeakAuras.ScanEvents(EVENTS.WA_TW_EVENT,
                                         TW_EVENTS.WA_TW_TOTEM_EXPIRED,
                                         schoolId)
            end)
        end

        function TotemWatcher.clearIconTimer(self)
            if self.timers.iconTimer then
                self.timers.iconTimer:Cancel()
                self.timers.iconTimer = nil
            end
        end

        function TotemWatcher.setIconTimer(self, duration)
            local schoolId = tostring(self.schoolId)
            self:clearIconTimer()
            self.timers.iconTimer = C_Timer.NewTimer(duration, function()
                    WeakAuras.ScanEvents(EVENTS.WA_TW_EVENT,
                                         TW_EVENTS.WA_TW_NOTIFICATION_HIDE,
                                         schoolId)
            end)
        end

        -- setting TW
        aura_env.tw = TotemWatcher:new(SCHOOL)
        aura_env.tw_version = aura_env.tw.version
    end
    return aura_env.tw:handleTriggerEvent(event, ...)
end
