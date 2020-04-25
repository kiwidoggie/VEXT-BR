FirestormShared = 
{
    G_RING_STATIONARY = 0,
    G_RING_CLOSING = 1,

    GAMESTATE_WARMUP = 0,
    GAMESTATE_INGAME = 1,
    GAMESTATE_GAMEOVER = 2,

    GetPoint = function(p_Position, p_CircleIndex, p_NumPoints, p_CurrentRadius)
        local s_Slice = (2 * math.pi) / p_NumPoints

        local s_Angle = s_Slice * p_CircleIndex

        local s_X = p_Position.x + p_CurrentRadius * math.cos(s_Angle)
        local s_Z = p_Position.z + p_CurrentRadius * math.sin(s_Angle)

        return Vec3(s_X, p_Position.y, s_Z)
    end
}