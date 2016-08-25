ArrayList g_aQueue;
ArrayList g_aActive;

public void Queue_OnPluginStart()
{
	g_aQueue = new ArrayList(1);
	g_aActive = new ArrayList(1);
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
	RemoveClientFromQueue(client);
	if(!IsClientActive(client))
	{
		CPrintToChat(client, "%t%t", "TAG", "You have been added to the game");
		g_aActive.Push(GetClientUserId(client));
	}
}

void RemoveClientFromGame(int client)
{
	if(IsClientActive(client))
	{
		if(IsClientValid(client))
			CPrintToChat(client, "%t%t", "TAG", "You have been removed from the game");
		g_aActive.Erase(g_aActive.FindValue(GetClientUserId(client)));
	}
}

bool IsClientActive(int client)
{
	if(g_aActive.FindValue(GetClientUserId(client)) != -1)
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
	return g_aActive.Length;
}