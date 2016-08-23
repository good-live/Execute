#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "good_live"
#define PLUGIN_VERSION "0.01"

#include <sourcemod>
#include <sdktools>
#include <execute>

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

public void OnAllPluginsLoaded()
{
	StringMap scenario = new StringMap();
	scenario.SetValue("amount", 1, true);
	scenario.SetString("name", "Test1", true);
	Ex_RegisterScenario(scenario);
	
	scenario.SetValue("amount", 2, true);
	scenario.SetString("name", "Test2", true);
	Ex_RegisterScenario(scenario);
	
	scenario.SetValue("amount", 3, true);
	scenario.SetString("name", "Test3", true);
	Ex_RegisterScenario(scenario);
	
	scenario.SetValue("amount", 4, true);
	scenario.SetString("name", "Test4", true);
	Ex_RegisterScenario(scenario);
	
	scenario.SetValue("amount", 5, true);
	scenario.SetString("name", "Test5", true);
	Ex_RegisterScenario(scenario);
	
	scenario.SetValue("amount", 6, true);
	scenario.SetString("name", "Test6", true);
	Ex_RegisterScenario(scenario);
	
	scenario.SetValue("amount", 7, true);
	scenario.SetString("name", "Test7", true);
	Ex_RegisterScenario(scenario);
	
	scenario.SetValue("amount", 8, true);
	scenario.SetString("name", "Test8", true);
	Ex_RegisterScenario(scenario);
	
	scenario.SetValue("amount", 9, true);
	scenario.SetString("name", "Test9", true);
	Ex_RegisterScenario(scenario);

	scenario.SetValue("amount", 10, true);
	scenario.SetString("name", "Test10", true);
	Ex_RegisterScenario(scenario);
}