// =========================================================== //

static bool ResetConfirmation[MAXPLAYERS + 1];

static char ResetConfirmationPhrases[2][] =
{
	"Reset preferences to defaults",
	"Click again to reset preferences"
};

// =========================================================== //

void ResetToolsMenuVariables(int client)
{
	ResetConfirmation[client] = false;
}

void DisplayPreferenceToolsMenu(int client)
{
	Menu menu = new Menu(PreferenceToolsMenu_Handler);
	menu.SetTitle(MHUD_TAG_RAW ... " Preferences helpers & tools");

	menu.AddItem("G", "Generate preferences code");
	menu.AddItem("C", "Load preferences from code");
	menu.AddItem("P", "Load preferences from player");
	menu.AddItem("R", ResetConfirmationPhrases[ResetConfirmation[client]]);

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

static void DisplayPlayersMenu(int client)
{
	Menu menu = new Menu(PlayersMenu_Handler);
	menu.SetTitle(MHUD_TAG_RAW ... " Import preferences from player");

	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == client)
		{
			continue;
		}

		if (!MHud_IsValidClient(i))
		{
			continue;
		}

		char name[MAX_NAME_LENGTH];
		GetClientName(i, name, sizeof(name));
		ReplaceString(name, sizeof(name), "#", "");

		int userid = GetClientUserId(i);

		char szUserId[12];
		IntToString(userid, szUserId, sizeof(szUserId));
		
		menu.AddItem(szUserId, name);
	}

	// If no players were added...
	if (menu.ItemCount <= 0)
	{
		menu.AddItem("", "No valid players were found, sorry!", ITEMDRAW_DISABLED);
	}

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int PreferenceToolsMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char itemInfo[2];
		menu.GetItem(param2, itemInfo, sizeof(itemInfo));
		
		// Any other input cancels confirmation
		if (itemInfo[0] != 'R')
		{
			ResetConfirmation[param1] = false;
		}

		switch (itemInfo[0])
		{
			case 'G': FakeClientCommand(param1, "sm_mhud_preferences_export");
			case 'C': FakeClientCommand(param1, "sm_mhud_preferences_import");
			case 'P': DisplayPlayersMenu(param1);
			case 'R':
			{
				if (ResetConfirmation[param1])
				{
					g_Prefs.ResetPreferences(param1);
					MHud_Print(param1, true, "Your preferences has been reset!");
				}

				ResetConfirmation[param1] = !ResetConfirmation[param1];
			}
		}

		if (itemInfo[0] != 'P')
		{
			DisplayPreferenceToolsMenu(param1);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		ResetConfirmation[param1] = false;
		DisplayPreferenceMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public int PlayersMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char itemInfo[12];
		menu.GetItem(param2, itemInfo, sizeof(itemInfo));
		
		int target = GetClientOfUserId(StringToInt(itemInfo));
		
		if (MHud_IsValidClient(target))
		{
			for (int i = 0; i < g_Prefs.Length; i++)
			{
				Preference pref = g_Prefs.GetPreference(i);

				char prefName[MAX_PREFERENCE_NAME_LENGTH];
				pref.GetName(prefName, sizeof(prefName));

				char targetValue[MAX_PREFERENCE_VALUE_LENGTH];
				pref.GetStringVal(target, targetValue, sizeof(targetValue));

				pref.SetVal(param1, targetValue);
			}
		}

		DisplayPlayersMenu(param1);
	}
	else if (action == MenuAction_Cancel)
	{
		DisplayPreferenceToolsMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

// =========================================================== //