-- ============================================================
-- BHAAL GIFTS — Give items to Dark Urge on game start
-- ============================================================

-- All known Dark Urge tag UUIDs — try each one
local DARK_URGE_TAGS = {
    "3ed35ac5-d527-4324-9680-d168de74de25",
    "d5fa5943-7c17-4313-8fb7-afdc0672c12e",
    "fc01011e-49f9-48a0-a339-f04ccbed75fb",
    "038175d6-5505-4b91-9a57-4f0788fcf217",
    "a5044b9b-39d8-4c7c-8ec6-1b7f3f4dc36f",
}

-- Item root template UUIDs
local RING_TEMPLATE    = "b3e8f1a2-4c7d-9e06-5f3b-8a2d1c6e4f09"
local DAGGER_TEMPLATE  = "d5c7a9e1-3b2f-4d8a-6e0c-1f9a7b3d5e08"
local AMULET_TEMPLATE  = "e9f1b3a5-7c2d-4e6f-8a0b-3d5c1e7f9a02"

local FLAG_NAME = "BhaalGifts_ItemsGiven"

local function IsDarkUrge(player)
    for _, tag in ipairs(DARK_URGE_TAGS) do
        local ok, result = pcall(function() return Osi.IsTagged(player, tag) end)
        if ok and result == 1 then
            _P("[BhaalGifts] Dark Urge detected via tag: " .. tag)
            return true
        end
    end
    -- Fallback: check origin by name via entity system
    local ok2, entity = pcall(Ext.Entity.Get, player)
    if ok2 and entity and entity.Origin and entity.Origin.Origin then
        local origin = entity.Origin.Origin
        _P("[BhaalGifts] Player origin: " .. tostring(origin))
        if string.find(tostring(origin), "DarkUrge") or string.find(tostring(origin), "TheDarkUrge") then
            return true
        end
    end
    return false
end

local function GiveItems(player)
    _P("[BhaalGifts] Giving 3 items to: " .. tostring(player))
    Osi.TemplateAddTo(RING_TEMPLATE, player, 1)
    Osi.TemplateAddTo(DAGGER_TEMPLATE, player, 1)
    Osi.TemplateAddTo(AMULET_TEMPLATE, player, 1)
    Osi.SetVarInteger(player, FLAG_NAME, 1)
    _P("[BhaalGifts] Items given!")
end

local function TryGiveToAllPlayers()
    local ok, players = pcall(function() return Osi.DB_Players:Get(nil) end)
    if not ok or not players then
        _P("[BhaalGifts] DB_Players not available yet")
        return
    end
    _P("[BhaalGifts] Found " .. #players .. " player(s)")
    for _, v in pairs(players) do
        local player = v[1]
        _P("[BhaalGifts] Checking player: " .. tostring(player))
        local alreadyGiven = pcall(function() return Osi.GetVarInteger(player, FLAG_NAME) end)
        if alreadyGiven == 1 then
            _P("[BhaalGifts] Already given, skipping")
        else
            if IsDarkUrge(player) then
                GiveItems(player)
            else
                _P("[BhaalGifts] Not Dark Urge, skipping")
            end
        end
    end
end

-- Try on level load with increasing delays
Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function(levelName, isEditorMode)
    _P("[BhaalGifts] Level started: " .. levelName)
    -- Try multiple times with increasing delays (class equipment might overwrite early)
    Ext.Timer.WaitFor(3000, TryGiveToAllPlayers)
    Ext.Timer.WaitFor(8000, TryGiveToAllPlayers)
    Ext.Timer.WaitFor(15000, TryGiveToAllPlayers)
end)

-- Also trigger on party join
Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", function(character)
    Ext.Timer.WaitFor(3000, function()
        _P("[BhaalGifts] Character joined party: " .. tostring(character))
        if IsDarkUrge(character) then
            local ag = pcall(function() return Osi.GetVarInteger(character, FLAG_NAME) end)
            if ag ~= 1 then
                GiveItems(character)
            end
        end
    end)
end)

-- ============================================================
-- CONSOLE COMMAND: manual fallback
-- In SE console type: !bhaal
-- This gives items to ALL players regardless of origin
-- ============================================================
Ext.RegisterConsoleCommand("bhaal", function(cmd)
    _P("[BhaalGifts] Manual give via console command!")
    local ok, players = pcall(function() return Osi.DB_Players:Get(nil) end)
    if ok and players then
        for _, v in pairs(players) do
            GiveItems(v[1])
        end
    else
        _P("[BhaalGifts] ERROR: No players found. Are you in a loaded game?")
    end
end)

_P("[BhaalGifts] Script loaded! Use '!bhaal' in SE console to manually give items.")
