// Vanilla Fence rejects every non-log item before its base is built.
// Allow only planks in that one foundation slot; retain all lock/gate rules.
modded class Fence
{
    override bool CanReceiveAttachment(EntityAI attachment, int slotId)
    {
        if (!HasBase() && attachment && attachment.IsKindOf("WoodenPlank") && slotId == InventorySlots.GetSlotIdFromString("Material_WoodenLogs"))
            return true;
        return super.CanReceiveAttachment(attachment, slotId);
    }
};
