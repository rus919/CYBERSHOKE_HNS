public int RoundWin(int client)
{
	/*
	int ct=1;
	for(int i=1;i<=MaxClients;i++)
        if(IsValidClient(i)) 
            if(IsPlayerAlive(i))
                if(GetClientTeam(i)==3) 
                    ct++;
					*/
	return RoundToCeil(PiePoints(client,1.0,GetFollow(client))*24);
}

public int RoundLost(int client)
{
	return RoundToCeil(PiePoints(client,1.0,GetFollow(client))*5);
}

public int PlayerKill(int client)
{
	return RoundToCeil(PiePoints(client,1.0,GetFollow(client))*(g_Murder[client]+1)*7);
}

public int PlayerDeath(int client)
{
	return RoundToCeil(PiePoints(client,1.0,GetFollow(client))*7);
}

public int PlayerAssist(int client)
{
	return RoundToCeil(PiePoints(client,1.0,GetFollow(client))*5);
}

public float GetKDA(int client)
{
	float KDA=1.0;
	if(g_aPlayerStats[client][DEATH]!=0.0) 
        KDA=float(g_aPlayerStats[client][KILL] + g_aPlayerStats[client][ASSISTS])/float(g_aPlayerStats[client][DEATH]);
	else 
        KDA=float(g_aPlayerStats[client][KILL] + g_aPlayerStats[client][ASSISTS]);

	if(KDA>10.0) 
        KDA=10.0;

	if(KDA<0.1) 
        KDA=0.1;

	return KDA;
}

public float GetFollow(int client)
{
	float f = g_aPlayerFollow[client][TIMEPERCENT];

	if(f>10.0) 
		f=10.0;

	if(f<0.01) 
		f=0.01;

	return f;
}

public int GetNumberCTFollowT(int client)
{
	int ct;
	if(IsPlayerAlive(client))
		for(int i=1;i<MaxClients;i++)
			if(IsValidClient(i)) 
				if(GetClientTeam(i)==3 && IsPlayerAlive(i) && g_FollowDelay[i][client][TICKFOLLOW]>0)
					ct++;
	return ct;
}


public void PointsOperation(int client,int p)
{
	int iCount = 0;
	for(int i=1;i<MaxClients;i++)
		if(IsValidClient(i)) 
			iCount++;

	if(iCount < 3) 
		return;

	g_aPlayerStats[client][POINTS]+=p;
	g_aPlayerStats[client][MONEY]+=p;

	if(g_aPlayerStats[client][POINTS]<0) 
		g_aPlayerStats[client][POINTS]=0;

	if(g_aPlayerStats[client][MONEY]<0) 
		g_aPlayerStats[client][MONEY]=0;

	if(IsValidClient(client))
		SaveRank(client);
}

public float PiePoints(int client,float K,float F)
{
	return K*F;
}


public float dist_v(float A[3],float B[3])
{
	return SquareRoot((A[0]-B[0])*(A[0]-B[0])+(A[1]-B[1])*(A[1]-B[1])+(A[2]-B[2])*(A[2]-B[2])/10.0);
}

public int calc(float A[25][3],float B[25][3],const int length,int ct,int t) 
{ 
	int dist[25]; 
	for(int smoth=0;smoth<length;smoth++) 
	{ 
		float d=0.0; 
		for(int i=0;i<(length-smoth);i++) 
		{ 
			d=d+dist_v(A[i+smoth],B[i]); 
		} 
	 	dist[smoth]=RoundToCeil(d/(25-smoth)); 	
	} 
	int min[3][2];
	int max;
	for(int i=0;i<3;i++) 
	{ 
		min[i][0]=-1; 
		min[i][1]=9999; 
		max=0;
		for(int smoth=0;smoth<length;smoth++) 
		{ 
			if(min[i][1]>dist[smoth] && smoth!=min[0][0] && smoth!=min[1][0] && smoth!=min[2][0]) 
			{ 
				min[i][0]=smoth; 
				min[i][1]=dist[smoth]; 				
			} 
			if(max<dist[smoth]) max=dist[smoth];
		} 
	} 
	if(min[0][1]<100 && max>100 && GetSpeed(ct)>100)
		return min[0][1]+100*min[0][0];
	
	return 0;
}