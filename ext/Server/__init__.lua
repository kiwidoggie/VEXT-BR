class "BRServer"

FirestormServer =
{
    -- Rounds
    Default_MaxRounds = 10,

    -- Game state
    Default_UpdateGameStateTime = 1.5, -- In seconds
    Default_MinPlayerCount = 4,

    -- Ring defaults
    Default_RingCloseTime = 5.0, -- In seconds
    Default_RingStationaryTime = 5.0, -- In Seconds
    Default_RingRadius = 100.0, -- Should be re-calculated based on spawn bb
    Default_UpdateRingTime = 0.5, -- In seconds
    
    -- Fade to black defaults
    Default_FadeToBlackTime = 2.0, -- Wait 2 seconds
    FadeToBlack_VisibleToBlack = 0,
    FadeToBlack_BlackToVisible = 1,
    FadeToBlack_Disabled = 2,

    -- Default ring positions for certain maps (used for debugging)
    RingPosition_Metro = Vec3(-95.0356827, 69.8191986, -98.9525299),
    RingPosition_Kharg = Vec3(-287.066406, 130.306442, -219.524414),

    Random = function (lower, greater)
        return lower + math.random()  * (greater - lower);
    end
}

function BRServer:__init()
    print("initializing battle royale server")

    self.m_EngineUpdateEvent = Events:Subscribe("Engine:Update", self, self.OnEngineUpdate)
    
    -- Update state timer (for sending events)
    self.m_UpdateGameStateTimer = 0.0
    self.m_UpdateGameStateMaxTime = FirestormServer.Default_UpdateGameStateTime
    -- Keep the current game state
    self.m_GameState = FirestormShared.GAMESTATE_WARMUP
    self.m_MinPlayerCount = 2 -- FirestormServer.Default_MinPlayerCount

    -- Radius updating timer (for sending events)
    self.m_UpdateRingTimer = 0.0
    self.m_UpdateRingMaxTime = FirestormServer.Default_UpdateRingTime

    -- Enable fade to black, disable for debugging purposes
    self.m_FadeToBlackState = FirestormServer.FadeToBlack_Disabled
    self.m_FadeToBlackMaxTime = FirestormServer.Default_FadeToBlackTime
    self.m_FadeToBlackTimer = 0.0

    -- Rounds
    self.m_MaxRounds = FirestormServer.Default_MaxRounds
    self.m_RoundNumber = 1

    -- Ring timers
    self.m_RingStationaryMaxTime = FirestormServer.Default_RingStationaryTime
    self.m_RingClosingMaxTime = FirestormServer.Default_RingCloseTime
    -- Used by both the stationary, and active rings based on ring state
    self.m_RingTimer = 0.0
    -- Location of the ring (should be calculated based on bounding box)
    self.m_RingPosition = Vec3(0, 0, 0)
    -- State of the current ring
    self.m_RingStatus = FirestormShared.G_RING_STATIONARY
    -- The smaller the circle, the less points we need to save on resources
    self.m_RingPoints = 32
end

function BRServer:ResetGameState()
    -- Resets the gamestate back to a clean game

    -- Update state timer (for sending events)
    self.m_UpdateGameStateTimer = 0.0
    self.m_UpdateGameStateMaxTime = FirestormServer.Default_UpdateGameStateTime
    -- Keep the current game state
    self.m_GameState = FirestormShared.GAMESTATE_WARMUP

    -- Radius updating timer (for sending events)
    self.m_UpdateRingTimer = 0.0
    self.m_UpdateRingMaxTime = FirestormServer.Default_UpdateRingTime

    -- Enable fade to black, disable for debugging purposes
    self.m_FadeToBlackState = FirestormServer.FadeToBlack_Disabled
    self.m_FadeToBlackMaxTime = FirestormServer.Default_FadeToBlackTime
    self.m_FadeToBlackTimer = 0.0

    -- Rounds
    self.m_MaxRounds = FirestormServer.Default_MaxRounds
    self.m_RoundNumber = 1

    -- Ring timers
    self.m_RingStationaryMaxTime = FirestormServer.Default_RingStationaryTime
    self.m_RingClosingMaxTime = FirestormServer.Default_RingCloseTime
    -- Used by both the stationary, and active rings based on ring state
    self.m_RingTimer = 0.0
    -- Location of the ring (should be calculated based on bounding box)
    self.m_RingPosition = Vec3(0, 0, 0)
    -- State of the current ring
    self.m_RingStatus = FirestormShared.G_RING_STATIONARY
    -- The smaller the circle, the less points we need to save on resources
    self.m_RingPoints = 32
    -- Current ring radius
    self.m_RingRadius = 0.0
    self.m_RingRadiusPart = 0.0
    -- This is used so we can lerp in between the two radius' radi? idk
    self.m_PreviousRingRadius = 0.0 -- each round 10% of the ring goes away
    self.m_NextRingRadius = 0.0 -- The "destination" size of the ring once 10% is erroded
