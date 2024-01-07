--Mod Registration
local mod = RegisterMod("Six Character Mod", 1)
local game = Game()
local sfx = SFXManager()
local seeds = game:GetSeeds()
local startSeed = seeds:GetStartSeed()
local rng = RNG()
SIXCHARACTERMOD = true

--Library of Isaac
local LoI = "library_of_isaac"
local LOCAL_TSIL = require(LoI .. ".TSIL")
LOCAL_TSIL.Init(LoI)

--Class to Variable

--Mod Variables
mod.characters = {
    Six = Isaac.GetPlayerTypeByName("Six", false)
}
mod.challenges = {

}
mod.items = {

}
mod.mechanics = {
    deathcircle = {

    }
}
mod.entities = {
    innerCircleHitbox = Isaac.GetEntityTypeByName("radiusCircleInnerHitbox")
}
local whatever = Sprite()
whatever:Load("gfx/ui/radiusCircle.anm2", true)
whatever:Play("radius", true)

local whateverInner = Sprite()
whateverInner:Load("gfx/ui/radiusCircleInner.anm2", true)
whateverInner:Play("radius", true)

local function generateDeathCircleTable(player)
    return {
        placeholderRadius = 100,
        placeholderRadiusInner = 50,
        placeholderRotation = 0,
        placeholderOffset = Vector(0,0),
        placeholderOffsetInner = Vector(0,0),
        placeholderInnateOffset = Vector(0,-2.5),
        innerCircleHitbox = nil
    }
end

--Helpful Functions
local function lerp(first, second, percent)
    return (first + (second - first) * percent)
end

local function toTears(fireDelay) --thanks oat for the cool functions for calculating firerate!
    return 30 / (fireDelay + 1)
end
local function fromTears(tears)
    return math.max((30 / tears) - 1, -0.99)
end

--Functions
function mod:PlayerInit(player)
    mod.mechanics.deathcircle[startSeed] = generateDeathCircleTable(player)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.PlayerInit)

function mod:NewRun(isContinued)
    if isContinued == false then
        seeds = game:GetSeeds()
        startSeed = seeds:GetStartSeed()
        rng:SetSeed(startSeed, 35)

        whatever.Color = Color(255/255, 0/255, 0/255, 255/255, 0/255, 0/255, 0/255)
        whateverInner.Color = whatever.Color

        for playerNum = 1, game:GetNumPlayers() do
            local player = game:GetPlayer(playerNum)
            local player_uuid=player:GetCollectibleRNG(1):GetSeed()
            if not mod.mechanics.deathcircle[player_uuid] then mod.mechanics.deathcircle[player_uuid]=generateDeathCircleTable(player) end
            mod.mechanics.deathcircle[player_uuid].innerCircleHitbox = Isaac.Spawn(mod.entities.innerCircleHitbox, 0, 0, player.Position, Vector(0,0), nil)
            mod.mechanics.deathcircle[player_uuid].innerCircleHitbox:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            mod.mechanics.deathcircle[player_uuid].innerCircleHitbox:AddEntityFlags(EntityFlag.FLAG_PERSISTENT)
            mod.mechanics.deathcircle[player_uuid].innerCircleHitbox.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            mod.mechanics.deathcircle[player_uuid].innerCircleHitbox.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.NewRun)

