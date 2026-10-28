// Object-free safety gate, shared by preview and execution. Distance is horizontal.
class ServahzLootRefreshPolicy
{
    static bool MayDelete(vector position, float centerX, float centerZ, float radius, bool allowedType, bool hasParent, bool hasStorage)
    {
        float dx = position[0] - centerX;
        float dz = position[2] - centerZ;
        if (dx * dx + dz * dz <= radius * radius)
            return false;
        if (!allowedType || hasParent || hasStorage)
            return false;
        return true;
    }
}
