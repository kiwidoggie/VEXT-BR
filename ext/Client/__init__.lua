class "BRClient"


function BRClient:__init()
    -- Debug output
    print("Starting battle royale client")

    -- BR:RadiusUpdate([float] p_NewRadius, [Vec3] p_NewPosition)
    -- Subscribe to the server event
    self.m_RadiusUpdateEvent = NetEvents:Subscribe("BR:RingUpdate", self, self.OnUpdateRadius)
    self.m_UpdateStatsEvent = NetEvents:Subscribe("BR:GameStateUpdate", self, self.OnUpdateState)
    self.m_ExtensionLoadingEvent = Events:Subscribe("Extension:Loaded", self, self.OnExtensionLoaded)
    self.m_ExtensionUnloadingEvent = Events:Subscribe("Extension:Unloading", self, self.OnExtensionUnloading)
    self.m_LevelLoadingInfoEvent = Events:Subscribe("Level:LoadingInfo", self, self.OnLevelLoadingInfo)
    self.m_PartitionLoadedEvent = Events:Subscribe("Partition:Loaded", self, self.OnPartitionLoaded)
    self.m_LevelLoadResourceEvent = Events:Subscribe("Level:LoadResources", self, self.OnLoadResources)
    
    -- Hooks
    self.m_LoadBundlesHook = Hooks:Install("ResourceManager:LoadBundles", 100, self, self.OnLoadBundles)
    -- Debug Commands
    self.m_PrintPositionCommand = Console:Register("PrintPos", "Prints player position", function(p_Args)
        local s_LocalPlayer = PlayerManager:GetLocalPlayer()
        if s_LocalPlayer == nil then
            return "invalid player"
        end

        local s_LocalSoldier = s_LocalPlayer.soldier
        if s_LocalSoldier == nil then
            return "invalid soldier"
        end

        local s_LocalPos = s_LocalSoldier.position

        return "xyz: " .. s_LocalPos.x .. ", " .. s_LocalPos.y .. ", " .. s_LocalPos.z
    end)
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

    self.m_Ready = false

    -- Seriously frostbite >_>
    self.m_LazyLoadedIds = { }
end

function BRClient:OnLoadBundles(p_Hook, p_Bundles, p_Compartment)
    --[[if #bundles == 1 and 
        bundles[1] == SharedUtils:GetLevelName() and 
        SharedUtils:GetLevelName():find("Levels/MP_Subway") == nil then
            print("Injecting MP Bundles.")

            bundles = 
            {
                "Levels/MP_Subway/MP_Subway",
                "Levels/MP_Subway/DeathMatch",
                "Levels/MP_Subway/SquadDeathMatch",
                bundles[1],
            }
            
        end

        p_Hook:Pass(p_Bundles, p_Compartment)
    end--]]
end

function BRClient:OnLoadResources()
    --ResourceManager:MountSuperbundle("Levels/MP_Subway/MP_Subway")
end

function BRClient:OnLevelLoadingInfo(p_Info)
    if p_Info == "Loading done" then
        print("updating ready status")
        self.m_Ready = true
    elseif p_Info == "Level exited" then
        print("updating unready status")
        self.m_Ready = false
    end
end

function BRClient:OnExtensionLoaded()
end

