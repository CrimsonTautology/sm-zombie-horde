/**
 * vim: set ts=4 :
 * =============================================================================
 * zombie_horde
 * The post-cyberapocalyptic zombie horde shooter TF2 mod.
 *
 * Copyright 2013 The Crimson Tautology
 * =============================================================================
 *
 */


#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>

#define PLUGIN_VERSION 0.1

public Plugin:myinfo =
{
    name = "TF2 Zombie Horde",
    author = "CrimsonTautology",
    description = "Fight off the zombie horde",
    url = ""
}


#define ENTITY_BUFFER 128
#define MAX_SPAWN_POINTS 128
#define MAX_ZOMBIES 128

new Handle:g_Cvar_ZmbEnabled = INVALID_HANDLE;
new Handle:g_Cvar_ZmbTeam = INVALID_HANDLE;
new Handle:g_Cvar_ZmbHealth = INVALID_HANDLE;
new Handle:g_Cvar_ZmbDamage = INVALID_HANDLE;

new g_SpawnPoints[MAX_SPAWN_POINTS];
new g_SpawnPointsCount = 0;
new g_NextSpawnPoint = 0;

new Float:g_DifficultyCoefficent = 10.0;
new g_MaxStages = 6;
new g_CurrentStage = 0;

public OnPluginStart()
{

    g_Cvar_ZmbEnabled = CreateConVar("sm_zmb_enabled", "0", "Whether the zombie horde is enabled or not");
    g_Cvar_ZmbTeam = CreateConVar("sm_zmb_team", "3", "The team that the zombies will spawn on. [2=RED; 3=BLU]");
    //g_Cvar_ZmbHealth = CreateConVar(sm_zmb_health, "1", "TODO - Add a description for this cvar");
    //g_Cvar_ZmbDamage = CreateConVar(sm_zmb_damage, "1", "TODO - Add a description for this cvar");


    HookEvent("player_team", Event_PlayerTeam);
    HookEvent("teamplay_round_stalemate", Event_TeamplayRoundStalemate);
    HookEvent("teamplay_round_win", Event_TeamplayRoundWin);
    HookEvent("teamplay_game_over", Event_TeamplayGameOver);
    HookEvent("teamplay_round_start", Event_TeamplayRoundStart);

    RegConsoleCmd("sm_test123", Command_Test);

}

public OnMapStart()
{
    
}

public Action:Command_Test(client, args){
    test();
}

public FindSpawnPoints()
{
    new entity;
    g_SpawnPointsCount = 0;

    while (((entity = FindEntityByClassname(entity, "info_player_teamspawn")) > 0) && g_SpawnPointsCount < MAX_SPAWN_POINTS)
    {
        if(IsValidZombieSpawn(entity)){
            g_SpawnPoints[g_SpawnPointsCount] = entity;
            g_SpawnPointsCount++;
        }
    }
}

public bool:IsValidZombieSpawn(entity)
{
    return !GetEntProp(entity, Prop_Data, "m_bDisabled") && GetEntProp(entity, Prop_Data, "m_iTeamNum") == 3;
}

public NextSpawnPoint()
{
    if (g_SpawnPointsCount == 0) return -1;

    g_NextSpawnPoint = (g_NextSpawnPoint + 1) % g_SpawnPointsCount;
    return g_SpawnPoints[g_NextSpawnPoint];
}

public SpawnZombie(Float:spawn[3])
{
    if(GetEntityCount() >= GetMaxEntities() - ENTITY_BUFFER)
    {
        LogError("[ZMB] Maxed out entities");
    }else
    {
        new zombie = CreateEntityByName("tf_zombie");
        if(IsValidEntity(zombie))
        {
            DispatchSpawn(zombie);
            spawn[2] -= 10.0;
            TeleportEntity(zombie, spawn, NULL_VECTOR, NULL_VECTOR);
        }
    }
}

public Float:CalculateNextZombieSpawn()
{
    new Float:stage_difficulty = ((g_MaxStages - g_CurrentStage) / (g_MaxStages * 1.0));
    new Float:player_difficulty = ((32.0 - GetClientCount(true)) / 32.0);
    new Float:calc = g_DifficultyCoefficent * stage_difficulty * player_difficulty;

    if (calc > 0.25)
    {
        return calc;
    }else{
        return 0.25;
    }

}

public Action:ZombieTimer(Handle:timer)
{
    if(IsModeEnabled())
    {
        SpawnZombieAtNextPoint();
        CreateTimer(CalculateNextZombieSpawn(), ZombieTimer);
    }
}

public SpawnZombieAtNextPoint()
{
    //new Float:spawn[3]={-1444.356323, 6.377807, 579.346191};
    new Float:spawn[3];
    FindSpawnPoints();
    GetEntPropVector(NextSpawnPoint(), Prop_Send, "m_vecOrigin", spawn);
    SpawnZombie(spawn);
}

public ClearZombie()
{
}

public bool:IsModeEnabled()
{
    return GetConVarBool(g_Cvar_ZmbEnabled);
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    //Block players from joining the zombie team if the mode is enabled

    if(!IsModeEnabled())
        return Plugin_Continue;

    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new TFTeam:team = TFTeam:GetEventInt(event, "team");
    new TFTeam:zombie_team = TFTeam:GetConVarInt(g_Cvar_ZmbTeam);

    if(team == zombie_team)
    {

        ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 Joining that team is not allowed.");
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Event_TeamplayRoundStalemate(Handle:event, const String:name[], bool:dontBroadcast)
{
    //TODO
}

public Event_TeamplayRoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
    //TODO
}

public Event_TeamplayGameOver(Handle:event, const String:name[], bool:dontBroadcast)
{
    //TODO
}

public Action:Event_TeamplayRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!IsModeEnabled())
        return Plugin_Continue;

    g_CurrentStage = 0;
    CreateTimer(CalculateNextZombieSpawn(), ZombieTimer);
    return Plugin_Continue;
}

public test()
{
    SpawnZombieAtNextPoint();
}