function mod:PostPeffectUpdate(player)
    if player:GetPlayerType() == mod.characters.Six then
        local player_uuid=player:GetCollectibleRNG(1):GetSeed()
        if not mod.mechanics.deathcircle[player_uuid] then mod.mechanics.deathcircle[player_uuid]=generateDeathCircleTable(player) end

        mod.mechanics.deathcircle[player_uuid].placeholderRadius = player.TearRange/4
        mod.mechanics.deathcircle[player_uuid].placeholderRadiusInner = player.TearRange/8
        if mod.mechanics.deathcircle[player_uuid].innerCircleHitbox ~= nil then
            mod.mechanics.deathcircle[player_uuid].innerCircleHitbox.Size = mod.mechanics.deathcircle[player_uuid].placeholderRadiusInner
            mod.mechanics.deathcircle[player_uuid].innerCircleHitbox.Position = player.Position+mod.mechanics.deathcircle[player_uuid].placeholderOffsetInner
        end

        local roomEntitiesOuter = Isaac.FindInRadius(player.Position+mod.mechanics.deathcircle[player_uuid].placeholderOffset, mod.mechanics.deathcircle[player_uuid].placeholderRadius, EntityPartition.ENEMY)
        local roomEntitiesInner = Isaac.FindInRadius(player.Position+mod.mechanics.deathcircle[player_uuid].placeholderOffsetInner, mod.mechanics.deathcircle[player_uuid].placeholderRadiusInner, EntityPartition.ENEMY)
        for _, entity in ipairs(roomEntitiesOuter) do
            if entity:IsActiveEnemy() and entity:IsVulnerableEnemy() then
                if player.TearFlags & TearFlags.TEAR_POISON > 0 then
                    entity:AddPoison(EntityRef(player), 5, 1)
                end

                local tears = math.max(1.0, fromTears(toTears(player.MaxFireDelay)))
                local tearsInner = tears / 4

                for _, entity2 in ipairs(roomEntitiesInner) do
                    if game:GetFrameCount()%tearsInner == 0 then
                        entity2:TakeDamage(player.Damage/4, 0, EntityRef(player), 0)
                        sfx:Play(SoundEffect.SOUND_BOSS_LITE_HISS, 0.5, 2, false, 4, 0)
                    end
                end
                if game:GetFrameCount()%tears == 0 then
                    entity:TakeDamage(player.Damage/4, 0, EntityRef(player), 0)
                    sfx:Play(SoundEffect.SOUND_BOSS_LITE_HISS, 0.5, 2, false, 4, 0)
                end

                if player:HasCollectible(CollectibleType.COLLECTIBLE_HAEMOLACRIA) then
                    if game:GetFrameCount()%tears == 0 then
                        for i=1,1 do
                            local tear = player:FireTear(entity.Position+RandomVector()*25, RandomVector()*5, true, true, false, entity, 1)
                            tear:ChangeVariant(TearVariant.BLOOD)
                        end
                    end
                end
            end
        end
        local room = Game():GetRoom()
        for i = 0, room:GetGridSize() do
            local grid = room:GetGridEntity(i)

            if grid ~= nil and grid:GetType() == GridEntityType.GRID_POOP and mod.mechanics.deathcircle[player_uuid].innerCircleHitbox ~= nil then
                if TSIL.Utils.Math.IsCircleIntersectingWithRectangle ( grid.Position, Vector(40, 40), mod.mechanics.deathcircle[player_uuid].innerCircleHitbox.Position, mod.mechanics.deathcircle[player_uuid].innerCircleHitbox.Size ) == true then
                    if game:GetFrameCount()%3 == 0 then
                        grid:Hurt(1)
                    end
                end
            end
        end

        for _, gridEntity in pairs(Isaac.FindInRadius(player.Position+mod.mechanics.deathcircle[player_uuid].placeholderOffsetInner, mod.mechanics.deathcircle[player_uuid].placeholderRadiusInner, EntityPartition.ENEMY)) do
            if game:GetFrameCount()%3 == 0 then
                if gridEntity.Type == EntityType.ENTITY_FIREPLACE and gridEntity.Variant == 10 then
                    gridEntity:TakeDamage(99, 0, EntityRef(nil), 0)
                end
                
                if gridEntity.Type == EntityType.ENTITY_FIREPLACE and gridEntity.Variant <= 1 
                or gridEntity.Type == EntityType.ENTITY_MOVABLE_TNT 
                or gridEntity.Type == EntityType.ENTITY_POOP 
                then
                    gridEntity:Die()
                end
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.PostPeffectUpdate)

function mod:Render()
    for playerNum = 1, game:GetNumPlayers() do
        local player = game:GetPlayer(playerNum)
        local player_uuid=player:GetCollectibleRNG(1):GetSeed()
        if not mod.mechanics.deathcircle[player_uuid] then mod.mechanics.deathcircle[player_uuid]=generateDeathCircleTable(player) end

        mod.mechanics.deathcircle[player_uuid].placeholderRotation = mod.mechanics.deathcircle[player_uuid].placeholderRotation + 1
        mod.mechanics.deathcircle[player_uuid].placeholderRotation = mod.mechanics.deathcircle[player_uuid].placeholderRotation % 360

        if player:GetPlayerType() == mod.characters.Six then
            -- Synergies
            if player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) then whatever.Color = Color(255/255, 255/255, 190/255, 255/255, 0/255, 0/255, 0/255) whateverInner.Color = whatever.Color end
            
            mod.mechanics.deathcircle[player_uuid].placeholderOffset = lerp(mod.mechanics.deathcircle[player_uuid].placeholderOffset+mod.mechanics.deathcircle[player_uuid].placeholderInnateOffset, player:GetAimDirection()*mod.mechanics.deathcircle[player_uuid].placeholderRadius, player.ShotSpeed/10)
            local wts = Isaac.WorldToScreen(player.Position+mod.mechanics.deathcircle[player_uuid].placeholderOffset)
            whatever.Scale = Vector.One * mod.mechanics.deathcircle[player_uuid].placeholderRadius
            whatever.Rotation = mod.mechanics.deathcircle[player_uuid].placeholderRotation
            whatever:Render(wts)

            mod.mechanics.deathcircle[player_uuid].placeholderOffsetInner = lerp(mod.mechanics.deathcircle[player_uuid].placeholderOffsetInner+mod.mechanics.deathcircle[player_uuid].placeholderInnateOffset, player:GetAimDirection()*mod.mechanics.deathcircle[player_uuid].placeholderRadiusInner, player.ShotSpeed/10)
            local wtsInner = Isaac.WorldToScreen(player.Position+mod.mechanics.deathcircle[player_uuid].placeholderOffsetInner)
            whateverInner.Scale = Vector.One * mod.mechanics.deathcircle[player_uuid].placeholderRadiusInner
            whateverInner.Rotation = mod.mechanics.deathcircle[player_uuid].placeholderRotation
            whateverInner:Render(wtsInner)
        end

    end
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.Render)

--File Inclusions