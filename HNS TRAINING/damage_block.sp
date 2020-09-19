#include <sourcemod>
#include <sdkhooks>

#pragma newdecls required

public void OnPluginStart() {
    for (int iClient = 1; iClient <= MaxClients; iClient++) {
        if (IsClientInGame(iClient)) {
            OnClientPostAdminCheck(iClient);
        }
    }
}

public void OnClientPostAdminCheck(int iClient) {
    SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom) {
    return Plugin_Stop;
}