end

function BRServer:SelectCenter()
    -- This function handles selecting where the endgame ring position will be
    -- TODO: Determine map size
    -- TODO: Get a "bounding box" of where all player spawns are
    -- TODO: select a random point inside of the "bounding box"
    -- TODO: Return the point
end

function BRServer:OnEngineUpdate(p_DeltaTime, p_SimulationDeltaTime)
    self.m_UpdateGameStateTimer = self.m_UpdateGameStateTimer + p_DeltaTime
    self.m_UpdateRingTimer = self.m_UpdateRingTimer + p_DeltaTime

    -- Always tick the update state timer, even in preround or whatever
    if self.m_UpdateGameStateTimer > self.m_UpdateGameStateMaxTime then
        self.m_UpdateGameStateTimer = 0.0
        self:UpdateGameState()
    end

    if self.m_GameState == FirestormShared.GAMESTATE_WARMUP then
        -- Handle the warmup conditions
        -- TODO: Wait for at least 2 players
        -- TOOD: Calculate the ring bounds
        -- TODO: Calculate the ring position
        -- TODO: Wait for players ready state
        -- TODO: Allow for squad joining, respawning, give players random kits that do no damage or disable damage state
        -- TODO: Implement blackout while we switch states
    elseif self.m_GameState == FirestormShared.GAMESTATE_INGAME then
        -- Handle the ingame conditions
        -- TODO: Update the ring state, handle calculations etc
        -- TODO: Disable respawning of players
        -- TODO: Disable ticket bleed
        -- TODO: Enable spectator mode for dead players
        -- TODO: Implement day-nite cycle (maybe)

        -- Tick the current radius update timer
        if self.m_UpdateRingTimer > self.m_UpdateRingMaxTime then
            self:UpdateRing(self.m_UpdateRingTimer)
            self.m_UpdateRingTimer = 0.0
        end
    elseif self.m_GameState == FirestormShared.GAMESTATE_GAMEOVER then
        -- Handle the game over conditions
        -- TODO: Force everyone to spectate the winners
        -- TODO: Implement blackout while we transition back to warmup
    end

    if self.m_IsGameRunning == true then
        

    end
end

function BRServer:Lerp(a, b, f)
    return a + f * (b - a)
end

