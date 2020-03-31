class "BRServer"

require("GameStates/None")

-- GameState's
GameStates = {
    Warmup = 0,
    Starting = 1,
    Started = 2,
    SecondHalf = 3,
    Overtime = 4,
    Endgame = 5,
    None = 6
}

function BRServer:__init()
    print("initializing battle royale server")

    self.m_EngineUpdateEvent = Events:Subscribe("Engine:Update", self, self.OnEngineUpdate)
    
    -- Update state timer
    self.m_CurrentUpdateStateTimer = 0.0
    self.m_UpdateStateTime = 1.0

    -- Radius updating timer
    self.m_CurrentRadiusUpdateTimer = 0.0
    self.m_RadiusUpdateTime = 0.5

    -- Enable fade to black, disable for debugging purposes
    self.m_FadeToBlack = true
    self.m_FadeToBlackMaxTime = 5.0
    self.m_CurrentFadeToBlackTime = 0.0

    -- Current round number
    self.m_RoundNumber = 0

    -- Location of the center of the ring
    self.m_CurrentRingPosition = Vec3(0, 0, 0)
    self.m_CurrentRingStatus = FirestormShared.G_RING_STATIONARY
    self.m_CurrentRingMinimumRadius = 1.0      -- Minimum radius of the ring
    self.m_CurrentRingRadius = 500.0    -- Current radius of the ring
    self.m_CurrentRingNumPoints = 16    -- Number of points around the ring
end

function BRServer:OnEngineUpdate(p_DeltaTime, p_SimulationDeltaTime)
    self.m_CurrentUpdateStateTimer = self.m_CurrentUpdateStateTimer + p_DeltaTime
    self.m_CurrentRadiusUpdateTimer = self.m_CurrentRadiusUpdateTimer + p_DeltaTime
    self.m_CurrentUpdateStateTimer = self.m_CurrentUpdateStateTimer + p_DeltaTime

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
end

function BRServer:StateUpdate()
    -- Get total player count
    s_TotalPlayerCount = PlayerManager:GetPlayerCount()

    -- Total squad table
    s_TotalTeamPlayers = { }

    -- Alive squad table
    s_TotalAliveTeamPlayers = { }
    s_TotalAlivePlayers = 0

    -- Initialize both of the lists
    for l_TeamIndex = TeamId.Team1, TeamId.TeamIdCount do
        s_TotalTeamPlayers[l_TeamIndex] = 0
        s_TotalAliveTeamPlayers[l_TeamIndex] = 0
    end

    -- Iterate through all of the players and assign them accordingly
    s_Players = PlayerManager:GetPlayers()
    for l_Index, l_Player in ipairs(s_Players) do
        l_PlayerTeam = l_Player.teamId

        -- Add the total player count to the specified team
        s_TotalTeamPlayers[l_PlayerTeam] = s_TotalTeamPlayers[l_PlayerTeam] + 1

        -- Total up all of the alive players
        if l_Player.alive then
            s_TotalAliveTeamPlayers[l_PlayerTeam] = s_TotalAliveTeamPlayers[l_PlayerTeam] + 1
            s_TotalAlivePlayers = s_TotalAlivePlayers + 1
        end
    end

    s_TeamsLeft = 0
    for l_TeamIndex = TeamId.Team1, TeamId.TeamIdCount do
        if s_TotalAlivePlayers[l_TeamIndex] > 0 then
            s_TeamsLeft = s_TeamsLeft + 1
        end
    end

    NetEvents:Broadcast("BR:UpdateState", s_TotalAlivePlayers, s_TeamsLeft, self.m_RoundNumber, self.m_CurrentRingStatus)
end

function BRServer:RadiusUpdate()
    -- Send clients the radius update message
    NetEvents:Broadcast("BR:UpdateRadius", self.m_CurrentRingRadius, self.m_CurrentRingPosition, self.m_CurrentRingNumPoints)
end

return BRServer()