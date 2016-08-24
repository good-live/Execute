#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "good_live"
#define PLUGIN_VERSION "0.01"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <multicolors>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Executes",
	author = PLUGIN_AUTHOR,
	description = "Play a randomized competetive Scenario.",
	version = PLUGIN_VERSION,
	url = "painlessgaming.eu"
};

ArrayList g_aScenarios;
ArrayList g_aPossibleScenarios;
ArrayList g_aQueue;
ArrayList g_aActive;

StringMap g_smActiveScenario;

bool g_bIsActive;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Ex_RegisterScenario", Native_RegisterScenario);
}

public void OnPluginStart()
{
	LoadTranslations("execute.phrases");
	
	g_aScenarios = new ArrayList(1);
	g_aPossibleScenarios = new ArrayList(1);
	g_aQueue = new ArrayList(1);
	g_aActive = new ArrayList(1);
	
	HookEvent("round_start", OnRoundStart);
	AddCommandListener(OnJoinTeam, "jointeam");
}

public void OnMapStart()
{
	g_aScenarios.Clear();
	g_aActive.Clear();
	g_bIsActive = false;
	g_aQueue.Clear();
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CalculatePlayers();
}

public Action OnJoinTeam(int client, const char[] szCommand, int iArgCount)
{
	if(iArgCount < 1)
		return Plugin_Continue;

	char szData[2];
	GetCmdArg(1, szData, sizeof(szData));
	int iTeam = StringToInt(szData);
	
	if(iTeam !=  CS_TEAM_SPECTATOR && !IsClientActive(client))
	{
		if(g_bIsActive)
		{
			AddClientToQueue(client);
			ChangeClientTeam(client, CS_TEAM_SPECTATOR);
			return Plugin_Stop;
		}else{
			AddClientToGame(client);
			CreateTimer(0.1, Timer_CalculatePlayers);
		}
	}
	if(iTeam ==  CS_TEAM_SPECTATOR)
	{
		RemoveClientFromGame(client);
	}
	
	return Plugin_Continue;
}

public Action Timer_CalculatePlayers(Handle timer)
{
	CalculatePlayers();
	return;
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

public void OnClientDisconnect(int client)
{
	RemoveClientFromQueue(client);
	RemoveClientFromGame(client);
}

void CalculatePlayers()
{
	g_bIsActive = true;
	int iActivePlayers = GetActivePlayers();
	for (int i = g_aQueue.Length; i >= 0; i--)
	{
		if(GetScenarioAmount(iActivePlayers + i) > 0)
		{
			LoadPossibleScenarios(iActivePlayers + i);
			InitiateRandomScenario(i);
			return;
		}
	}
	for (int i = 1; i <= MaxClients; i++)
		if(IsClientConnected(i))
			CPrintToChat(i, "%t%t", "TAG", "Not enough players");
	
	CPrintToChatAll("Setting Game to inactive!");
	g_bIsActive = false;
}

int GetActivePlayers()
{
	return g_aActive.Length;
}
int GetScenarioAmount(int iClientAmount)
{
	int iAmount = 0;
	StringMap smBuffer;
	int iTemp;
	for (int i = 0; i < g_aScenarios.Length; i++)
	{
		smBuffer = view_as<StringMap>(g_aScenarios.Get(i));
		if(smBuffer.GetValue("amount", iTemp))
			if(iTemp == iClientAmount)
				iAmount++;
	}
	return iAmount;
}

void LoadPossibleScenarios(int iClientAmount)
{
	g_aPossibleScenarios.Clear();
	StringMap smBuffer;
	int iTemp;
	for (int i = 0; i < g_aScenarios.Length; i++)
	{
		smBuffer = view_as<StringMap>(g_aScenarios.Get(i));
		if(smBuffer.GetValue("amount", iTemp))
			if(iTemp == iClientAmount)
				g_aPossibleScenarios.Push(smBuffer);
	}
}

void InitiateRandomScenario(int iAmountQueue)
{
	
	int iIndex;
	
	SetRandomSeed(GetTime());
	
	iIndex = GetRandomInt(0, g_aPossibleScenarios.Length - 1);
	
	g_smActiveScenario = view_as<StringMap>(g_aPossibleScenarios.Get(iIndex));
	
	char sName[64];
	g_smActiveScenario.GetString("name", sName, sizeof(sName));
	
	CPrintToChatAll("The Scenario %s has started. %i player/s from the Queue get added to the game.", sName, iAmountQueue);
	
	AddClientsToGame(iAmountQueue);
	
	SpawnClients();
}

void SpawnClients()
{
	int iAmount = 0;
	char sSpawn[16];
	StringMap smSpawn;
	float fPos[3];
	for (int i = 0; i < g_aActive.Length; i++)
	{
		int client = GetClientOfUserId(g_aActive.Get(i));
		if(!IsClientValid(client))
		{
			LogError("A invalid client has been in the active clients List.");
			g_aActive.Erase(i);
			CalculatePlayers();
			return;
		}
		
		Format(sSpawn, sizeof(sSpawn), "spawn_%i", i + 1);
		
		if(!g_smActiveScenario.GetValue(sSpawn, smSpawn))
		{
			int iAmounts;
			g_smActiveScenario.GetValue("amount", iAmounts);
			if(iAmount >= i+1)
				SetFailState("There is no Spawn number %i defined for a Scenario. Needed Spawns: %i", i + 1, iAmounts);
			
			LogError("There are too much clients for the current Scenario. Failed to calculate scenario correctly");
			CalculatePlayers();
			return;
		}
		
		if(smSpawn == INVALID_HANDLE)
		{
			LogError("The spawn %i is invalid.", i+1);
			CalculatePlayers();
			return;
		}
		
		if(!smSpawn.GetArray("pos", fPos, sizeof(fPos)))
		{
			LogError("There is no spawning Position for spawn %i.", i+1);
		}
		
		if(!IsPlayerAlive(client))
			CS_RespawnPlayer(client);
		
		TeleportEntity(client, fPos, NULL_VECTOR, NULL_VECTOR);
		CPrintToChatAll("[Execute] Client %N has been spawned at Positon: %f %f %f", client, fPos[0], fPos[1], fPos[2]);
	}
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

stock int IsClientValid(int client)
{
	if(0 < client <= MaxClients && IsClientConnected(client))
		return true;
	
	return false;
}

public int Native_RegisterScenario(Handle plugin, int numParams)
{
	StringMap smScenario = GetNativeCell(1);
	int iAmount;
	smScenario.GetValue("amount", iAmount);
	CPrintToChatAll("Adding a new scenario for %i players", iAmount );
	if(smScenario == INVALID_HANDLE)
		return 0;
		
	g_aScenarios.Push(smScenario);
	return 0;
}