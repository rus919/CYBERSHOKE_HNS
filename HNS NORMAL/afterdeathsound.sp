#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define SOUND_DOWNLOAD	"sound/WithoutName/death.mp3"
#define SOUND_PLAY		"*WithoutName/death.mp3"

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
}

public OnMapStart()
{
	PrecacheSound(SOUND_PLAY, true);
	AddFileToDownloadsTable(SOUND_DOWNLOAD);
}

public void Event_PlayerDeath(Event hEvent, const char[] sEvName, bool bDontBroadcast)   
{

    new i = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    if(IsClientInGame(i))
	{
		
		ClientCommand(i, "playgamesound *WithoutName/death.mp3");
	}
}