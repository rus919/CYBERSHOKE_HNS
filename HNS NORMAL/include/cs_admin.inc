#if defined _cybershoke_admin_included_
  #endinput
#endif
#define _cybershoke_admin_included_

native bool CS_IsOverlay(int iClient);
native void CS_Admin_SetBan(int iClient, int iTarget, int iTime, char[] sReason);

forward void CS_Admin_OnMenuCreated(int iClient, Menu& hMenu);
forward void CS_Admin_OnMenuSelected(int iClient, const char[] sInfo);

public SharedPlugin __pl_cybershoke_admin = 
{
	name = "cybershoke_admin",
	file = "cybershoke_admin.smx",

	#if defined REQUIRE_PLUGIN
		required = 1,
	#else
		required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_cybershoke_admin_SetNTVOptional()
{
	MarkNativeAsOptional("CS_Admin_SetBan");
	MarkNativeAsOptional("CS_IsOverlay");
}
#endif