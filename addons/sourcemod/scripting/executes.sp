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

StringMap g_smActiveScenario;

bool g_bIsActive;

public void OnPluginStart()
{
	g_aScenarios = new ArrayList(1);
	g_aQueue = new ArrayList(1);
	HookEvent("round_start", OnRoundStart);
	
	LoadTranslations("executes.phrases");
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CalculatePlayers();
}

void CalculatePlayers()
{
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
}

int GetActivePlayers()
{
	int iCounter;
	for (int i = 0; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && GetClientTeam(i) <= CS_TEAM_SPECTATOR)
			iCounter++;
	}
	return iCounter;
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
	
	g_bIsActive = false;
	
	g_smActiveScenario = view_as<StringMap>(g_aPossibleScenarios.Get(iIndex));
	
	char sName[64];
	g_smActiveScenario.GetString("name", sName, sizeof(sName));
	
	CPrintToChatAll("The Scenario %s has started. %i player/s from the Queue get added to the game.", sName, iAmountQueue);
	
	ArrayList aActiveClients = new ArrayList(1);
	RemoveClientsFromQueue(iAmountQueue);
	
	g_bIsActive = true;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && !IsClientInQueue(i))
			aActiveClients.Push(i);
	}
	
	SpawnClients(aActiveClients);
}

void SpawnClients(ArrayList aActiveClients)
{
	for (int i = 0; i < aActiveClients.Length; i++)
	{
		CPrintToChatAll("[Execute] Spawning now %N", aActiveClients.Get(i));
	}
}

bool IsClientInQueue(int client)
{
	if(g_aQueue.FindValue(client) != -1)
		return true;
	return false;
}

void RemoveClientsFromQueue(int iAmount)
{
	for (int i = 0; i < iAmount && i < g_aQueue.Length; i++)
	{
		int client = GetClientOfUserId(g_aQueue.Get(i));
		if(!IsClientValid(client))
		{
			g_aQueue.Erase(i--);
			continue;
		}
		CPrintToChat(client, "%t%t", "TAG", "You have been added to the game");
		g_aQueue.Erase(i);
	}
}

stock int IsClientValid(int client)
{
	if(0 < client <= MaxClients && IsClientConnected(client))
		return true;
	
	return false;
}