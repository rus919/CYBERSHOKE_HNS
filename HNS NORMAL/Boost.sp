#include "main\Lib\Lib.sp"

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(!IsValidClient(client))
		return;
		
	int ent = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	
	if(!IsValidClient(ent))
		return;
	
	if(ent > 0 && GetEntPropEnt(ent, Prop_Send, "m_hGroundEntity")>0)
		SetEntPropEnt(ent, Prop_Send, "m_hGroundEntity", 0);
}