function BRServer:UpdateGameState()
    -- We always want to update the player counts no matter what, this is to ensure we can use them later in our game logic

    -- Get total player count
    local s_TotalPlayerCount = PlayerManager:GetPlayerCount()

    -- Total squad table
    local s_TotalTeamPlayers = { }

    -- Alive squad table
    local s_TotalAliveTeamPlayers = { }
    local s_TotalAlivePlayers = 0

    -- Initialize both of the lists
    for l_TeamIndex = TeamId.TeamNeutral, TeamId.TeamIdCount do
        s_TotalTeamPlayers[l_TeamIndex] = 0
        s_TotalAliveTeamPlayers[l_TeamIndex] = 0
    end

    -- Iterate through all of the players and assign them accordingly
    local s_Players = PlayerManager:GetPlayers()
    for l_Index, l_Player in ipairs(s_Players) do
        local l_PlayerTeam = l_Player.teamId
        if l_PlayerTeam == TeamId.TeamNeutral then
            goto state_player_next
        end

        -- Add the total player count to the specified team
        s_TotalTeamPlayers[l_PlayerTeam] = s_TotalTeamPlayers[l_PlayerTeam] + 1

        -- Total up all of the alive players
        if l_Player.alive then
            s_TotalAliveTeamPlayers[l_PlayerTeam] = s_TotalAliveTeamPlayers[l_PlayerTeam] + 1
            s_TotalAlivePlayers = s_TotalAlivePlayers + 1
        end

        ::state_player_next::
    end

    local s_TeamsLeft = 0
    for l_TeamIndex = TeamId.Team1, TeamId.TeamIdCount do
        if s_TotalAliveTeamPlayers[l_TeamIndex] > 0 then
            s_TeamsLeft = s_TeamsLeft + 1
        end
    end

    

    if self.m_GameState == FirestormShared.GAMESTATE_WARMUP then
        if s_TotalPlayerCount >= 1--[[self.m_MinPlayerCount--]] then
            ChatManager:SendMessage("Get ready, we are starting!")
            PlayerManager:FadeOutAll(self.m_FadeToBlackMaxTime)
            self.m_FadeToBlackState = FirestormServer.FadeToBlack_VisibleToBlack

            local s_MinX = 0.0
            local s_MaxX = 0.0

            local s_MinY = 0.0
            local s_MaxY = 0.0

            local s_MinZ = 0.0
            local s_MaxZ = 0.0
            
            -- Calculate the bounding box
            local s_Iterator = EntityManager:GetIterator("ServerCharacterSpawnEntity")
            if s_Iterator ~= nil then
                local s_SpawnEntity = SpatialEntity(s_Iterator:Next())
                --print("spawnEntity: " .. s_SpawnEntity)
                while s_SpawnEntity ~= nil do
                    --print("found entity")
                    -- Check to see if this spawn point is enabled
                    --local l_SpawnTransform = LinearTransform()
                    print(s_SpawnEntity.typeInfo.name)
                    local l_SpawnEntity = SpatialEntity(s_SpawnEntity)
                    local l_SpawnTransform = l_SpawnEntity.transform
                    local l_SpawnPosition = l_SpawnTransform.trans
                    --local l_SpawnPosition = l_SpawnTransform.trans
                    --print(l_SpawnPosition)

                    -- Check for minimums
                    if l_SpawnPosition.x < s_MinX then
                        s_MinX = l_SpawnPosition.x
                    end

                    if l_SpawnPosition.y < s_MinY then
                        s_MinY = l_SpawnPosition.y
                    end

                    if l_SpawnPosition.z < s_MinZ then
                        s_MinZ = l_SpawnPosition.z
                    end

                    -- Check for maximums
                    if l_SpawnPosition.x > s_MaxX then
                        s_MaxX = l_SpawnPosition.x
                    end

                    if l_SpawnPosition.y > s_MaxY then
                        s_MaxY = l_SpawnPosition.y
                    end

                    if l_SpawnPosition.z > s_MaxZ then
                        s_MaxZ = l_SpawnPosition.z
                    end

                    -- Get the next entity
                    s_SpawnEntity = s_Iterator:Next()
                end
            end

            -- Pick a random point
            local s_RandomX = FirestormServer.Random(s_MinX, s_MaxX)
            local s_RandomY = FirestormServer.Random(s_MinY, s_MaxY)
            local s_RandomZ = FirestormServer.Random(s_MinZ, s_MaxZ)
            print("selected new point (" .. s_RandomX .. "," .. s_RandomY .. "," .. s_RandomZ)

            local s_MaxWidth = s_MaxX - s_MinX
            local s_MaxDepth = s_MaxZ - s_MinZ

            print("maxWidth: " .. s_MaxWidth .. " maxDepth: " .. s_MaxDepth)

            local s_Radius = (s_MaxWidth + s_MaxDepth) / 2.0
            print("newRadius: " .. s_Radius)

            self.m_RingRadius = s_Radius / 2.0
            self.m_RingPosition = Vec3(s_RandomX, 200.0, s_RandomZ)
            --self.m_RingPosition = FirestormServer.RingPosition_Kharg

            self.m_GameState = FirestormShared.GAMESTATE_INGAME
        end
    elseif self.m_GameState == FirestormShared.GAMESTATE_INGAME then
        -- If we are switching from warmup, we should enable players vision
        if self.m_FadeToBlackState == FirestormServer.FadeToBlack_VisibleToBlack then
            -- We want to make the players able to see after another 1.5s
            PlayerManager:FadeInAll(self.m_FadeToBlackMaxTime)

            -- Disable the state for the rest of the in-game
            self.m_FadeToBlackState = FirestormServer.FadeToBlack_Disabled
        end

        if s_TotalPlayerCount < 1 then
            self:ResetGameState()
        end
        
    elseif self.m_GameState == FirestormShared.GAMESTATE_GAMEOVER then
    end

    --print("broadcasting update")
    print("currentRingStatus: " .. self.m_RingStatus)
    NetEvents:Broadcast("BR:GameStateUpdate", s_TotalAlivePlayers, s_TeamsLeft, self.m_RoundNumber, self.m_RingStatus)
