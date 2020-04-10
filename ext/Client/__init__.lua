class "BRClient"

--FirestormShared = require("__shared/FirestormShared")

function BRClient:__init()
    -- Debug output
    print("Starting battle royale client")

    -- BR:RadiusUpdate([float] p_NewRadius, [Vec3] p_NewPosition)
    -- Subscribe to the server event
    self.m_RadiusUpdateEvent = NetEvents:Subscribe("BR:UpdateRadius", self, self.OnUpdateRadius)
    self.m_UpdateStatsEvent = NetEvents:Subscribe("BR:UpdateState", self, self.OnUpdateState)

    -- Engine events

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
    self.m_FireEffectBlueprint = nil
    self.m_EffectParams = EffectParams()

    -- Initialize all of the handles
    self.m_EffectHandles = { }

    self.m_Bundles = { }

    self.m_LevelName = ""
end

function BRClient:GetEffectBlueprint()
    -- Check to see if we already got the blueprint
    if self.m_FireEffectBlueprint ~= nil then
        return self.m_FireEffectBlueprint
    end

    -- Get the EffectBlueprint FX/Ambient/Generic/FireSmoke/Fire/Generic/FX_Amb_Generic_Fire_L_01
    s_FireEffectResource = ResourceManager:SearchForInstanceByGUID(Guid('392D298D-CD2D-498F-AF2E-2C2F5B2AF137'))
    if s_FireEffectResource == nil then
        print("could not find fire effect resource")
        return nil
    end

    print("get effect blueprint")
    s_FireEffectBlueprint = EffectBlueprint(s_FireEffectResource)
    if s_FireEffectBlueprint == nil then
        print("could not find fire effect blueprint")
        return nil
    end

    print("assigning the effect blueprint")
    self.m_FireEffectBlueprint = s_FireEffectBlueprint

    -- Modify the effect entity data
    local s_EffectEntityData = EffectEntityData(s_FireEffectBlueprint.object)
    if s_EffectEntityData == nil then
        print("err: could not get effect entity data")
        return s_FireEffectBlueprint
    end

    for _, l_EntityData in pairs(s_EffectEntityData.components) do
        -- Check to make sure we have a valid entity data
        if l_EntityData == nil then
            goto emitter_entity_data_continue
        end

        -- We only want the emitter entity datas
        if l_EntityData.typeInfo.name ~= "EmitterEntityData" then
            goto emitter_entity_data_continue
        end

        local l_EmitterEntityData = EmitterEntityData(l_EntityData)

        -- Get the emitter document
        local l_EmitterDocument = EmitterDocument(l_EmitterEntityData.emitter)
        if l_EmitterDocument == nil then
            print("err: could not get emitter document")
            goto emitter_entity_data_continue
        end

        local l_Emitter = EmitterTemplateData(l_EmitterDocument.templateData)
        if l_Emitter == nil then
            print("err: could not get emitter template data")
            goto emitter_entity_data_continue
        end

        -- Make this emitter writable
        l_Emitter:MakeWritable()

        -- Change the maximum count of this emitter
        --l_Emitter.maxCount = 91

        print("changed emitter: " .. l_Emitter.name .. " max count to: " .. l_Emitter.maxCount)

        ::emitter_entity_data_continue::
    end

    return s_FireEffectBlueprint
end

-- TODO: Get the instance of the fire
-- if not then import it from metro
-- then after that we need to work on kit unlocks
-- then after that we need to work on spawning kits
-- then after that we need to disable the respawn ability server side
-- then we implement the fadein/fadeout
-- then we need to implement the end game
-- do we throw some extra ric-flair on it with a plane sequence?

function BRClient:StopPlayingAllEffects()
    EffectManager:Clear()
    self.m_EffectHandles = { }
end


