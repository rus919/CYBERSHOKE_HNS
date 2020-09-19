#include <sourcemod>
#include <sdkhooks>

float _stamina

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage)
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost)
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	_stamina = GetEntPropFloat(victim, Prop_Send, "m_flStamina")
}

public void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	if(attacker != 0 && attacker != -1)
		SetEntPropFloat(victim, Prop_Send, "m_flStamina", _stamina)
	SetEntPropFloat(victim, Prop_Send, "m_flVelocityModifier", 1.0)
}