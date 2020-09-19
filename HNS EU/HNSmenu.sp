#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <cstrike>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
    name = "HNSMENU",
    author = "Only",
    description = "HNS G MENU",
    version = "1.0",
    url = "CYBERSHOKE.NET"
}

public void OnPluginStart()
{
    RegConsoleCmd("sm_menu", Client_GMenu, "opens hns menu");

    AddCommandListener(Event_Drop, "drop"); // вызов меню
}

public Action Client_GMenu(int client, int args)
{
    GMenu(client);
	return Plugin_Handled;
}

void GMenu(int client)
{
    Menu menu = new Menu(GMenuHandler);
    menu.SetTitle("HNS Menu");

    menu.AddItem("0", "Rules", ITEMDRAW_DEFAULT);
    menu.AddItem("1", "HNS RANK", ITEMDRAW_DEFAULT);
    menu.AddItem("2", "Settings", ITEMDRAW_DEFAULT);
    menu.AddItem("3", "My jump statistics");
    menu.AddItem("4", "Jump statistics");
    menu.AddItem("5", "Hide/Show knife");
    menu.AddItem("6", "Thirdperson");
    menu.AddItem("7", "Beam settings");

	menu.ExitButton = true;
	menu.Display(client, 30);
}

bool IsValidClient(int client) {
	return (0 < client <= MaxClients && IsClientInGame(client));
}

public int GMenuHandler(Menu menu, MenuAction action, int client, int select)
{
    if(action == MenuAction_Select && IsValidClient(client))
    {
        switch(select)
        {
            case 0: 
            {
                ClientCommand(client, "sm_rules");
            }
            case 1:
            {
                ClientCommand(client, "sm_hnsrank");
            }
            case 2:
            {
                ClientCommand(client, "sm_js");
            }
            case 3:
            {
                ClientCommand(client, "sm_stats @me");
            }
            case 4:
            {
                ClientCommand(client, "sm_jt");
            }
            case 5:
            {
                ClientCommand(client, "sm_toggleknife");
            }
            case 6:
            {
                ClientCommand(client, "sm_thirdperson");
            }
            case 7:
            {
                ClientCommand(client, "sm_beam");
            }
            
        }
        GMenu(client);
    }
    if(action == MenuAction_End)
	    delete menu;
}

public Action Event_Drop(int client, const char[] command, int argc)
{
    GMenu(client);
    return Plugin_Handled;
}