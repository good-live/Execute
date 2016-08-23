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
	
	StringMap scenario2 = new StringMap();
	scenario2.SetValue("amount", 2, true);
	scenario2.SetString("name", "Test2", true);
	Ex_RegisterScenario(scenario2);
	
	StringMap scenario3 = new StringMap();
	scenario3.SetValue("amount", 3, true);
	scenario3.SetString("name", "Test3", true);
	Ex_RegisterScenario(scenario3);
	
	StringMap scenario4 = new StringMap();
	scenario4.SetValue("amount", 4, true);
	scenario4.SetString("name", "Test4", true);
	Ex_RegisterScenario(scenario4);
	
	StringMap scenario5 = new StringMap();
	scenario5.SetValue("amount", 5, true);
	scenario5.SetString("name", "Test5", true);
	Ex_RegisterScenario(scenario5);
	
	StringMap scenario6 = new StringMap();
	scenario6.SetValue("amount", 6, true);
	scenario6.SetString("name", "Test6", true);
	Ex_RegisterScenario(scenario6);
}