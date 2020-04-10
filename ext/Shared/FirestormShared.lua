class "FirestormShared"

G_RING_STATIONARY = 0
G_RING_CLOSING = 1

function FirestormShared:__init()
    
end

-- Vec3 GetPoint([Vec3] p_Position, [int] p_CircleIndex, [int] p_NumPoints, [float] p_CurrentRadius)
function FirestormShared:GetPoint(p_Position, p_CircleIndex, p_NumPoints, p_CurrentRadius)
    local s_Slice = (2 * math.pi) / p_NumPoints

    local s_Angle = s_Slice * p_CircleIndex

    local s_X = p_Position.x + p_CurrentRadius * math.cos(s_Angle)
    local s_Z = p_Position.z + p_CurrentRadius * math.sin(s_Angle)

    return Vec3(s_X, p_Position.y, s_Z)
end

return FirestormShared()