#if defined _executes_included_
  #endinput
#endif
#define _executes_included_
 
/**
 * Registers a new Scenario.
 *
 * @note    	  	There is no prevention of double registration.
 * @param Scenario	The scenario that should get registered.
 */
native void Ex_RegisterScenario(StringMap Scenario);