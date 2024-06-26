#include <sourcemod>
#include <clientprefs>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#define CHATTAG "\x04[CYBERSHOKE]\x01 "

#pragma newdecls required
#pragma semicolon 1

Address g_iPatchAddress;

Handle g_hStyle = INVALID_HANDLE;

ConVar g_cvEnabled
		 , g_cvSwitchMap
		 , g_cvAlwaysFJ
		 , g_cvStylesAllowed
		 , g_cvAllowNoclip
		 , g_cvAllowTeleport
		 , g_cvAllowSpectate
		 , g_cvFJTime;

int g_iPatchRestore[100]
	, g_iPatchRestoreBytes
	, g_iEnabled
	, g_iSwitchMap
	, g_iAlwaysFJ
	, g_iStylesAllowed
	, g_iAllowNoclip
	, g_iAllowTeleport
	, g_iFJTime
	, g_iYesFJ
	, g_iNoFJ
	, g_iAllowSpectate;

float g_fOrigin[MAXPLAYERS+1][3]
		, g_fAngs[MAXPLAYERS+1][3];

bool g_bStylePre[MAXPLAYERS+1]
	 , g_bNoclip[MAXPLAYERS+1]
	 , g_bDidSave[MAXPLAYERS+1]
	 , g_bNoCollision;

public Plugin myinfo = {
	name = "HNS PRAC",
	author = "",
	description = "",
	version = "1.0",
	url = ""
}

