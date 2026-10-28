#include "$CurrentDir:mpmissions/servahz.chernarusplus/servahz_refresh/Policy.c"

class ServahzLootRefreshRequest
{
    int Schema;
    string RequestId;
    float CenterX;
    float CenterZ;
    float Radius;
    bool PreviewOnly = true;
    string PreviewRequestId;
    string PolicyHash;
    string BackupPath;
    ref array<string> AllowedTypes;
}

class ServahzLootRefreshReport
{
    string RequestId;
    string PolicyHash;
    string Status;
    bool PreviewOnly;
    float CenterX;
    float CenterZ;
    float Radius;
    int Cells;
    int Candidates;
    int Deleted;
    int Protected;
    string Message;
    ref array<string> Samples = new array<string>;
}

class ServahzLootRefresh
{
    protected ref ServahzLootRefreshRequest m_Request;
    protected ref ServahzLootRefreshReport m_Report;
    protected ref map<string, bool> m_Allowed = new map<string, bool>;
    protected ref map<Object, bool> m_Seen = new map<Object, bool>;
    protected int m_Cell;
    protected string m_ReportPath = "$profile:Servahz/LootRefresh-report.json";

    bool SaveReport(string status, string message)
    {
        m_Report.Status = status;
        m_Report.Message = message;
        string error;
        if (!JsonFileLoader<ServahzLootRefreshReport>.SaveFile(m_ReportPath, m_Report, error))
        {
            Print("[ServahzLootRefresh] Report failed; stopping: " + error);
            return false;
        }
        return true;
    }

    bool PlayersPresent()
    {
        array<Man> players = new array<Man>;
        GetGame().GetPlayers(players);
        foreach (Man candidate : players)
        {
            PlayerBase human = PlayerBase.Cast(candidate);
            if (human && human.GetIdentity())
                return true;
        }
        return false;
    }

    void Begin()
    {
        if (!GetCEApi())
            return;
        string requestPath = "$profile:Servahz/LootRefresh-request.json";
        if (!FileExist(requestPath))
            return;
        string error;
        if (!JsonFileLoader<ServahzLootRefreshRequest>.LoadFile(requestPath, m_Request, error))
        {
            Print("[ServahzLootRefresh] Invalid request; no changes: " + error);
            return;
        }
        string world;
        GetGame().GetWorldName(world);
        world.ToLower();
        if (!m_Request || m_Request.Schema != 1 || world != "chernarusplus")
            return;
        if (m_Request.CenterX <= 0 || m_Request.CenterX >= 15360 || m_Request.CenterZ <= 0 || m_Request.CenterZ >= 15360 || m_Request.Radius < 500 || m_Request.Radius > 5000)
            return;
        if (m_Request.RequestId.Length() != 32 || m_Request.PolicyHash.Length() != 64 || !m_Request.AllowedTypes || m_Request.AllowedTypes.Count() == 0 || m_Request.BackupPath == "")
            return;
        string validHex = "0123456789abcdef";
        for (int index = 0; index < m_Request.RequestId.Length(); index++)
        {
            if (validHex.IndexOf(m_Request.RequestId.Substring(index, 1)) < 0)
                return;
        }
        if (!m_Request.PreviewOnly)
        {
            ServahzLootRefreshReport preview;
            if (!JsonFileLoader<ServahzLootRefreshReport>.LoadFile(m_ReportPath, preview, error))
                return;
            if (!preview || preview.Status != "PreviewCompleted" || !preview.PreviewOnly || preview.RequestId != m_Request.PreviewRequestId || preview.PolicyHash != m_Request.PolicyHash)
                return;
            if (preview.CenterX != m_Request.CenterX || preview.CenterZ != m_Request.CenterZ || preview.Radius != m_Request.Radius)
                return;
        }
        // Claim once BEFORE any scan/deletion. A crash or interrupted scan is not
        // automatically retried on the next startup; queue a fresh preview instead.
        string claimed = "$profile:Servahz/LootRefresh-" + m_Request.RequestId + ".started";
        if (FileExist(claimed))
            return;
        FileHandle handle = OpenFile(claimed, FileMode.WRITE);
        if (!handle)
            return;
        FPrintln(handle, m_Request.RequestId);
        CloseFile(handle);
        m_Report = new ServahzLootRefreshReport;
        m_Report.RequestId = m_Request.RequestId;
        m_Report.PolicyHash = m_Request.PolicyHash;
        m_Report.PreviewOnly = m_Request.PreviewOnly;
        m_Report.CenterX = m_Request.CenterX;
        m_Report.CenterZ = m_Request.CenterZ;
        m_Report.Radius = m_Request.Radius;
        foreach (string typeName : m_Request.AllowedTypes)
            m_Allowed.Insert(typeName, true);
        if (!SaveReport("Running", "Scanning in batches. Do not join the server."))
            return;
        Tick();
    }

