// =========================================================== //

void DisplayPreferenceMenu(int client)
{
	Menu menu = new Menu(PreferenceMenu_Handler);

	menu.SetTitle("%s V%s\nPlugin Author: %s\
					\nPreferences Revision: %d",
					MHUD_TAG_RAW,
				  	MHUD_VERSION,
					MHUD_AUTHOR,
					MHUD_PREFERENCES_REVISION);

	menu.AddItem("S", "Simple preferences");
	menu.AddItem("A", "Advanced preferences");
	menu.AddItem("T", "Preferences helpers & tools");

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int PreferenceMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char itemInfo[2];
		menu.GetItem(param2, itemInfo, sizeof(itemInfo));

		switch (itemInfo[0])
		{
			case 'S': DisplaySimplePreferenceMenu(param1);
			case 'A': DisplayAdvancedPreferenceMenu(param1);
			case 'T': DisplayPreferenceToolsMenu(param1);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

// =========================================================== //