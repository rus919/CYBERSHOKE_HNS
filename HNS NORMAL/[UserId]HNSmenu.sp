#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <cstrike>
#include <csgo_colors>

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

    menu.AddItem("0", "Правила");
    menu.AddItem("1", "HNS RANK");
    menu.AddItem("2", "Настройки");
    menu.AddItem("3", "Моя статистика прыжков");
    menu.AddItem("4", "статистика прыжков");
    menu.AddItem("5", "Скрыть/Показ ножа");
    menu.AddItem("6", "вид от третьего лица");
    menu.AddItem("7", "Настройки Луча");
    menu.AddItem("8", "Сбросить Rank");


	menu.ExitButton = true;
	menu.Display(client, 30);
}

bool IsValidClient(int client) {
	return (0 < client <= MaxClients && IsClientInGame(client));
}

void AREYOUSURE(int client){

    Menu menu = new Menu(AREYOUSUREHANDLER);
    menu.SetTitle("Вы точно уверены?");

    menu.AddItem("0", "Да");
    menu.AddItem("1", "Нет");
    menu.AddItem("2", "Вернуть ранг невозможно!", ITEMDRAW_DISABLED );


    menu.ExitButton = false;
	menu.Display(client, 0);

}

public int AREYOUSUREHANDLER(Menu menu, MenuAction action, int client, int select){

 if(action == MenuAction_Select && IsValidClient(client))
    {
        switch(select)
        {
            case 0: 
            {
                CPrintToChat(client, "{green}CYBBERSHOKE {default}| Вы успешно сбросили RANK");
                ClientCommand(client, "sm_resetrank");

            }
            case 1:
            {
                CPrintToChat(client, "{green}CYBBERSHOKE {default}| Вы отказались сбрасывать RANK");
                delete menu;
            }
        }
    }
    if(action == MenuAction_End)
	    delete menu;
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
            case 8:
            {
                AREYOUSURE(client);
                return;
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