// ================== DOUBLE INCLUDE ========================= //

#if defined _MovementHUD_included_
#endinput
#endif
#define _MovementHUD_included_

// ====================== DEFINITIONS ======================== //

#define MHUD_NAME "MovementHUD"
#define MHUD_AUTHOR "Sikari"
#define MHUD_VERSION "2.2.1"
#define MHUD_URL "https://bitbucket.org/Sikarii/MovementHUD"

#define MHUD_PREFERENCES_REVISION 2
#define MHUD_TAG_RAW "[MovementHUD]"
#define MHUD_TAG_COLOR "[\x0CMovement\x07HUD\x01]"

#define EPSILON 0.000001
#define TEAM_SPECTATOR 1
#define SPEC_MODE_INEYE 4
#define SPEC_MODE_CHASE 5
#define INPUT_TIMEOUT 15.0

// =========================================================== //

#include <clientprefs>
#include <StringMapEx>

#include <MovementHUD/preference>
#include <MovementHUD/preferences>
#include <MovementHUD/typehelpers>

// =========================================================== //

/**
 * Gets a MovementHUD preference by its int value (index)
 *
 * @note				See MovementHUD/preferences.inc enum for int values
 * @param iPref			Int value (index) of the preference to get
 * @return				The returned preference or null if index does not exist
 */
native Preference MHud_GetPreference(int iPref);

/**
 * Gets a MovementHUD preference by its name
 *
 * @param name			Name of the preference to get
 * @return				The returned preference or null if name does not exist
 */
native Preference MHud_GetPreferenceByName(char[] name);

/**
 * Gets current ticks on ground for client from MovementHUD tracking
 *
 * @param client		Client index
 * @return				Amount of ticks on ground for the client
 */
native int MHud_Movement_GetGroundTicks(int client);

/**
 * Gets current speed for client from MovementHUD tracking
 *
 * @param client		Client index
 * @return				Speed of the client as float
 */
native float MHud_Movement_GetCurrentSpeed(int client);

/**
 * Prints a message to the client's chat
 *
 * @param client		Client index
 * @param usePrefix		Whether to use MHud prefix
 * @param format		Formatting rules
 * @param any			Variable number of format parameters
 * @noreturn
 */
native void MHud_Print(int client, bool usePrefix, const char[] format, any ...);

// =========================================================== //

/**
 * Called when input is expected for a client
 *
 * @param client		Client index
 * @param pref			Preference of what we're expecting input for
 * @noreturn
 */
forward void MHud_OnExpectingInput(int client, Preference pref);

/**
 * Called when input is cancelled for a client
 *
 * @param client		Client index
 * @param pref			Preference of the input cancelled
 * @param timeout		Whether the cancellation was a timeout
 * @noreturn
 */
forward void MHud_OnInputCancelled(int client, Preference pref, bool timeout);

/**
 * Called when MovementHUD's stock preferences are initialized
 *
 * @noreturn
 */
forward void MHud_OnPreferencesInit();

/**
 * Called when preferences are loaded for a client
 *
 * @param client		Client index
 * @noreturn
 */
forward void MHud_OnPreferencesLoaded(int client);

/**
 * Called when a client imports their preferences
 * This can only be a preferences code at the moment
 *
 * @param client		Client index
 * @noreturn
 */
forward void MHud_OnPreferencesImported(int client);

/**
 * Called when a client exports their preferences
 * This can only be a preferences code at the moment
 *
 * @param client		Client index
 * @param code			Preferences code that was generated
 * @noreturn
 */
forward void MHud_OnPreferencesExported(int client, char[] code);

/**
 * Called when a preference is set for a client
 *
 * @param client		Client index
 * @param pref			The preference that was set
 * @param fromCommand	Whether this preference was set from a command
 * @noreturn
 */
forward void MHud_OnPreferenceSet(int client, Preference pref, bool fromCommand);

/**
 * Called when a client uses a preference command
 *
 * @param client		Client index
 * @param pref			The preference that the command triggered
 * @param hadValue		Whether the command had given a value (args > 0)
 */
forward void MHud_OnPreferenceCommand(int client, Preference pref, bool hadValue);

/**
 * Called when movement takeoff happens for a client
 *
 * @note				This is a single- hook!
 * @param client		Client index
 * @param didJump		Whether the takeoff was from a jump
 * @param didPerf		By-reference value of whether a perfect bunnyhop was done
 * @param takeoffSpeed	By-reference value of what the takeoff speed should be
 */
forward void MHud_Movement_OnTakeoff(int client, bool didJump, bool &didPerf, float &takeoffSpeed);

// ========================= STOCKS ========================== //

stock bool MHud_IsValidClient(int client, bool botsValid = false)
{
	return (0 < client <= MaxClients) && IsClientInGame(client) && (botsValid || !IsFakeClient(client));
}

stock float GetSpeed(int client)
{
	float vel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
	return SquareRoot(Pow(vel[0], 2.0) + Pow(vel[1], 2.0));
}

stock int GetSpectatorTarget(int client)
{
	if (GetClientTeam(client) == TEAM_SPECTATOR)
	{
		int mode = GetEntProp(client, Prop_Send, "m_iObserverMode");
		if (mode == SPEC_MODE_INEYE || mode == SPEC_MODE_CHASE)
		{
			int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			if (target != -1)
			{
				return target;
			}
		}
	}

	return client;
}

// ======================= PLUGIN INFO ======================= //

public SharedPlugin __pl_MovementHUD =
{
	name = "MovementHUD",
	file = "MovementHUD.smx",
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_MovementHUD_SetNTVOptional()
{
	MarkNativeAsOptional("MHud_Print");

	MarkNativeAsOptional("MHud_GetPreference");
	MarkNativeAsOptional("MHud_GetPreferenceByName");

	MarkNativeAsOptional("MHud_Movement_GetGroundTicks");
	MarkNativeAsOptional("MHud_Movement_GetCurrentSpeed");
}
#endif

// =========================================================== //