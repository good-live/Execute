#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "good_live"
#define PLUGIN_VERSION "0.01"

#include <sourcemod>
#include <sdktools>
#include <execute>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Execute - Test", 
	author = PLUGIN_AUTHOR, 
	description = "Registers some Test scenarios for Execute.", 
	version = PLUGIN_VERSION, 
	url = ""
};

public void OnPluginStart()
{
	
}

public void OnMapStart()
{
	StringMap scenario = new StringMap();
	
	StringMap spawn1 = new StringMap();
	spawn1.SetArray("pos", { -245.322753, 1256.592163, 32.031250 }, 3, true);
	spawn1.SetValue("team", CS_TEAM_T, true);
	spawn1.SetString("primary", "weapon_ak47");
	ArrayList aSpawns = new ArrayList(1);
	aSpawns2.Push(spawn1);
	
	scenario.SetValue("amount", 1, true);
	scenario.SetString("name", "Test1", true);
	scenario.SetValue("spawns", aSpawns, true);
	Ex_RegisterScenario(scenario);
	
	StringMap scenario2 = new StringMap();
	
	StringMap spawn2 = new StringMap();
	spawn2.SetArray("pos", { 340.521881, 2427.900390, -126.968750 }, 3, true);
	spawn2.SetValue("team", CS_TEAM_CT, true);
	spawn2.SetString("primary", "weapon_m4a1");
	
	ArrayList aSpawns2 = new ArrayList(1);
	aSpawns2.Push(spawn1);
	aSpawns2.Push(spawn2);
	
	scenario2.SetValue("amount", 2, true);
	scenario2.SetString("name", "Test2", true);
	scenario2.SetValue("spawns", aSpawns2, true);
	Ex_RegisterScenario(scenario2);
} 