    void Tick()
    {
        if (PlayersPresent())
        {
            SaveReport("Aborted", "A player joined. Queue a new preview with the server stopped.");
            Print("[ServahzLootRefresh] Aborted: player online.");
            return;
        }
        if (m_Cell >= 225)
        {
            string completed = "PreviewCompleted";
            if (!m_Request.PreviewOnly)
                completed = "ApplyCompleted";
            if (SaveReport(completed, "Normal Central Economy refill supplies the new loot."))
                PrintFormat("[ServahzLootRefresh] %1 candidates=%2 deleted=%3 protected=%4", completed, m_Report.Candidates, m_Report.Deleted, m_Report.Protected);
            m_Seen.Clear();
            return;
        }
        // Chernarus is 15360m square. A horizontal circle covers all elevations;
        // 15x15 cells at 1024m spacing, radius 800m, overlap at their corners.
        int row = m_Cell / 15;
        int column = m_Cell % 15;
        vector center = Vector(column * 1024 + 512, 0, row * 1024 + 512);
        array<Object> objects = new array<Object>;
        array<CargoBase> proxies = new array<CargoBase>;
        GetGame().GetObjectsAtPosition(center, 800, objects, proxies);
        foreach (Object obj : objects)
        {
            ItemBase item = ItemBase.Cast(obj);
            if (!item || !item.GetInventory() || !m_Allowed.Contains(item.GetType()) || m_Seen.Contains(obj))
                continue;
            m_Seen.Insert(obj, true);
            bool hasParent = item.GetHierarchyParent() != null;
            bool hasStorage = item.GetInventory().GetCargo() != null;
            array<EntityAI> descendants = new array<EntityAI>;
            item.GetInventory().EnumerateInventory(InventoryTraversalType.PREORDER, descendants);
            foreach (EntityAI descendant : descendants)
            {
                if (descendant && descendant.GetInventory() && descendant.GetInventory().GetCargo())
                {
                    hasStorage = true;
                    break;
                }
                // Keep the whole root if an attachment lies across the protected
                // boundary, even when the root itself is just outside the circle.
                if (descendant && !ServahzLootRefreshPolicy.MayDelete(descendant.GetPosition(), m_Request.CenterX, m_Request.CenterZ, m_Request.Radius, true, false, false))
                {
                    hasStorage = true;
                    break;
                }
            }
            if (!ServahzLootRefreshPolicy.MayDelete(item.GetPosition(), m_Request.CenterX, m_Request.CenterZ, m_Request.Radius, true, hasParent, hasStorage))
            {
                m_Report.Protected++;
                continue;
            }
            m_Report.Candidates++;
            if (m_Report.Samples.Count() < 50)
                m_Report.Samples.Insert(item.GetType() + " @ " + item.GetPosition().ToString());
            // Preview passes through the identical safety gate but never deletes.
            if (!m_Request.PreviewOnly)
            {
                GetGame().ObjectDelete(item);
                m_Report.Deleted++;
            }
        }
        m_Cell++;
        m_Report.Cells = m_Cell;
        if (!SaveReport("Running", "Scanning in batches. Do not join the server."))
            return;
        GetGame().GetCallQueue(CALL_CATEGORY_SYSTEM).CallLater(Tick, 200, false);
    }
}

class ServahzRefreshMission: CustomMission
{
    protected ref ServahzLootRefresh m_ServahzRefresh;
    override void OnInit()
    {
        super.OnInit();
        m_ServahzRefresh = new ServahzLootRefresh;
        GetGame().GetCallQueue(CALL_CATEGORY_SYSTEM).CallLater(m_ServahzRefresh.Begin, 120000, false);
    }
}
