// Servahz: replace building logs/lumber with planks; retain existing entity/part IDs.
class CfgPatches
{
    class Servahz_Planks
    {
        units[] = {};
        weapons[] = {};
        requiredVersion = 0.1;
        requiredAddons[] = {"DayZExpansion_Objects_BaseBuilding_Walls", "DayZExpansion_Objects_BaseBuilding_Floors", "DayZExpansion_Objects_BaseBuilding_Stairs", "DayZExpansion_Objects_BaseBuilding_Ramps", "DZ_Gear_Camping", "BuildingFortifications"};
    };
};
class CfgVehicles
{
    class ExpansionBaseBuilding;
    class ExpansionWallBase: ExpansionBaseBuilding
    {
        class Construction
        {
            class interact
            {
                class wood_base
                {
                    class Materials
                    {
                        class Material1
                        {
                            type = "WoodenPlank";
                            slot_name = "Material_WoodenPlanks";
                            quantity = 4;
                        };
                    };
                };
                class wood_base_half
                {
                    class Materials
                    {
                        class Material1
                        {
                            type = "WoodenPlank";
                            slot_name = "Material_WoodenPlanks";
                            quantity = 4;
                        };
                    };
                };
                class wood_base_third
                {
                    class Materials
                    {
                        class Material1
                        {
                            type = "WoodenPlank";
                            slot_name = "Material_WoodenPlanks";
                            quantity = 4;
                        };
                    };
                };
            };
        };
    };
    class ExpansionFloorBase: ExpansionBaseBuilding
    {
        class Construction
        {
            class interact
            {
                class wood_base
                {
                    class Materials
                    {
                        class Material1
                        {
                            type = "WoodenPlank";
                            slot_name = "Material_WoodenPlanks";
                            quantity = 8;
                        };
                    };
                };
            };
        };
    };
    class ExpansionFloor6x6: ExpansionFloorBase
    {
        class Construction: Construction
        {
            class interact: interact
            {
                class wood_base
                {
                    class Materials
                    {
                        class Material1
                        {
                            type = "WoodenPlank";
                            slot_name = "Material_WoodenPlanks";
                            quantity = 8;
                        };
                    };
                };
            };
        };
    };
    class ExpansionStairBase: ExpansionBaseBuilding
    {
        class Construction
        {
            class interact
            {
                class wood_base
                {
                    class Materials
                    {
                        class Material1
                        {
                            type = "WoodenPlank";
                            slot_name = "Material_WoodenPlanks";
                            quantity = 8;
                        };
                    };
                };
            };
        };
    };
    class ExpansionRampBase: ExpansionBaseBuilding
    {
        class Construction
        {
            class interact
            {
                class wood_base
                {
                    class Materials
                    {
                        class Material1
                        {
                            type = "WoodenPlank";
                            slot_name = "Material_WoodenPlanks";
                            quantity = 4;
                        };
                    };
                };
            };
        };
    };
    class Inventory_Base;
    class WoodenPlank: Inventory_Base
    {
        inventorySlot[] += {"Material_WoodenLogs", "Material_L1_WoodenLogs", "Material_L2_WoodenLogs", "Material_L3_WoodenLogs", "Material_FPole_WoodenLog", "Material_FPole_WoodenLog2", "Material_FPole_MagicStick"};
    };
    class BaseBuildingBase;
    class BuildingFortficationsCore;
    class Fence: BaseBuildingBase
    {
        class Construction
        {
            class wall
            {
                class base
                {
                    class Materials
                    {
                        class Material1
                        {
                            type = "WoodenPlank";
                            slot_name = "Material_WoodenLogs";
                            quantity = 4;
                            lockable = 0;
                        };
                    };
                };
            };
        };
    };
    class Watchtower: BaseBuildingBase
    {
        class Construction
        {
            class level_1
            {
                class level_1_base
                {
                    class Materials
                    {
                        class Material1
                        {
                            type = "WoodenPlank";
                            slot_name = "Material_L1_WoodenLogs";
                            quantity = 8;
                            lockable = 0;
                        };
                    };
                };
            };
            class level_2
            {
                class level_2_base
                {
                    class Materials
                    {
                        class Material1
                        {
                            type = "WoodenPlank";
                            slot_name = "Material_L2_WoodenLogs";
                            quantity = 8;
                            lockable = 0;
                        };
                    };
                };
            };
            class level_3
            {
                class level_3_base
                {
                    class Materials
                    {
                        class Material1
                        {
                            type = "WoodenPlank";
                            slot_name = "Material_L3_WoodenLogs";
                            quantity = 8;
                            lockable = 0;
                        };
                    };
                };
            };
        };
    };
    class TerritoryFlag: BaseBuildingBase
    {
        class Construction
        {
            class totem
            {
                class base
                {
                    class Materials
                    {
                        class Material1
                        {
                            type = "WoodenPlank";
                            slot_name = "Material_FPole_WoodenLog";
                            quantity = 2;
                            lockable = 0;
                        };
                    };
                };
                class support
                {
                    class Materials
                    {
                        class Material2
                        {
                            type = "WoodenPlank";
                            slot_name = "Material_FPole_WoodenLog2";
                            quantity = 12;
                            lockable = 0;
                        };
                    };
                };
                class pole
                {
                    class Materials
                    {
                        class Material4
                        {
                            type = "WoodenPlank";
                            slot_name = "Material_FPole_MagicStick";
                            quantity = 6;
                            lockable = 0;
                        };
                    };
                };
            };
        };
    };
    class BF_DoorBarricade: BuildingFortficationsCore
    {
        class Construction
        {
            class wall
            {
                class a_base
                {
                    class Materials
                    {
                        class Material1
                        {
                            type = "WoodenPlank";
                            slot_name = "Material_WoodenLogs";
                            quantity = 4;
                            lockable = 0;
                        };
                    };
                };
            };
        };
    };
    class BF_DoubleDoorBarricade: BuildingFortficationsCore
    {
        class Construction
        {
            class wall
            {
                class a_base
                {
                    class Materials
                    {
                        class Material1
                        {
                            type = "WoodenPlank";
                            slot_name = "Material_WoodenLogs";
                            quantity = 4;
                            lockable = 0;
                        };
                    };
                };
            };
        };
    };
};
class CfgMods
{
    class Servahz_Planks
    {
        dir = "Servahz/Planks";
        name = "Servahz Planken";
        type = "mod";
        dependencies[] = {"World"};
        class defs
        {
            class worldScriptModule
            {
                value = "";
                files[] = {"Servahz/Planks/Scripts/4_World"};
            };
        };
    };
};
