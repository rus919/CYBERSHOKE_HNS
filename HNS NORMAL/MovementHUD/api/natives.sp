// =========================================================== //

void CreateNatives()
{
	CreateNative("MHud_Print", Native_Print);

	CreateNative("MHud_GetPreference", Native_GetPreference);
	CreateNative("MHud_GetPreferenceByName", Native_GetPreferenceByName);

	CreateNative("MHud_Movement_GetGroundTicks", Native_Movement_GetGroundTicks);
	CreateNative("MHud_Movement_GetCurrentSpeed", Native_Movement_GetCurrentSpeed);
}

// =========================================================== //

public int Native_Print(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	bool usePrefix = GetNativeCell(2);

	char buffer[256];
	FormatNativeString(0, 3, 4, sizeof(buffer), _, buffer);

	if (usePrefix)
	{
		Format(buffer, sizeof(buffer), "%s %s", MHUD_TAG_COLOR, buffer);
	}

	PrintToChat(client, "%s", buffer);
}

public int Native_GetPreference(Handle plugin, int numParams)
{
	int iPref = GetNativeCell(1);
	return g_Prefs.Get(iPref);
}

public int Native_GetPreferenceByName(Handle plugin, int numParams)
{
	char name[MAX_PREFERENCE_NAME_LENGTH];
	GetNativeString(1, name, sizeof(name));
	return view_as<int>(g_Prefs.GetPreferenceByName(name));
}

public int Native_Movement_GetGroundTicks(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return gI_GroundTicks[client];
}

public int Native_Movement_GetCurrentSpeed(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return view_as<int>(gF_CurrentSpeed[client]);
}

// =========================================================== //