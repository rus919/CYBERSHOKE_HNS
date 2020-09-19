#include <sourcemod>
#include <cstrike>
#include <sdktools>

#include <msharedutil/ents>


#define COLLISION_TRIGGERONLY       2
#define COLLISION_DEFAULT           5


bool g_bLate;

public APLRes AskPluginLoad2( Handle hPlugin, bool late, char[] szError, int error_len )
{
    g_bLate = late;
}

public void OnPluginStart()
{
    HookEvent( "player_spawn", E_PlayerSpawn );
    
    
    if ( g_bLate )
    {
        for ( int i = 1; i <= MaxClients; i++ )
        {
            if ( IsClientInGame( i ) && IsPlayerAlive( i ) )
            {
                SetEntityCollisionGroup( i, COLLISION_TRIGGERONLY );
            }
        }
    }
}

public void OnPluginEnd()
{
    for ( int i = 1; i <= MaxClients; i++ )
    {
        if ( IsClientInGame( i ) && IsPlayerAlive( i ) )
        {
            SetEntityCollisionGroup( i, COLLISION_DEFAULT );
        }
    }
}

public void E_PlayerSpawn( Event event, const char[] szEvent, bool bImUselessWhyDoIExist )
{
    int client = GetClientOfUserId( event.GetInt( "userid" ) );
    if ( client < 1 || !IsClientInGame( client ) ) return;
    
    if ( GetClientTeam( client ) <= CS_TEAM_SPECTATOR || !IsPlayerAlive( client ) ) return;
    
    
    SetEntityCollisionGroup( client, COLLISION_TRIGGERONLY );
}