class "BRServer"

function BRServer:__init()
    print("initializing battle royale server")

    self.m_EngineUpdateEvent = Events:Subscribe("Engine:Update", self, self.OnEngineUpdate)
    
    -- Update state timer
    self.m_CurrentUpdateStateTimer = 0.0
    self.m_UpdateStateTime = 1.5

    -- Radius updating timer
    self.m_CurrentRadiusUpdateTimer = 0.0
    self.m_RadiusUpdateTime = 0.5

    -- Enable fade to black, disable for debugging purposes
    self.m_FadeToBlack = true
    self.m_FadeToBlackMaxTime = 5.0
    self.m_CurrentFadeToBlackTime = 0.0

    -- Current round number
    self.m_MaxRounds = 4
    self.m_RoundNumber = 0
    self.m_RoundWaitTime = 210.0 -- 3m30s
    self.m_CurrentRoundWaitTime = 0.0
    self.m_CloseTime = 60 -- 1m
    self.m_CurrentCloseTime = 0.0

    -- Keep the current game state
    self.m_IsGameRunning = false

    -- Location of the center of the ring
    self.m_CurrentRingPosition = Vec3(-95.0356827, 69.8191986, -98.9525299)    --Vec3(0, 0, 0)
    self.m_CurrentRingStatus = FirestormShared.G_RING_STATIONARY
    self.m_CurrentRingMinimumRadius = 1.0      -- Minimum radius of the ring
    self.m_CurrentRingRadius = 25.0    -- Current radius of the ring
    self.m_CurrentRingNumPoints = 30    -- Number of points around the ring
end

function BRServer:OnEngineUpdate(p_DeltaTime, p_SimulationDeltaTime)
    self.m_CurrentUpdateStateTimer = self.m_CurrentUpdateStateTimer + p_DeltaTime
    self.m_CurrentRadiusUpdateTimer = self.m_CurrentRadiusUpdateTimer + p_DeltaTime

    -- Always tick the update state timer, even in preround or whatever
    if self.m_CurrentUpdateStateTimer > self.m_UpdateStateTime then
        self.m_CurrentUpdateStateTimer = 0.0
        self:StateUpdate()
    end

    -- Always tick the current radius update timer
    if self.m_CurrentRadiusUpdateTimer > self.m_RadiusUpdateTime then
        self.m_CurrentRadiusUpdateTimer = 0.0
        self:RadiusUpdate()
    end

    if self.m_IsGameRunning == true then
        if self.m_CurrentRingStatus == FirestormShared.G_RING_STATIONARY then
            self.m_CurrentRoundWaitTime = self.m_CurrentRoundWaitTime + p_DeltaTime
            if self.m_CurrentRoundWaitTime > self.m_RoundWaitTime then
                -- We need to change to the closing state, and increase the round count
                self.m_CurrentRoundWaitTime = 0.0
                self.m_RoundNumber = self.m_RoundNumber + 1
                self.m_CurrentRingStatus = FirestormShared.G_RING_CLOSING
            end
        elseif self.m_CurrentRingStatus == FirestormShared.G_RING_CLOSING then

        end

    end
end

function BRServer:StateUpdate()
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

    --print("broadcasting update")
    NetEvents:Broadcast("BR:UpdateState", s_TotalAlivePlayers, s_TeamsLeft, self.m_RoundNumber, self.m_CurrentRingStatus)
end

function BRServer:RadiusUpdate()
    -- Send clients the radius update message
    NetEvents:Broadcast("BR:UpdateRadius", self.m_CurrentRingRadius, self.m_CurrentRingPosition, self.m_CurrentRingNumPoints)

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
    local s_Distance = self:TwoDeeDistance(s_Position, self.m_CurrentRingPosition)
    -- Check to see if the player is outside of the radius
    if s_Distance > self.m_CurrentRingRadius then
        s_DamageInfo = DamageInfo()
        s_DamageInfo.damage = 0.25
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