public void OnPluginStart() {
	RegConsoleCmd("sm_hns", Client_FJ, "opens hns menu");

	g_cvEnabled = CreateConVar("fj_enabled", "1.0", "Set to enable/disable plugin, 1/0", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvSwitchMap = CreateConVar("fj_change_map", "0.0", "enable/disable the fj plugin from changing map once warmup is over 1/0", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvAlwaysFJ = CreateConVar("fj_fjonly", "1.0", "enable/disable every round being FJ round 1/0", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvStylesAllowed = CreateConVar("fj_styles", "0.0", "What styles are allowed, 2 for nopre only, 1 for pre only, 0 to allow clients to switch", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	g_cvAllowNoclip = CreateConVar("fj_noclip", "1.0", "Allow players noclip, 1 to allow, 0 to disable", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvAllowTeleport = CreateConVar("fj_teleport", "1.0", "Allow players to teleport, 1 to allow, 0 to disable", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvAllowSpectate = CreateConVar("fj_spectate", "1.0", "Allow players to switch teams between spectate and terrorist, 1 to allow, 0 to disable", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvFJTime = CreateConVar("fj_time", "30.0", "Time in minutes for players to fj, will set to warmup", FCVAR_NOTIFY, true, 0.0, true, 999.0);

	g_iEnabled = GetConVarInt(g_cvEnabled);
	HookConVarChange(g_cvEnabled, OnSettingChanged);
	g_iSwitchMap = GetConVarInt(g_cvSwitchMap);
	HookConVarChange(g_cvSwitchMap, OnSettingChanged);
	g_iAlwaysFJ = GetConVarInt(g_cvAlwaysFJ);
	HookConVarChange(g_cvAlwaysFJ, OnSettingChanged);
	g_iStylesAllowed = GetConVarInt(g_cvStylesAllowed);
	HookConVarChange(g_cvStylesAllowed, OnSettingChanged);
	g_iAllowNoclip = GetConVarInt(g_cvAllowNoclip);
	HookConVarChange(g_cvAllowNoclip, OnSettingChanged);
	g_iAllowTeleport = GetConVarInt(g_cvAllowTeleport);
	HookConVarChange(g_cvAllowTeleport, OnSettingChanged);
	//g_iAllowSpectate = GetConVarInt(g_cvAllowSpectate);
	//HookConVarChange(g_cvAllowSpectate, OnSettingChanged);
	g_iFJTime = GetConVarInt(g_cvFJTime);
	HookConVarChange(g_cvFJTime, OnSettingChanged);

	HookEvent("player_spawn", Event_PlayerSpawn);
	AddCommandListener(Event_Drop, "drop"); // вызов меню

	g_hStyle = RegClientCookie("StyleCookie", "Pre/Nopre style cookie", CookieAccess_Private);

	// Load the gamedata file.
	Handle hGameConf = LoadGameConfigFile("csgo_movement_unlocker.games");
	if(hGameConf == null)
		SetFailState("Can't find csgo_movement_unlocker.games.txt gamedata.");

	// Get the address near our patch area inside CGameMovement::WalkMove
	Address iAddr = GameConfGetAddress(hGameConf, "WalkMoveMaxSpeed");
	if(iAddr == Address_Null) {
		CloseHandle(hGameConf);
		SetFailState("Can't find WalkMoveMaxSpeed address.");
	}

	// Get the offset from the start of the signature to the start of our patch area.
	int iCapOffset = GameConfGetOffset(hGameConf, "CappingOffset");
	if(iCapOffset == -1) {
		CloseHandle(hGameConf);
		SetFailState("Can't find CappingOffset in gamedata.");
	}

	// Move right in front of the instructions we want to NOP.
	iAddr += view_as<Address>(iCapOffset);
	g_iPatchAddress = iAddr;

	// Get how many bytes we want to NOP.
	g_iPatchRestoreBytes = GameConfGetOffset(hGameConf, "PatchBytes");

	delete hGameConf;

	if(g_iPatchRestoreBytes == -1) {
		delete hGameConf;
		SetFailState("Can't find PatchBytes in gamedata.");
	}

	//PrintToServer("CGameMovement::WalkMove VectorScale(wishvel, mv->m_flMaxSpeed/wishspeed, wishvel); ... at address %x", g_iPatchAddress);

	for(int i = 0; i < g_iPatchRestoreBytes; i++) {
		// Save the current instructions, so we can restore them on unload.
		g_iPatchRestore[i] = LoadFromAddress(iAddr, NumberType_Int8);
		
		// NOP
		StoreToAddress(iAddr, 0x90, NumberType_Int8);
		
		iAddr++;
	}

	for(int i = MaxClients; i > 0; --i) {
		if(AreClientCookiesCached(i))
			OnClientPostAdminCheck(i);
	}

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i))
			OnClientPutInServer(i);
	}
}

public Action Event_Drop(int client, const char[] command, int argc)
{
	FJMenu(client);
    return Plugin_Handled;
}

public void OnMapStart() {
	if(g_iEnabled == 1 && g_iAlwaysFJ == 1)
		StartFJ();
}

public void Event_PlayerSpawn(Event hEvent, const char[] sEvName, bool bDontBroadcast)    // Функция будет вызвана когда на сервере произойдет событие player_spawn
{
    int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if(client)
	{
		FJMenu(client);
	}
}

public int OnSettingChanged(ConVar convar, char[] oldValue, char[] newValue) {
	if(convar == g_cvEnabled)
		g_iEnabled = StringToInt(newValue[0]);
	else if(convar == g_cvSwitchMap)
		g_iSwitchMap = StringToInt(newValue[0]);
	else if(convar == g_cvAlwaysFJ)
		g_iAlwaysFJ = StringToInt(newValue[0]);
	else if(convar == g_cvStylesAllowed)
		g_iStylesAllowed = StringToInt(newValue[0]);
	else if(convar == g_cvAllowNoclip)
		g_iAllowNoclip = StringToInt(newValue[0]);
	else if(convar == g_cvAllowTeleport)
		g_iAllowTeleport = StringToInt(newValue[0]);
	//else if(convar == g_cvAllowSpectate)
		//g_iAllowSpectate = StringToInt(newValue[0]);


	//else if(convar == g_cvFJTime)
		//g_iFJTime = StringToInt(newValue[0]);
}

public void OnClientPostAdminCheck(int client) {
	char sCookie[128];

	GetClientCookie(client, g_hStyle, sCookie, sizeof(sCookie));
	g_bStylePre[client] = (sCookie[0] != '\0' && StringToInt(sCookie));
}

public void OnPluginEnd() {
	// Restore the original instructions, if we patched them.
	UnpatchGame();
}

public void OnClientPutInServer(int client) {
	if(IsFakeClient(client) || g_iEnabled == 0)
		return;

	if(g_iStylesAllowed == 0 || g_iStylesAllowed == 1) {
		g_bStylePre[client] = true;
		char szValue[8];
		IntToString(g_bStylePre[client], szValue, 8);
		SetClientCookie(client, g_hStyle, szValue);
	}
	else {
		g_bStylePre[client] = false;
		char szValue[8];
		IntToString(g_bStylePre[client], szValue, 8);
		SetClientCookie(client, g_hStyle, szValue);
	}

	if(g_bNoCollision) {
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 2, 4, true);
	}

	g_bNoclip[client] = false;
	g_bDidSave[client] = false;

	SDKHook(client, SDKHook_PreThinkPost, Hook_PreThinkPost);
	SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
}

void StartFJ() {
	if(g_iEnabled == 0)
		return;

	int iTime = (g_iFJTime * 60);

	g_bNoCollision = true;

	for(int i = MaxClients; i > 0; --i) {
		if(IsValidClient(i)) {
			SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
			SetEntData(i, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 2, 4, true);
		}
	}

	float fTime = float(iTime);

	//CreateTimer(fTime, EndFJ, _, TIMER_FLAG_NO_MAPCHANGE);
	return;
}

/*public Action EndFJ(Handle timer) {
	PrintToServer("%sFJ Has ended", CHATTAG);
	g_bNoCollision = false;
	if(g_iSwitchMap == 1) {
		char szNextMap[256];
		GetNextMap(szNextMap, 256);
		ServerCommand("sm_map %s", szNextMap);
	}
	else // makes it so fj cant be used in normal play, only when fj wants >:D
		g_iEnabled = 0;

	return;
}*/

public Action Client_FJ(int client, int args) {
	if(g_iEnabled == 0)
		return Plugin_Handled;

	FJMenu(client);

	return Plugin_Handled;
}

public Action Admin_FJ(int client, int args) {
	if(g_iAlwaysFJ == 1 && g_iEnabled == 1) {
		ReplyToCommand(client, "%sNice try, we are already in FJ round!", CHATTAG);
		return Plugin_Handled;
	}

	StartFJ();

	return Plugin_Handled;
}

public Action Admin_VoteFJ(int client, int args) {
	if(g_iAlwaysFJ == 1 && g_iEnabled == 1) {
		ReplyToCommand(client, "%sNice try, we are already in FJ round!", CHATTAG);
		return Plugin_Handled;
	}

	g_iYesFJ = 0;
	g_iNoFJ = 0;

	CreateTimer(30.0, CheckFJVote);

	for(int i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			Menu menu = new Menu(VoteFJHandler);

			menu.SetTitle("Start FJ Round?");

			menu.AddItem("0", "Yes");
			menu.AddItem("1", "No");

			//menu.ExitButton = false;
			//menu.ExitBackButton = false;

			menu.Display(i, 30);
		}
	}

	return Plugin_Handled;
}

public int VoteFJHandler(Menu menu, MenuAction action, int client, int select) {\
	if(action == MenuAction_Select) {
		switch(select) {
			case 0: g_iYesFJ++;
			case 1: g_iNoFJ++;
		}
	}
	if(action == MenuAction_End) {
		delete menu;
	}
}

public Action CheckFJVote(Handle timer, int client) {
	int iVoteResult = 100 * (g_iYesFJ / (g_iNoFJ + g_iYesFJ));

	if(iVoteResult > 60) {
		PrintToChatAll("%sResults are in, %i%% (out of %i) voted yes, FJ round will start shortly.", CHATTAG, iVoteResult, (g_iYesFJ + g_iNoFJ));
		StartFJ();
	}
	else
		PrintToChatAll("%sResults are in, %i%% (out of %i) voted yes (60%+ needed for FJ), FJ round will not start", CHATTAG, iVoteResult, (g_iYesFJ + g_iNoFJ));

	return Plugin_Handled;
}

void FJMenu(int client) {
	Menu menu = new Menu(FJMenuHandler);
	menu.SetTitle("HNS Training");
	
	menu.AddItem("0", "Сохранить Позицию", g_iAllowTeleport == 1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DEFAULT);

	if(g_bDidSave[client])
		menu.AddItem("1", "Телепорт На Позицию", g_iAllowTeleport == 1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	else
		menu.AddItem("1", "Телепорт На Позицию", ITEMDRAW_DISABLED);

	//menu.AddItem("2", "Включить Noclip", g_iAllowNoclip == 1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	if(g_bNoclip[client])
		menu.AddItem("2", "Выключить Noclip", ITEMDRAW_DEFAULT);
	else
		menu.AddItem("2", "Включить Noclip", g_iAllowNoclip == 1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		
	menu.AddItem("3", "Скрыть Игроков", ITEMDRAW_DEFAULT);
	menu.AddItem("4", "Third Person", ITEMDRAW_DEFAULT);
	
	if(GetClientTeam(client) != CS_TEAM_SPECTATOR)
		menu.AddItem("5", "Наблюдать", g_iAllowSpectate == 1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DEFAULT);
	else
		menu.AddItem("5", "Вернуться в игру", g_iAllowSpectate == 1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DEFAULT);

	menu.AddItem("6", "Rank Меню", ITEMDRAW_DEFAULT);
	menu.AddItem("7", "Jump cmd", ITEMDRAW_DEFAULT);

	menu.AddItem("8", "Ljblock", ITEMDRAW_DEFAULT);
	menu.AddItem("9", "Beam", ITEMDRAW_DEFAULT);

	if(g_iStylesAllowed == 0) {
	if(g_bStylePre[client])
		menu.AddItem("10", "Style - [Pre]", ITEMDRAW_DEFAULT);
	else
		menu.AddItem("10", "Style - [NoPre]", ITEMDRAW_DEFAULT);
	}
	else if(g_iStylesAllowed == 1)
		menu.AddItem("10", "Style - [NoPre]", ITEMDRAW_DISABLED);
	else
		menu.AddItem("10", "Style - [Pre]", ITEMDRAW_DISABLED);

	menu.AddItem("11", "Открыть меню\n    Нажмите: G", ITEMDRAW_DISABLED);

	menu.ExitButton = true;
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	menu.Display(client, MENU_TIME_FOREVER);
}

public int FJMenuHandler(Menu menu, MenuAction action, int client, int select) 
{
	if(action == MenuAction_Select) 
	{
		switch(select) 
		{
			case 0: {
				SaveLocation(client);
				//PrintToChat(client, "\x01 \x04[CYBERSHOKE]\x01 Позиция сохранена", CHATTAG);
			}
			case 1: {
				Teleport(client);
				//PrintToChat(client, "\x01 \x04[CYBERSHOKE]\x01 Телепорт на позицию", CHATTAG);
			}
			case 2: {
				g_bNoclip[client] = !g_bNoclip[client];
			}
			case 3: {
				ClientCommand(client, "sm_hide");
			}
			case 4: {
				ClientCommand(client, "sm_tp");
			}
			case 5: 
			{
				if(GetClientTeam(client) != CS_TEAM_SPECTATOR) 
				{
					SaveLocation(client);
					ChangeClientTeam(client, CS_TEAM_SPECTATOR);
				}
				else 
				{
					ChangeClientTeam(client, CS_TEAM_T);
					CS_RespawnPlayer(client);
					Teleport(client);
				}
			}
			case 6: {
				ClientCommand(client, "sm_hnsrank");
			}
			case 7: {
				ClientCommand(client, "sm_js");
			}
			case 8: {
				ClientCommand(client, "sm_ljblock");
			}
			case 9: {
				ClientCommand(client, "sm_beam");
			}
			case 10: 
			{
				g_bStylePre[client] = !g_bStylePre[client];
				char szValue[8];
				IntToString(g_bStylePre[client], szValue, 8);
				SetClientCookie(client, g_hStyle, szValue);
			}
		}
			FJMenu(client);
	}

	if(action == MenuAction_End)
	{
		delete menu;
	}

}		

void SaveLocation(int client) {
	if (IsPlayerAlive(client)) {
		if(GetEntDataEnt2(client, FindSendPropInfo("CBasePlayer", "m_hGroundEntity")) != -1) {
			g_bDidSave[client] = true;
			GetClientAbsOrigin(client, g_fOrigin[client]);
			GetClientEyeAngles(client, g_fAngs[client]);
		}
		else
			PrintToChat(client, "\x01 \x04%s Вы должны быть на земле, чтобы сохранить позицию", CHATTAG);
	}
	else
		PrintToChat(client, "\x01 \x04%s Вы должны быть живы, чтобы сохранить позицию", CHATTAG);
}

void Teleport(int client) {
	float vel[3];
	//vel[0] = 0.0;
	//vel[1] = 0.0;
	vel[2] = 10.0;
	if(IsPlayerAlive(client))
		TeleportEntity(client, g_fOrigin[client], g_fAngs[client], vel);
	else
		PrintToChat(client, "\x01 \x04%s Вы должны быть живы, чтобы телепортироваться на позицию", CHATTAG);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2]) {
	if(g_iEnabled == 0)
		return Plugin_Handled;

	if(g_bNoclip[client])
		SetEntityMoveType(client, MOVETYPE_NOCLIP);
	else if(GetEntityMoveType(client) != MOVETYPE_LADDER)
		SetEntityMoveType(client, MOVETYPE_WALK);

	return Plugin_Continue;
}

public void Hook_PreThinkPost(int client) {
	if(!g_bStylePre[client])
		UnpatchGame();
}

public void Hook_PostThinkPost(int client) {
	if(!g_bStylePre[client])
		RepatchGame();
}

void RepatchGame() {
	if(g_iPatchAddress != Address_Null) {
		for(int i = 0; i < g_iPatchRestoreBytes; i++)
			StoreToAddress(g_iPatchAddress + view_as<Address>(i), 0x90, NumberType_Int8);
	}
}

void UnpatchGame() {
	if(g_iPatchAddress != Address_Null) {
		for(int i = 0; i < g_iPatchRestoreBytes; i++)
			StoreToAddress(g_iPatchAddress + view_as<Address>(i), g_iPatchRestore[i], NumberType_Int8);
	}
}

bool IsValidClient(int client) {
	return (0 < client <= MaxClients && IsClientInGame(client));
}