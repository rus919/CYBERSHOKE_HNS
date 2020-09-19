// ================== DOUBLE INCLUDE ========================= //

#if defined _MovementHUD_Preferences_included_
#endinput
#endif
#define _MovementHUD_Preferences_included_

// =========================================================== //

enum
{
	Pref_Speed_Display,
	Pref_Speed_Position,
	Pref_Speed_Normal_Color,
	Pref_Speed_Perf_Color,
	Pref_Keys_Display,
	Pref_Keys_Position,
	Pref_Keys_Normal_Color,
	Pref_Keys_Overlap_Color,
	Pref_Keys_Mouse_Direction,
	PREF_COUNT
};

// =========================================================== //

methodmap Preferences < ArrayList
{
	public Preferences()
	{
		return view_as<Preferences>(new ArrayList());
	}

	public void PushPreference(Preference preference)
	{
		this.Push(preference);
	}

	public Preference GetPreference(int pref)
	{
		return this.Get(pref);
	}
	
	public Preference GetPreferenceByName(char[] name)
	{
		for (int i = 0; i < this.Length; i++)
		{
			Preference pref = this.Get(i);

			char prefName[MAX_PREFERENCE_NAME_LENGTH];
			pref.GetName(prefName, sizeof(prefName));
			
			if (StrEqual(prefName, name))
			{
				return pref;
			}
		}

		return null;
	}
	
	public void CreatePreference(char[] name, char[] display, char[] defValue, int type, int limit)
	{
		int iPref = this.Length;
		this.PushPreference(new Preference(name, display, defValue, type, limit, iPref));
	}

	public void ResetPreferences(int client)
	{
		for (int i = 0; i < this.Length; i++)
		{
			this.GetPreference(i).Reset(client);
		}
	}
}

// =========================================================== //