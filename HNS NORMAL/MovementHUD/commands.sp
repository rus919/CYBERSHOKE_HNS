// ======================= LISTENERS ========================= //

void CreateCommands()
{
	//RegConsoleCmd("sm_mhud", Command_MHud, "Opens main MovementHUD preference menu");
	//RegConsoleCmd("sm_mhud_adv", Command_MHud_Adv, "Opens advanced MovementHUD preference menu");
	//RegConsoleCmd("sm_mhud_tools", Command_MHud_Tools, "Opens tools MovementHUD preference menu");
	//RegConsoleCmd("sm_mhud_simple", Command_MHud_Simple, "Opens simple MovementHUD preference menu");
	//RegConsoleCmd("sm_mhud_preferences_import", Command_MHud_Preferences_Import, "Import MovementHUD preferences from a code");
	//RegConsoleCmd("sm_mhud_preferences_export", Command_MHud_Preferences_Export, "Export MovementHUD preferences into a code");
	RegConsoleCmd("sm_mhdefault", SetDefault, "Default");
	RegConsoleCmd("sm_mhcustom", SetCustom, "Custom");

	CreateCommandAliases();
}

void CreatePreferenceCommands()
{
	for (int i = 0; i < g_Prefs.Length; i++)
	{
		char name[MAX_PREFERENCE_NAME_LENGTH];
		Pref(i).GetName(name, sizeof(name));

		char command[sizeof(name) + 4];
		Format(command, sizeof(command), "sm_%s", name);

		char display[MAX_PREFERENCE_DISPLAY_LENGTH];
		Pref(i).GetDisplay(display, sizeof(display));

		RegConsoleCmd(command, Command_Preference, display);
	}
}

static void CreateCommandAliases()
{
	RegConsoleCmd("sm_mhud_settings_import", Command_MHud_Preferences_Import, "Import MovementHUD preferences from a code");
	RegConsoleCmd("sm_mhud_settings_export", Command_MHud_Preferences_Export, "Export MovementHUD preferences into a code");
}

// ========================= PUBLIC ========================== //

public Action Command_MHud(int client, int args)
{
	if (!MHud_IsValidClient(client))
	{
		return Plugin_Handled;
	}

	DisplayPreferenceMenu(client);
	return Plugin_Handled;
}

public Action Command_MHud_Adv(int client, int args)
{
	if (!MHud_IsValidClient(client))
	{
		return Plugin_Handled;
	}

	DisplayAdvancedPreferenceMenu(client);
	return Plugin_Handled;
}

public Action Command_MHud_Tools(int client, int args)
{
	if (!MHud_IsValidClient(client))
	{
		return Plugin_Handled;
	}

	DisplayPreferenceToolsMenu(client);
	return Plugin_Handled;
}

public Action Command_MHud_Simple(int client, int args)
{
	if (!MHud_IsValidClient(client))
	{
		return Plugin_Handled;
	}

	DisplaySimplePreferenceMenu(client);
	return Plugin_Handled;
}

public Action Command_MHud_Preferences_Import(int client, int args)
{
	if (!MHud_IsValidClient(client))
	{
		return Plugin_Handled;
	}

	if (args < 1)
	{
		char cmdName[64];
		GetCmdArg(0, cmdName, sizeof(cmdName));

		MHud_Print(client, true, "Enter your preferences code in the console");
		MHud_Print(client, false, "Follow the format of: %s <\x05code\x01>", cmdName);
		return Plugin_Handled;
	}

	char buffer[256];
	GetCmdArgString(buffer, sizeof(buffer));

	PreferencesCode code = ImportPreferencesFromCode(client, buffer);
	if (!code.Failure)
	{
		char steamId2[32] = "Unknown";
		code.GetSteamId2(steamId2, sizeof(steamId2));
		
		if (code.Revision != MHUD_PREFERENCES_REVISION)
		{
			MHud_Print(client, true, "\x07WARNING! Mismatched preference revisions\x01");
		}

		MHud_Print(client, true, "Imported preferences from \x05%s\x01", steamId2);
		MHud_Print(client, true, "Imported preferences using revision number \x05%d\x01", code.Revision);
	}
	else
	{
		MHud_Print(client, true, "\x07Failure importing preferences from code!\x01");
	}

	Call_OnPreferencesImported(client, code);

	delete code;
	return Plugin_Handled;
}

public Action Command_MHud_Preferences_Export(int client, int args)
{
	if (!MHud_IsValidClient(client))
	{
		return Plugin_Handled;
	}

	char code[256];
	ExportPreferencesToCode(client, code, sizeof(code));

	MHud_Print(client, true, "See your console for your preferences code!");
	PrintToConsole(client, "\n-- COPY BETWEEN THESE --\n%s\n-- COPY BETWEEN THESE --", code);

	Call_OnPreferencesExported(client, code);
	return Plugin_Handled;
}

public Action Command_Preference(int client, int args)
{
	if (!MHud_IsValidClient(client))
	{
		return Plugin_Handled;
	}

	char command[MAX_PREFERENCE_NAME_LENGTH + 4];
	GetCmdArg(0, command, sizeof(command));

	Preference pref = g_Prefs.GetPreferenceByName(command[3]);

	if (args <= 0)
	{
		char display[MAX_PREFERENCE_DISPLAY_LENGTH];
		pref.GetDisplay(display, sizeof(display));

		char value[MAX_PREFERENCE_VALUE_LENGTH];
		pref.GetStringVal(client, value, sizeof(value));

		MHud_Print(client, true, "%s is currently set to \"%s\"", display, value);
	}
	else
	{
		char prefValue[MAX_PREFERENCE_VALUE_LENGTH];
		GetCmdArgString(prefValue, sizeof(prefValue));

		pref.SetVal(client, prefValue);
		
		char display[MAX_PREFERENCE_DISPLAY_LENGTH];
		pref.GetDisplay(display, sizeof(display));

		char value[MAX_PREFERENCE_VALUE_LENGTH];
		pref.GetStringVal(client, value, sizeof(value));

		Call_OnPreferenceSet(client, pref, true);
		MHud_Print(client, true, "%s set to \"%s\"", display, value);
	}

	Call_OnPreferenceCommand(client, pref, (args > 0));
	return Plugin_Handled;
}

// =========================================================== //