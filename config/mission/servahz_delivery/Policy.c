class ServahzDeliveryPolicy
{
    static bool MayDeliver(int schema, bool validRequest, bool validRecipient, bool classExists, bool claimed, int matchingPlayers, bool alive)
    {
        return schema == 1 && validRequest && validRecipient && classExists && !claimed && matchingPlayers == 1 && alive;
    }
}
