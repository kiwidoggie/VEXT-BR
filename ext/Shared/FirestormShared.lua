class "FirestormShared"

M_PI = 3.14159265358979323846264338327950288

G_RING_STATIONARY = 0
G_RING_CLOSING = 1

function FirestormShared:__init()
    
end

-- Vec3 GetPoint([Vec3] p_Position, [int] p_CircleIndex, [int] p_NumPoints, [float] p_CurrentRadius)
function FirestormShared:GetPoint(p_Position, p_CircleIndex, p_NumPoints, p_CurrentRadius)
    s_Slice = (2 * M_PI) / p_NumPoints

    s_Angle = s_Slice * p_CircleIndex

    s_X = p_Position.x + p_CurrentRadius * cos(s_Angle)
    s_Z = p_Position.z + p_CurrentRadius * sin(s_Angle)

    return Vec3(s_X, p_CurrentRadius.y, s_Z)
end

return FirestormShared()