// =========================================================== //

stock int ClampInt(int value, int maxValue)
{
	if (value < 0 || value > maxValue)
	{
		return 0;
	}
	else
	{
		return value;
	}
}

// =========================================================== //

stock float ClampXY(float val)
{
	if (val - EPSILON <= -1.0)
	{
		return -1.0;
	}
	else
	{
		if (val < 0.0 - EPSILON)
		{
			return 0.0;
		}
		else if (val > 1.0 - EPSILON)
		{
			return 1.0;
		}
		else
		{
			return val;
		}
	}
}

stock void BufferToXY(char[] buffer, float[] xy, int maxlength)
{
	if (maxlength < 2)
	{
		LogError("Not enough space to store XY");
		return;
	}

	char sXY[2][5];
	ExplodeString(buffer, " ", sXY, sizeof(sXY), sizeof(sXY[]));

	xy[0] = ClampXY(StringToFloat(sXY[0]) + EPSILON);
	xy[1] = ClampXY(StringToFloat(sXY[1]) + EPSILON);
}

// =========================================================== //

stock int ClampRGBA(int val)
{
	if (val > 255)
	{
		return 255;
	}
	else if (val < 0)
	{
		return 0;
	}
	else
	{
		return val;
	}
}

stock void BufferToRGBA(char[] buffer, int[] rgba, int maxlength)
{
	if (maxlength < 4)
	{
		LogError("Not enough space to store RGBA");
		return;
	}

	char sRGBA[4][4];
	ExplodeString(buffer, " ", sRGBA, sizeof(sRGBA), sizeof(sRGBA[]));

	rgba[0] = ClampRGBA(StringToInt(sRGBA[0]));
	rgba[1] = ClampRGBA(StringToInt(sRGBA[1]));
	rgba[2] = ClampRGBA(StringToInt(sRGBA[2]));
	rgba[3] = ClampRGBA(StringToInt(sRGBA[3]));
}

// =========================================================== //