end

function BRServer:UpdateRing(p_DeltaTime)
    -- Determine which state the ring is in
    if self.m_RingStatus == FirestormShared.G_RING_STATIONARY then
        -- Update the current round wait time
        self.m_RingTimer = self.m_RingTimer + p_DeltaTime

        -- If we have expired, switch to the ring closing
        if self.m_RingTimer > self.m_RingStationaryMaxTime then
            print("Ring status updating to Closing")

            -- Reset the ring timer (so closing can use it now)
            self.m_RingTimer = 0.0

            -- Only on the first round do we want to calulcate 10%
            if self.m_RoundNumber == 1 then
                -- There are 10 rounds, 10% each round until it's gone
                self.m_RingRadiusPart = (self.m_RingRadius * 0.10)
            end

            -- Increase the round count
            self.m_RoundNumber = self.m_RoundNumber + 1

            -- Update the previous ring radius and the next ring radius
            self.m_PreviousRingRadius = self.m_RingRadius

            self.m_NextRingRadius = self.m_RingRadius - self.m_RingRadiusPart

            -- Cap the smallest ring radius
            if self.m_NextRingRadius < 0.0 then
                self.m_NextRingRadius = 0.0
            end

            -- Change the status of the ring
            self.m_RingStatus = FirestormShared.G_RING_CLOSING
        end
    elseif self.m_CurrentRingStatus == FirestormShared.G_RING_CLOSING then
        -- Handle when the ring is in the closing state

        -- Update the current close timer
        self.m_RingTimer = self.m_RingTimer + p_DeltaTime

        -- Calcualte the position between the current time / total time
        local s_FractionOfJourney = self.m_RingTimer / self.m_RingClosingMaxTime

        -- Lerp our current time to get a final answer between the 2 radius'
        local s_NewRadius = self:Lerp(self.m_PreviousRingRadius, self.m_NextRingRadius, s_FractionOfJourney)

        self.m_RingRadius = s_NewRadius

        -- Check to see if our close time is completed, then we can switch back to the stationary time
        if self.m_RingTimer > self.m_RingClosingMaxTime then
            print("Ring status updating to Stationary")
            -- We need to change back to the stationary state
            self.m_RingTimer = 0.0
            self.m_RingStatus = FirestormShared.G_RING_STATIONARY
        end
    end

    -- Send clients the radius update message
    NetEvents:Broadcast("BR:RingUpdate", self.m_RingRadius, self.m_RingPosition, self.m_RingPoints)

    -- Iterate through all players and apply damage if they are outside of the radius
    local s_Players = PlayerManager:GetPlayers()
    for l_Index, l_Player in ipairs(s_Players) do
        if l_Player == nil then
            goto radius_player_continue
        end

        self:DamagePlayerIfOutsideOfRadius(l_Player)        
        ::radius_player_continue::
    end
end

function BRServer:DamagePlayerIfOutsideOfRadius(p_Player)
    if p_Player == nil then
        return
    end

    -- Check if the player is alive
    if p_Player.alive == false then
        return
    end

    -- Get the soldier instance
    local s_Soldier = p_Player.soldier
    if s_Soldier == nil then
        return
    end

    -- Get the soldier transform
    local s_Transform = s_Soldier.worldTransform

    -- Get the position from the transform
    local s_Position = s_Transform.trans
    
    -- Get the 2d distance
    local s_Distance = self:TwoDeeDistance(s_Position, self.m_RingPosition)
    -- Check to see if the player is outside of the radius
    if s_Distance > self.m_RingRadius then
        s_DamageInfo = DamageInfo()
        s_DamageInfo.damage = 0.25 * self.m_RoundNumber -- Increase the hurt based on round number
        s_DamageInfo.position = s_Position
        s_DamageInfo.direction = Vec3(0, 1, 0)
        s_DamageInfo.shouldForceDamage = true

        s_Soldier:ApplyDamage(s_DamageInfo)
    end
end

function BRServer:TwoDeeDistance(p_Vec1, p_Vec2)
    return math.sqrt( ( (p_Vec2.x - p_Vec1.x) * (p_Vec2.x - p_Vec1.x) ) + ( (p_Vec2.z - p_Vec1.z) * (p_Vec2.z - p_Vec1.z) ) )
end

return BRServer()