class "BRClient"

FirestormShared = require "__shared/FirestormShared"
FirestormClient = require "FirestormClient"

function BRClient:__init()
    -- Debug output
    print("Starting battle royale client")

    -- BR:RadiusUpdate([float] p_NewRadius, [Vec3] p_NewPosition)
    -- Subscribe to the server event
    self.m_RadiusUpdateEvent = NetEvents:Subscribe("BR:UpdateRadius", self, self.OnUpdateRadius)
    self.m_RoundStartEvent = NetEvents:Subscribe("BR:RoundStart", self, self.OnRoundStart)
    self.m_RoundEndEvent = NetEvents:Subscribe("BR:RoundEnd", self, self.OnRoundEnd)
    self.m_UpdateStatsEvent = NetEvents:Subscribe("BR:UpdateState", self, self.OnUpdateState)

    -- Engine update events
    self.m_EngineUpdateEvent = Events:Subscribe("Engine:Update", self, self.OnEngineUpdate)

    -- Timer that gets added to each engine update (deltaTime gets added)
    self.m_UpdateTimer = 0.0

    -- Update tick frequency (default: 1 second)
    self.m_UpdateFreq = 2.0

    -- Hold ring information, this is updated by the server
    self.m_CurrentRingRadius = 0.0
    self.m_CurrentRingPosition = Vec3(0, 0, 0)
    self.m_CurrentRingNumPoints = 0 -- default 16
    self.m_CurrentRingStatus = FirestormShared.G_RING_STATIONARY

    -- Stats information, this is updated by the server
    self.m_PlayersLeft = 0
    self.m_TeamsLeft = 0
    self.m_RoundNumber = 0

    -- Raycast start height
    self.m_RaycastStartHeight = 500.0

    -- Hold our ring of fire
    self.m_FireEntity = nil
    self.m_EffectParams = EffectParams()

    -- Initialize all of the handles
    self.m_EffectHandles = { }

    self.m_FirestormClient = FirestormClient()
end

function BRClient:PopulateEffectHandles(p_Count)
    for l_EffectIndex = 0, self.m_CurrentRingNumPoints do
        l_EffectHandle = self.m_EffectHandles[l_EffectIndex]

        -- Stop the effect from playing
        if l_EffectHandle ~= nil then
            EffectManager:StopEffect(l_EffectHandle)
        end

        -- Remove the effect handle from the list
        self.m_EffectHandles[l_EffectIndex] = nil
    end

    -- Clear out the list and start over
    self.m_EffectHandles = { }

    for l_EffectIndex = 0, p_Count do
        self.m_EffectHandles[l_EffectIndex] = nil
    end

    self.m_CurrentRingNumPoints = p_NumPoints

    -- Update effects
    self:GetEffect()
end

function BRClient:GetEffect()
    -- Get all of the fire effects that we needed
end

function BRClient:OnUpdateRadius(p_NewRadius, p_NewPosition, p_NumPoints)
    print("Updating radius size to: " .. p_NewRadius .. " at: " .. p_NewPosition)

    -- Update the current radius
    self.m_CurrentRingRadius = p_NewRadius
    self.m_CurrentRingPosition = p_NewPosition

    -- Check to see if we need to re-create the effects
    if self.m_CurrentRingNumPoints ~= p_NumPoints then
        self:PopulateEffectHandles(p_NumPoints)

        -- Create new effects
        for l_EffectIndex = 0, self.m_CurrentRingNumPoints do
            l_Vec = self:GetRaycastPosition(l_EffectIndex)

            l_Transform = LinearTransform()
            l_Transform.trans = l_Vec
            l_EffectHandle = EffectManager:PlayEffect(self.m_FireEntity, l_Transform, self.m_Params, true)
            if EffectManager:IsEffectPlaying(l_EffectHandle) == false then
                print("could not play effect")
                goto effect_continue
            end

            self.m_EffectHandles[l_EffectIndex] = l_EffectHandle

            ::effect_continue::
        end
    else
        -- Move existing effects
        for l_EffectIndex = 0, self.m_CurrentRingNumPoints do
            l_Vec = self:GetRaycastPosition(l_EffectIndex)

            l_Transform = LinearTransform()
            l_Transform.trans = l_Vec

            -- Get the effect handle
            l_EffectHandle = self.m_EffectHandles[l_EffectIndex]
            if l_EffectHandle == nil then
                goto effect_transform_continue
            end

            EffectManager::TransformEffect(l_EffectHandle, l_Transform)

            ::effect_transform_continue::
        end
    end

