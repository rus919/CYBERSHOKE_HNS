// =========================================================== //

#include <MovementHUD>

// ====================== VARIABLES ========================== //

bool gB_Late = false;
Preferences g_Prefs = null;

// ======================= INCLUDES ========================== //

#include "MovementHUD/prefs/code.sp"
#include "MovementHUD/prefs/prefs.sp"
#include "MovementHUD/prefs/input.sp"

#include "MovementHUD/menus/main.sp"
#include "MovementHUD/menus/tools.sp"
#include "MovementHUD/menus/simple.sp"
#include "MovementHUD/menus/advanced.sp"

#include "MovementHUD/commands.sp"
#include "MovementHUD/movement.sp"
#include "MovementHUD/hud/hudtext.sp"

#include "MovementHUD/api/convars.sp"
#include "MovementHUD/api/natives.sp"
#include "MovementHUD/api/forwards.sp"

// ====================== PLUGIN INFO ======================== //

public Plugin myinfo =
{
	name = MHUD_NAME,
	author = MHUD_AUTHOR,
	description = "",
	version = MHUD_VERSION,
	url = MHUD_URL
};

// ======================= MAIN CODE ========================= //

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	InitMovement();
	CreateConvars();
	CreateNatives();
	CreateCommands();
	CreateForwards();

	gB_Late = late;
	RegPluginLibrary(MHUD_NAME);
	AutoExecConfig(true, MHUD_NAME);
}

public void OnPluginStart()
{
	InitHudText();

	g_Prefs = InitPrefs();
	Call_OnPreferencesInit();
	CreatePreferenceCommands();

	if (gB_Late)
	{
		gB_Late = false;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!MHud_IsValidClient(i))
			{
				continue;
			}

			if (AreClientCookiesCached(i))
			{
				OnClientCookiesCached(i);
			}
		}
	}
}

public void OnClientCookiesCached(int client)
{
	if (!IsFakeClient(client))
	{
		InitPrefsForClient(client, g_Prefs);
	}
}

public void OnClientDisconnect_Post(int client)
{
	ResetMovementForClient(client);
	ResetToolsMenuVariables(client);
	ResetExpectInputForClient(client);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!gCV_Speed.BoolValue && !gCV_Keys.BoolValue)
	{
		return;
	}

	// Allow bots to be tracked as well
	if (!MHud_IsValidClient(client, true))
	{
		return;
	}

	int target = GetSpectatorTarget(client);
	if (client == target)
	{
		TrackMovement(client, buttons, mouse);
	}

	// Only draw huds to real players
	if (!IsFakeClient(client))
	{
		DrawKeys(client, target);
		DrawSpeed(client, target);
	}
}

static void DrawSpeed(int player, int target)
{
	if (!gCV_Speed.BoolValue)
	{
		return;
	}

	if (Pref(Pref_Speed_Display).GetIntVal(player) <= 0)
	{
		return;
	}

	bool didPerf = gB_DidPerf[target];
	bool didTakeoff = gB_Takeoff[target];
	float currentSpeed = gF_CurrentSpeed[target];
	float takeoffSpeed = gF_TakeoffSpeed[target];

	DrawHudTextSpeed(player, currentSpeed, didPerf, didTakeoff, takeoffSpeed);
}

static void DrawKeys(int player, int target)
{
	if (!gCV_Keys.BoolValue)
	{
		return;
	}

	if (Pref(Pref_Keys_Display).GetIntVal(player) <= 0)
	{
		return;
	}

	int buttons = gI_Buttons[target];
	float lastJumpInput = gF_LastJumpInput[target];

	bool holdingS = (buttons & IN_BACK == IN_BACK);
	bool holdingC = (buttons & IN_DUCK == IN_DUCK);
	bool holdingW = (buttons & IN_FORWARD == IN_FORWARD);
	bool holdingA = (buttons & IN_MOVELEFT == IN_MOVELEFT);
	bool holdingD = (buttons & IN_MOVERIGHT == IN_MOVERIGHT);
	bool holdingJ = ((GetEngineTime() - lastJumpInput) < 0.05);
	bool overlapped = (holdingA && holdingD) || (holdingW && holdingS);
	bool lookingLeft = gI_Mouse[target][0] < 0;
	bool lookingRight = gI_Mouse[target][0] > 0;

	char keys[8][2] = { "W", "A", "S", "D", "C", "J", "←", "→" };
	int blankPref = Pref(Pref_Keys_Display).GetIntVal(player);

	char blankChar[2];
	switch (blankPref)
	{
		case 1: blankChar = "—";
		case 2: blankChar = "  ";
	}

	if (!holdingW) keys[0] = blankChar;
	if (!holdingA) keys[1] = blankChar;
	if (!holdingS) keys[2] = blankChar;
	if (!holdingD) keys[3] = blankChar;
	if (!holdingC) keys[4] = blankChar;
	if (!holdingJ) keys[5] = blankChar;
	if (!lookingLeft) keys[6] = blankChar;
	if (!lookingRight) keys[7] = blankChar;

	DrawHudTextKeys(player, overlapped, keys);
}

// =========================================================== //