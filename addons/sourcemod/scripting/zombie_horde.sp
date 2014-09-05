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
#include <entcontrol>

#define PLUGIN_VERSION 0.1

public Plugin:myinfo =
{
    name = "TF2 Zombie Horde",
    author = "CrimsonTautology",
    description = "Fight off the zombie horde",
    url = "https://github.com/CrimsonTautology/sm_zombie_horde"
}


#define ENTITY_BUFFER 128
#define MAX_SPAWN_POINTS 128
#define MAX_ZOMBIES 128

new Handle:g_Cvar_ZmbEnabled = INVALID_HANDLE;
new Handle:g_Cvar_ZmbTeam = INVALID_HANDLE;
//new Handle:g_Cvar_ZmbHealth = INVALID_HANDLE;
//new Handle:g_Cvar_ZmbDamage = INVALID_HANDLE;

new bool:g_NavMeshParsed = false;

new Float:g_DifficultyCoefficent = 10.0;
new g_MaxStages = 6;
new g_CurrentStage = 0;

enum Enemy
{
    Skeleton = 0,
    SkeletonBaby,
    SkeletonKing,
    Ghost,
    Hatman,
    Eyeboss,
    Merasmus
}

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
    //pumpkin_lord_killed
    //eyeball_boss_killed
    //merasmus_killed

    RegConsoleCmd("sm_test123", Command_Test);

}

public OnMapStart()
{
    //TODO: check if cvar is set?
    g_NavMeshParsed = ParseNavMesh();

}

bool:ParseNavMesh()
{
    //Parse the nav-mesh
    if(EC_Nav_Load())
    {
        //Cache positions in nav-mesh
        if(EC_Nav_CachePositions())
        {
            return true;
        }else
        {
            //TODO: Error, unable to cache positons
            return false;
        }
    }else
    {
        //TODO: Nav-mesh was not found
        return false;
    }
}

public Action:Command_Test(client, args){
    test();
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
    CreateTimer(CalculateNextEnemySpawn(), EnemyTimer);
    return Plugin_Continue;
}

public Action:EnemyTimer(Handle:timer)
{
    if(IsModeEnabled())
    {
        SpawnEnemyAtNextPoint();
        CreateTimer(CalculateNextEnemySpawn(), EnemyTimer);
    }
}

public SpawnEnemy(Float:spawn[3], Enemy:enemy_type)
{
    if(GetEntityCount() >= GetMaxEntities() - ENTITY_BUFFER)
    {
        LogError("[ZMB] Maxed out entities");
    }else
    {
        switch(enemy_type)
        {
            case Skeleton:
                SpawnSkeleton(spawn);
            case SkeletonBaby:
                SpawnSkeletonBaby(spawn);
            case SkeletonKing:
                SpawnSkeletonKing(spawn);
            case Ghost:
                SpawnGhost(spawn);
            case Hatman:
                SpawnHatman(spawn);
            case Eyeboss:
                SpawnEyeboss(spawn);
            case Merasmus:
                SpawnMerasmus(spawn);
        }
    }
}

SpawnSkeleton(Float:spawn[3])
{
    new entity = CreateEntityByName("tf_zombie");
    if(IsValidEntity(entity))
    {
        DispatchSpawn(entity);
        SetEntProp(entity, Prop_Send, "m_iTeamNum", GetConVarInt(g_Cvar_ZmbTeam));
        //SetEntPropFloat(entity, Prop_Send, "m_flModelScale", scale);
        //SetEntProp(entity, Prop_Send, "m_iTeamNum", team);
        //DispatchKeyValue(entity, "skin", skin);
        //SetEntProp(entity, Prop_Send, "m_bGlowEnabled", 1);
        //SetEntProp(entity, Prop_Data, "m_nSkeletonType", 1);

        spawn[2] -= 10.0;
        TeleportEntity(entity, spawn, NULL_VECTOR, NULL_VECTOR);
    }
}


SpawnSkeletonBaby(Float:spawn[3])
{
    new entity = CreateEntityByName("tf_zombie");
    if(IsValidEntity(entity))
    {
        DispatchSpawn(entity);
        SetEntProp(entity, Prop_Send, "m_iTeamNum", GetConVarInt(g_Cvar_ZmbTeam));
        SetEntProp(entity, Prop_Data, "m_nSkeletonType", 2);

        spawn[2] -= 10.0;
        TeleportEntity(entity, spawn, NULL_VECTOR, NULL_VECTOR);
    }
}

SpawnSkeletonKing(Float:spawn[3])
{
    new entity = CreateEntityByName("tf_zombie");
    if(IsValidEntity(entity))
    {
        DispatchSpawn(entity);
        SetEntProp(entity, Prop_Send, "m_iTeamNum", GetConVarInt(g_Cvar_ZmbTeam));
        SetEntProp(entity, Prop_Data, "m_nSkeletonType", 1);

        spawn[2] -= 10.0;
        TeleportEntity(entity, spawn, NULL_VECTOR, NULL_VECTOR);
    }
}

SpawnGhost(Float:spawn[3])
{
    new entity = CreateEntityByName("ghost");
    if(IsValidEntity(entity))
    {
        DispatchSpawn(entity);

        spawn[2] -= 10.0;
        TeleportEntity(entity, spawn, NULL_VECTOR, NULL_VECTOR);
    }
}

SpawnHatman(Float:spawn[3])
{
    new entity = CreateEntityByName("headless_hatman");
    if(IsValidEntity(entity))
    {
        DispatchSpawn(entity);

        spawn[2] -= 10.0;
        TeleportEntity(entity, spawn, NULL_VECTOR, NULL_VECTOR);
    }
}

SpawnEyeboss(Float:spawn[3])
{
    new entity = CreateEntityByName("eyeball_boss");
    if(IsValidEntity(entity))
    {
        DispatchSpawn(entity);

        spawn[2] -= 10.0;
        TeleportEntity(entity, spawn, NULL_VECTOR, NULL_VECTOR);
    }
}

SpawnMerasmus(Float:spawn[3])
{
    new entity = CreateEntityByName("merasmus");
    if(IsValidEntity(entity))
    {
        DispatchSpawn(entity);

        spawn[2] -= 10.0;
        TeleportEntity(entity, spawn, NULL_VECTOR, NULL_VECTOR);
    }
}

public Float:CalculateNextEnemySpawn()
{
    new Float:stage_difficulty = ((g_MaxStages - g_CurrentStage) / (g_MaxStages * 1.0));
    new Float:player_difficulty = ((32.0 - GetClientCount(true)) / 32.0);
    new Float:calc = g_DifficultyCoefficent * stage_difficulty * player_difficulty;

    return (calc > 0.25) ? calc : 0.25; //We don't have a max() function
}

public Enemy:CalculateNextEnemyType()
{
    return Skeleton;
}

public SpawnEnemyAtNextPoint()
{
    //new Float:spawn[3]={-1444.356323, 6.377807, 579.346191};
    new Float:spawn[3];
    if(EC_Nav_GetNextHidingSpot(spawn))
    {
        new Enemy:enemy_type = CalculateNextEnemyType();
        SpawnEnemy(spawn, enemy_type);
    }else{
        //TODO:  Unable to find hiding spot
    }
}

public ClearEnemy()
{
}

public bool:IsModeEnabled()
{
    return GetConVarBool(g_Cvar_ZmbEnabled) && g_NavMeshParsed;
}

public test()
{
    SpawnEnemyAtNextPoint();
}
