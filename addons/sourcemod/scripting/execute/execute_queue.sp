ArrayList g_aQueue;
ArrayList g_aActiveT;
ArrayList g_aActiveCT;

public void Queue_OnPluginStart()
{
	g_aQueue = new ArrayList(1);
	g_aActiveT = new ArrayList(1);
	g_aActiveCT = new ArrayList(1);
}

void AddClientToQueue(int client)
{
	RemoveClientFromGame(client);
	if(!IsClientInQueue(client))
	{
		CPrintToChat(client, "%t%t", "TAG", "You have been added to the queue");
		g_aQueue.Push(GetClientUserId(client));
	}
}

void RemoveClientFromQueue(int client)
{
	if(IsClientInQueue(client))
	{
		if(IsClientValid(client))
			CPrintToChat(client, "%t%t", "TAG", "You have been removed from the queue");
		g_aQueue.Erase(g_aQueue.FindValue(GetClientUserId(client)));
	}
}

bool IsClientInQueue(int client)
{
	if(g_aQueue.FindValue(GetClientUserId(client)) != -1)
		return true;
	return false;
}

void AddClientToGame(int client)
{
	int iActivePlayers = GetActivePlayers();
	int iNeededCT = RoundToCeil(iActivePlayers * g_cRatio.FloatValue);
	if(!IsClientActive(client))
	CPrintToChat(client, "%t%t", "TAG", "You have been added to the game");
	if(g_aActiveCT.Length < iNeededCT)
	{
		AddClientToCT(client);
	}else{
		AddClientToT(client);
	}
	RemoveClientFromQueue(client);
}

void AddClientToT(int client)
{
	RemoveClientFromQueue(client);
	int iIndex = g_aActiveCT.FindValue(GetClientUserId(client));
	if(iIndex != -1)
		g_aActiveCT.Erase(iIndex);
	iIndex = g_aActiveT.FindValue(GetClientUserId(client));
	if(iIndex == -1)
		g_aActiveT.Push(GetClientUserId(client));
}

void AddClientToCT(int client)
{
	CPrintToChat(client, "You have been moved to CT");
	RemoveClientFromQueue(client);
	int iIndex = g_aActiveT.FindValue(GetClientUserId(client));
	if(iIndex != -1)
		g_aActiveT.Erase(iIndex);
	iIndex = g_aActiveCT.FindValue(GetClientUserId(client));
	if(iIndex == -1)
		g_aActiveCT.Push(GetClientUserId(client));
}

void RemoveClientFromGame(int client)
{
	if(IsClientActive(client))
	{
		if(IsClientValid(client))
			CPrintToChat(client, "%t%t", "TAG", "You have been removed from the game");
		int iIndex = g_aActiveT.FindValue(GetClientUserId(client));
		if(iIndex != -1)
			g_aActiveT.Erase(iIndex);
		iIndex = g_aActiveCT.FindValue(GetClientUserId(client));
		if(iIndex != -1)
			g_aActiveCT.Erase(iIndex);
	}
}

bool IsClientActive(int client)
{
	if(g_aActiveT.FindValue(GetClientUserId(client)) != -1 || g_aActiveCT.FindValue(GetClientUserId(client)) != -1)
		return true;
	return false;
}

void AddClientsToGame(int iAmount)
{
	for (int i = 0; i < iAmount && i < g_aQueue.Length; i++)
	{
		int client = GetClientOfUserId(g_aQueue.Get(i));
		if(!IsClientValid(client))
		{
			g_aQueue.Erase(i--);
			continue;
		}
		AddClientToGame(client);
	}
}

int GetActivePlayers()
{
	return g_aActiveCT.Length + g_aActiveT.Length;
}

void CheckTeamBalance()
{
	int iActivePlayers = GetActivePlayers();
	int iNeededCT = RoundToCeil(iActivePlayers * g_cRatio.FloatValue);
	CPrintToChatAll("Needed CT's %i, Current CT's %i", iNeededCT, g_aActiveCT.Length);
	if(iNeededCT != g_aActiveCT.Length)
	{
		if(iNeededCT < g_aActiveCT.Length)
		{
			for (int i = 0; i < (g_aActiveCT.Length - iNeededCT); i++)
				AddClientToT(GetClientOfUserId(g_aActiveCT.Get(GetRandomInt(0, g_aActiveCT.Length - 1))));
		}else{
			for (int i = 0; i < (iNeededCT - g_aActiveCT.Length); i++)
				AddClientToCT(GetClientOfUserId(g_aActiveT.Get(GetRandomInt(0, g_aActiveT.Length - 1))));
		}
	}
}