end

function BRClient:OnUpdateState(p_AlivePlayersLeft, p_TeamsLeft, p_RoundNumber, p_CircleStatus)
    self.m_PlayersLeft = p_AlivePlayersLeft
    self.m_TeamsLeft = p_TeamsLeft
    self.m_RoundNumber = p_RoundNumber
    self.m_CurrentRingStatus = p_CircleStatus
end

function BRClient:OnRoundStart()
end

function BRClient:OnRoundEnd()
end



function BRClient:OnEngineUpdate(deltaTime, simulationDeltaTime)
    -- Add deltaTime to our current timer
    self.m_UpdateTimer = self.m_UpdateTimer + deltaTime

    --local vec2 = Vec2(1, 2)
    --local vec3 = Vec3(1, 2, 3)
    --local vec4 = Vec4(1, 2, 3, 4)
    --local lt = LinearTransform(vec3, vec3, vec3, vec3)

    --local vec21 = vec2 * 2.0
    --local vec31 = vec3 * 2.0
    --local vec41 = vec4 * 2.0
    --local lt1 = lt * 2.0

    -- If we elapse a tick, reset the timer and fire an event
    if self.m_UpdateTimer > self.m_UpdateFreq then
        self.m_UpdateTimer = 0.0
        self:OnClientTick()
    end
end


function BRClient:OnClientTick()
    print("OnClientTick: Called")

    s_Up = Vec3(0, 1, 0)
    s_Left = Vec3(1, 0, 0)
    s_Forward = Vec3(0, 0, 1)

    s_ResultVec = MathUtils:GetYPRFromULF(s_Up, s_Left, s_Forward)

    print("res: " .. s_ResultVec.x .. " " .. s_ResultVec.y .. " " .. s_ResultVec.z)

    s_LinearTransform = MathUtils:GetTransformFromYPR(3.1415926, 3.1615926, 3.1415926)
    s_Up = s_LinearTransform.up
    s_Left = s_LinearTransform.left
    s_Forward = s_LinearTransform.forward
    s_Trans = s_LinearTransform.trans

    print("up: " .. s_Up.x .. " " .. s_Up.y .. " " .. s_Up.z)
    print("foward: " .. s_LinearTransform.forward.x .. " " .. s_LinearTransform.forward.y .. " " .. s_LinearTransform.forward.z)
    print("left: " .. s_LinearTransform.left.x .. " " .. s_LinearTransform.left.y .. " " .. s_LinearTransform.left.z)
    print("trans: " .. s_LinearTransform.trans.x .. " " .. s_LinearTransform.trans.y .. " " .. s_LinearTransform.trans.z)
end

function BRClient:GetRaycastPosition(p_RingIndex)
    -- Get the x,z coordinate
    s_Location = FirestormShared:GetPoint(self.m_CurrentRingPosition, p_RingIndex, self.m_CurrentRingNumPoints, self.m_CurrentRingRadius)

    -- Place the raycast start location up higher on the y coordinate
    s_RaycastStartLocation = s_Location
    s_RaycastStartLocation.y = s_RaycastStartLocation.y + self.m_RaycastStartHeight

    -- Place the end raycast point below our requested height
    s_RaycastEndLocation = s_Location
    s_RaycastEndLocation.y = s_RaycastStartLocation.y - 100.0

    -- Do the actual raycast
    s_Hit = RaycastManager:Raycast(s_RaycastStartLocation, s_RaycastEndLocation, CheckDetailMesh)
    if s_Hit == nil then
        return s_Location
    end

    -- Get the hit position
    s_HitPosition = s_Hit.position
    print("hit position: " .. s_HitPosition.x .. " " .. s_HitPosition.y .. " " .. s_HitPosition.z)

    -- Return the position
    return s_HitPosition
end


return BRClient()