function BRClient:OnPartitionLoaded(p_Partition)
    for _, l_Instance in pairs(p_Partition.instances) do
        if l_Instance == nil then
            goto instance_continue
        end

        -- Change the maximum amount of emitters
        if l_Instance.typeInfo.name == "EmitterTemplateData" then
            local l_EmitterTemplateData = EmitterTemplateData(l_Instance)

            l_EmitterTemplateData:MakeWritable()
            l_EmitterTemplateData.maxCount = 32
        end

        -- Check any of the lazy loaded guids
        for _, l_LazyLoadedId in pairs(self.m_LazyLoadedIds) do
            if l_LazyLoadedId == nil then
                goto lazy_loaded_id_continue
            end

            -- Check to see if this is one of the lazy loaded EmitterDocuments
            if l_Instance.instanceGuid == l_LazyLoadedId then
                -- I think this is how this works, not sure
                local l_EmitterDocument = EmitterDocument(l_Instance)
                if l_EmitterDocument ~= nil then
                    -- Get the emitter template data
                    local l_EmitterTemplateData = EmitterTemplateData(l_EmitterDocument.templateData)
                    if l_EmitterTemplateData ~= nil then
                        print("emitter name: " .. l_EmitterTemplateData.name)
                        l_EmitterTemplateData:MakeWritable()
                        l_EmitterTemplateData.maxCount = 32

                        print("changed emitter: " .. l_EmitterTemplateData.name .. " max count to: " .. l_EmitterTemplateData.maxCount)

                    end
                end
            end

            ::lazy_loaded_id_continue::
        end

        if l_Instance.instanceGuid == Guid("392D298D-CD2D-498F-AF2E-2C2F5B2AF137") then
            s_FireEffectBlueprint = EffectBlueprint(l_Instance)

            self.m_FireEffectBlueprint = s_FireEffectBlueprint

            -- Modify the effect entity data
            local s_EffectEntityData = EffectEntityData(s_FireEffectBlueprint.object)
            if s_EffectEntityData ~= nil then
                s_EffectEntityData:MakeWritable()
                s_EffectEntityData.cullDistance = 9999.9
                s_EffectEntityData.maxInstanceCount = 32
            end

            for _, l_EntityData in pairs(s_EffectEntityData.components) do
                -- Check to make sure we have a valid entity data
                if l_EntityData ~= nil then
                    -- We only want the emitter entity datas
                    if l_EntityData.typeInfo.name == "EmitterEntityData" then
                        -- Cast the untyped entity data to something we can use
                        local l_EmitterEntityData = EmitterEntityData(l_EntityData)
                        l_EmitterEntityData:MakeWritable()

                        l_EmitterEntityData.maxInstanceCount = 32

                        -- Get the emitter document, this is lazy loaded
                        local l_EmitterDocumentId = l_EmitterEntityData.emitter.instanceGuid
                        table.insert(self.m_LazyLoadedIds, l_EmitterDocumentId)
                        print("Added EmitterDocument to list of lazy loaded ids")
                    end
                end
            end
        end
            ::instance_continue::
    end

    local s_EmitterSystemSettingsContainer = ResourceManager:GetSettings("EmitterSystemSettings")
    if s_EmitterSystemSettingsContainer ~= nil then
        local s_EmitterSystemSettings = EmitterSystemSettings(s_EmitterSystemSettingsContainer)
        s_EmitterSystemSettings.meshDrawCountLimit = 32
        --print("info: updated the emitter settings mesh draw count limit")
    end
end

function BRClient:OnExtensionUnloading()
    -- Stop all of the fire effects and clear them out
    self:StopPlayingAllEffects()
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

    if self.m_Ready == false then
        return
    end

    -- We only want to proceed if the effect is found
    local s_EffectBlueprint = self.m_FireEffectBlueprint
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
            --print("fireeffectblueprint: " .. self.m_FireEffectBlueprint)
            --print("effectparams: " .. self.m_EffectParams)
            local l_EffectHandle = EffectManager:PlayEffect(self.m_FireEffectBlueprint, l_Transform, self.m_EffectParams, true)
            print("effectHandle: " .. l_EffectHandle)
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

    --print("status: " .. p_CircleStatus .. " radius: " .. self.m_CurrentRingRadius)
end

function BRClient:GetRaycastPosition(p_RingIndex)
    -- Get the x,z coordinate
    local s_Location = FirestormShared.GetPoint(self.m_CurrentRingPosition, p_RingIndex, self.m_CurrentRingNumPoints, self.m_CurrentRingRadius)
    if s_Location == nil then
        print("location is nil")
    end

    --print(s_Location)

    -- Place the raycast start location up higher on the y coordinate
    local s_RaycastStartLocation = s_Location
    s_RaycastStartLocation.y = s_RaycastStartLocation.y

    -- Place the end raycast point below our requested height
    local s_RaycastEndLocation = s_Location
    s_RaycastEndLocation.y = s_RaycastStartLocation.y

    -- Do the actual raycast
    local s_Hit = RaycastManager:Raycast(s_RaycastStartLocation, s_RaycastEndLocation, RayCastFlags.CheckDetailMesh | RayCastFlags.DontCheckCharacter)
    if s_Hit == nil then
        return s_Location
    end

    -- Get the hit position
    local s_HitPosition = s_Hit.position
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