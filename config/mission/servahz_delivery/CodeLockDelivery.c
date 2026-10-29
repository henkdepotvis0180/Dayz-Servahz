#include "$CurrentDir:mpmissions/servahz.chernarusplus/servahz_refresh/LootRefresh.c"
#include "$CurrentDir:mpmissions/servahz.chernarusplus/servahz_delivery/Policy.c"

class ServahzCodeLockRequest
{
    int Schema;
    string RequestId;
    string SteamId;
}

class ServahzCodeLockReceipt
{
    string RequestId;
    string Status;
    bool BatteryAttached;
}

class ServahzCodeLockDelivery
{
    protected ref ServahzCodeLockRequest m_Request;
    protected string m_ClaimPath;

    bool IsDigits(string value, int length)
    {
        string digits = "0123456789";
        if (value.Length() != length)
            return false;
        for (int i = 0; i < value.Length(); i++)
        {
            if (digits.IndexOf(value.Substring(i, 1)) < 0)
                return false;
        }
        return true;
    }

    bool IsRequestId(string value)
    {
        string hex = "0123456789abcdef";
        if (value.Length() != 32)
            return false;
        for (int i = 0; i < value.Length(); i++)
        {
            if (hex.IndexOf(value.Substring(i, 1)) < 0)
                return false;
        }
        return true;
    }

    void Receipt(string status, bool battery = false)
    {
        ServahzCodeLockReceipt receipt = new ServahzCodeLockReceipt;
        receipt.RequestId = m_Request.RequestId;
        receipt.Status = status;
        receipt.BatteryAttached = battery;
        string error;
        if (!JsonFileLoader<ServahzCodeLockReceipt>.SaveFile("$profile:Servahz/CodeLockDelivery-report.json", receipt, error))
            Print("[ServahzCodeLockDelivery] Receipt could not be written; automatic repeat remains blocked.");
        Print("[ServahzCodeLockDelivery] " + status);
    }

    void Begin()
    {
        if (!GetGame().IsServer() || !FileExist("$profile:Servahz/CodeLockDelivery-request.json"))
            return;
        string error;
        if (!JsonFileLoader<ServahzCodeLockRequest>.LoadFile("$profile:Servahz/CodeLockDelivery-request.json", m_Request, error))
        {
            Print("[ServahzCodeLockDelivery] Invalid request; nothing delivered.");
            return;
        }
        if (!m_Request || m_Request.Schema != 1 || !IsRequestId(m_Request.RequestId) || !IsDigits(m_Request.SteamId, 17))
            return;
        m_ClaimPath = "$profile:Servahz/CodeLockDelivery-" + m_Request.RequestId + ".started";
        if (FileExist(m_ClaimPath))
            return;
        if (!GetGame().ConfigIsExisting("CfgVehicles DigitalCodeLock"))
        {
            Receipt("MissingClass");
            return;
        }
        Tick();
    }

    void Tick()
    {
        if (FileExist(m_ClaimPath))
            return;
        array<Man> players = new array<Man>;
        GetGame().GetPlayers(players);
        PlayerBase recipient;
        int matchingPlayers = 0;
        foreach (Man candidate : players)
        {
            PlayerBase human = PlayerBase.Cast(candidate);
            if (human && human.GetIdentity() && human.GetIdentity().GetPlainId() == m_Request.SteamId)
            {
                recipient = human;
                matchingPlayers++;
            }
        }
        bool alive = recipient && recipient.IsAlive();
        if (!ServahzDeliveryPolicy.MayDeliver(m_Request.Schema, IsRequestId(m_Request.RequestId), IsDigits(m_Request.SteamId, 17), GetGame().ConfigIsExisting("CfgVehicles DigitalCodeLock"), FileExist(m_ClaimPath), matchingPlayers, alive))
        {
            GetGame().GetCallQueue(CALL_CATEGORY_SYSTEM).CallLater(Tick, 5000, false);
            return;
        }
        // Claim before inventory creation. A crash never gives a second item
        // automatically, even if the receipt or the next world save is missing.
        FileHandle handle = OpenFile(m_ClaimPath, FileMode.WRITE);
        if (!handle)
            return;
        FPrintln(handle, m_Request.RequestId);
        CloseFile(handle);
        EntityAI delivered = recipient.GetInventory().CreateInInventory("DigitalCodeLock");
        if (!delivered)
        {
            Receipt("NoInventorySpace");
            return;
        }
        EntityAI battery = delivered.GetInventory().CreateAttachment("Battery9V");
        Receipt("Delivered", battery != null);
    }
}

class ServahzDeliveryMission: ServahzRefreshMission
{
    protected ref ServahzCodeLockDelivery m_ServahzDelivery;
    override void OnInit()
    {
        super.OnInit();
        m_ServahzDelivery = new ServahzCodeLockDelivery;
        GetGame().GetCallQueue(CALL_CATEGORY_SYSTEM).CallLater(m_ServahzDelivery.Begin, 10000, false);
    }
}