function BRClient:OnUpdateRadius(p_NewRadius, p_NewPosition, p_NumPoints)
    --print("Updating radius size to: " .. p_NewRadius .. " at: " .. p_NewPosition.x .. " " .. p_NewPosition.y .. " " .. p_NewPosition.z .. "numPoints: " .. p_NumPoints)
    --print(self.m_CurrentRingNumPoints)

    -- Update the current radius
    self.m_CurrentRingRadius = p_NewRadius
    self.m_CurrentRingPosition = p_NewPosition

    -- We only want to proceed if the effect is found
    local s_EffectBlueprint = self:GetEffectBlueprint()
    if s_EffectBlueprint == nil then
        return
    end

    -- Check to see if we need to re-create the effects
    if self.m_CurrentRingNumPoints ~= p_NumPoints then
        self:StopPlayingAllEffects()

        for l_EffectIndex = 1, p_NumPoints do
            -- Raycase from above our point to try and find the proper Y coordinate
            local l_Vec = self:GetRaycastPosition(l_EffectIndex)

            -- Create a new transform for spawning the effect
            local l_Transform = LinearTransform()
            l_Transform.trans = l_Vec

            -- Play the effect
            --print("playing effect at x: " .. l_Vec.x .. " y: " .. l_Vec.y .. " z: " .. l_Vec.z)
            local l_EffectHandle = EffectManager:PlayEffect(self.m_FireEffectBlueprint, l_Transform, self.m_EffectParams, true)
            if EffectManager:IsEffectPlaying(l_EffectHandle) == false then
                print("could not play effect")
                goto effect_continue
            end

            -- Save the effect handle to our array of effects
            --print("updating idx: " .. l_EffectIndex .. " with handle:" .. l_EffectHandle)
            self.m_EffectHandles[l_EffectIndex] = l_EffectHandle

            dsadsad = self.m_EffectHandles[l_EffectIndex]
            if dsadsad == nil then
                print("nil nil nil nil nil")
            end

            ::effect_continue::
        end

        self.m_CurrentRingNumPoints = p_NumPoints
    else
        -- Move existing effects
        for l_EffectIndex = 1, self.m_CurrentRingNumPoints do
            local l_Vec = self:GetRaycastPosition(l_EffectIndex)

            local l_Transform = LinearTransform()
            l_Transform.trans = l_Vec

            -- Get the effect handle
            --print(self.m_EffectHandles)
            local l_EffectHandle = self.m_EffectHandles[l_EffectIndex]
            if l_EffectHandle == nil then
                print("could not update transform idx: " .. l_EffectIndex)
                goto effect_transform_continue
            end

            -- Move the effect to the new coordinates
            --print("moving effect to x: " .. l_Vec.x .. " y: " .. l_Vec.y .. " z: " .. l_Vec.z)
            EffectManager:SetEffectTransform(l_EffectHandle, l_Transform)

            ::effect_transform_continue::
        end
    end

end

function BRClient:OnUpdateState(p_AlivePlayersLeft, p_TeamsLeft, p_RoundNumber, p_CircleStatus)
    -- Update the state provided by the server
    self.m_PlayersLeft = p_AlivePlayersLeft
    self.m_TeamsLeft = p_TeamsLeft
    self.m_RoundNumber = p_RoundNumber
    self.m_CurrentRingStatus = p_CircleStatus
end

function BRClient:GetRaycastPosition(p_RingIndex)
    -- Get the x,z coordinate
    s_Location = self:GetPoint(self.m_CurrentRingPosition, p_RingIndex, self.m_CurrentRingNumPoints, self.m_CurrentRingRadius)
    if s_Location == nil then
        print("location is nil")
    end

    --print(s_Location)

    -- Place the raycast start location up higher on the y coordinate
    s_RaycastStartLocation = s_Location
    s_RaycastStartLocation.y = s_RaycastStartLocation.y

    -- Place the end raycast point below our requested height
    s_RaycastEndLocation = s_Location
    s_RaycastEndLocation.y = s_RaycastStartLocation.y

    -- Do the actual raycast
    s_Hit = RaycastManager:Raycast(s_RaycastStartLocation, s_RaycastEndLocation, RayCastFlags.CheckDetailMesh | RayCastFlags.DontCheckCharacter)
    if s_Hit == nil then
        return s_Location
    end

    -- Get the hit position
    s_HitPosition = s_Hit.position
    --print("hit position: " .. s_HitPosition.x .. " " .. s_HitPosition.y .. " " .. s_HitPosition.z)

    -- Return the position
    return s_HitPosition
end

function BRClient:GetPoint(p_Position, p_CircleIndex, p_NumPoints, p_CurrentRadius)
    local s_Slice = (2 * math.pi) / p_NumPoints

    local s_Angle = s_Slice * p_CircleIndex

    local s_X = p_Position.x + p_CurrentRadius * math.cos(s_Angle)
    local s_Z = p_Position.z + p_CurrentRadius * math.sin(s_Angle)

    return Vec3(s_X, p_Position.y, s_Z)
end

return BRClient()