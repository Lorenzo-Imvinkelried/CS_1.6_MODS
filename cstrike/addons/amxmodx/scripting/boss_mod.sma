#include <amxmodx>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>

#define PLUGIN  "Juggernaut Multi-Boss Mod"
#define VERSION "5.0"
#define AUTHOR  "Antigravity"

// Estado de Boss por jugador (permite multiples bosses y permanencia entre rondas)
new bool:g_bIsBoss[33]

// Offsets para armas
#define OFFSET_WEAPON_OWNER        41
#define OFFSET_EXTRA_WEAPON        4

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    set_cvar_float("sv_maxspeed", 1000.0)
    if (is_dedicated_server())
    {
        set_cvar_num("sv_lan", 0)
    }

    // Eventos
    register_logevent("logevent_RoundStart", 2, "1=Round_Start")
    register_event("CurWeapon", "event_CurWeapon", "be", "1=1")
    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
    RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)

    // Balas infinitas en la Escopeta para cualquier Boss
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_xm1014", "fw_Shotgun_PrimaryAttack_Post", 1)
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m3", "fw_Shotgun_PrimaryAttack_Post", 1)

    // Comandos de chat para el menu del Boss
    register_clcmd("say boss", "cmd_OpenBossMenu")
    register_clcmd("say /boss", "cmd_OpenBossMenu")
    register_clcmd("say_team boss", "cmd_OpenBossMenu")
    register_clcmd("say_team /boss", "cmd_OpenBossMenu")
    register_clcmd("boss", "cmd_OpenBossMenu")

    // Atajos directos
    register_clcmd("say boss me", "cmd_MakeMeBoss")
    register_clcmd("say boss yo", "cmd_MakeMeBoss")
    register_clcmd("say boss bot", "cmd_MakeBotBoss")

    // Desactivar Boss
    register_clcmd("say noboss", "cmd_StopBossMode")
    register_clcmd("say /noboss", "cmd_StopBossMode")
    register_clcmd("say normal", "cmd_StopBossMode")
    register_clcmd("say noboss all", "cmd_StopAllBosses")
    register_clcmd("say /noboss all", "cmd_StopAllBosses")

    // Comandos directos para Bots
    register_clcmd("say bot", "cmd_AddBotT")
    register_clcmd("say /bot", "cmd_AddBotT")
    register_clcmd("say bot_t", "cmd_AddBotT")
    register_clcmd("say /bot_t", "cmd_AddBotT")
    register_clcmd("say bot_ct", "cmd_AddBotCT")
    register_clcmd("say /bot_ct", "cmd_AddBotCT")
    register_clcmd("say kickbots", "cmd_KickBots")
    register_clcmd("say /kickbots", "cmd_KickBots")

    // Tarea continua para mostrar el HUD de vida de todos los Bosses
    set_task(0.5, "task_ShowBossHUD", _, _, _, "b")
}

public client_disconnected(id)
{
    g_bIsBoss[id] = false
}

// =========================================================================
// APLICAR SUPER PODERES AL BOSS (INSTANTANEO Y PERMANENTE)
// =========================================================================
ApplyBossBuffs(id)
{
    if (!id || !is_user_connected(id) || !is_user_alive(id))
        return

    g_bIsBoss[id] = true

    // Calcular vida segun cantidad de jugadores en la partida
    new players[32], count
    get_players(players, count)
    new iBossHP = 2500 + (count * 300)
    if (iBossHP < 4000) iBossHP = 4000

    // Modificar vida, chaleco, salto y velocidad
    set_user_health(id, iBossHP)
    set_user_armor(id, 500)
    set_user_gravity(id, 0.6)
    set_user_maxspeed(id, 420.0)

    // Aura roja brillante
    set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 25)

    // Otorgar escopeta automatica XM1014 y Deagle con municion completa
    give_item(id, "weapon_xm1014")
    cs_set_user_bpammo(id, CSW_XM1014, 100)
    give_item(id, "weapon_deagle")
    cs_set_user_bpammo(id, CSW_DEAGLE, 100)

    new szName[32]
    get_user_name(id, szName, charsmax(szName))

    // Mensaje en pantalla
    set_hudmessage(255, 0, 0, -1.0, 0.25, 1, 3.5, 3.5)
    show_hudmessage(0, "¡%s ES AHORA UN BOSS!^nVIDA: %d HP^n(Permanente entre rondas)", szName, iBossHP)

    client_print(0, print_chat, "^4[BOSS MOD]^1 ¡^3%s^1 es un ^4BOSS^1 con ^3%d HP^1 y escopeta infinita!", szName, iBossHP)
}

// =========================================================================
// MENU PRINCIPAL AL ESCRIBIR "boss"
// =========================================================================
public cmd_OpenBossMenu(id)
{
    if (!is_user_alive(id))
    {
        client_print(id, print_chat, "^4[BOSS MOD]^1 Debes estar vivo para usar el comando boss.")
        return PLUGIN_HANDLED
    }

    new menu = menu_create("\y=== \rMODO BOSS (MULTI-BOSS PERMANENTE) \y===", "menu_BossHandler")

    if (g_bIsBoss[id])
        menu_additem(menu, "Ya eres Boss \y(Rellenar vida a 5000 HP)", "1")
    else
        menu_additem(menu, "Convertirme en BOSS \y(Shotgun Infinita + Permanente)", "1")

    menu_additem(menu, "Convertir a un BOT en Boss \y(+1 Boss)", "2")
    menu_additem(menu, "Añadir BOT Terrorista \y(bot_add_t)", "4")
    menu_additem(menu, "Añadir BOT Anti-Terrorista \y(bot_add_ct)", "5")
    menu_additem(menu, "Expulsar a TODOS los Bots \y(bot_kick)", "6")
    menu_additem(menu, "\dDejar de ser Boss \y(Volver a normal)", "3")

    menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
    menu_display(id, menu, 0)
    return PLUGIN_HANDLED
}

public menu_BossHandler(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    new data[6], iName[64], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), iName, charsmax(iName), callback)
    new key = str_to_num(data)
    menu_destroy(menu)

    switch (key)
    {
        case 1: cmd_MakeMeBoss(id)
        case 2: cmd_MakeBotBoss(id)
        case 3: cmd_StopBossMode(id)
        case 4: cmd_AddBotT(id)
        case 5: cmd_AddBotCT(id)
        case 6: cmd_KickBots(id)
    }

    return PLUGIN_HANDLED
}

// 1. TRANSFORMAR AL JUGADOR EN BOSS PERMANENTE
public cmd_MakeMeBoss(id)
{
    if (!id || !is_user_alive(id))
    {
        client_print(id, print_chat, "^4[BOSS MOD]^1 Debes estar vivo para ser el Boss.")
        return PLUGIN_HANDLED
    }

    ApplyBossBuffs(id)
    client_print(id, print_chat, "^4[BOSS MOD]^2 ¡Eres un Boss! Mantendras tu status y vida en las siguientes rondas.")
    return PLUGIN_HANDLED
}

// 2. TRANSFORMAR A UN BOT EN BOSS
public cmd_MakeBotBoss(caller)
{
    new bots[32], botCount = 0
    for (new i = 1; i <= 32; i++)
    {
        // Priorizar bots vivos que aun no sean boss
        if (is_user_connected(i) && is_user_bot(i) && is_user_alive(i) && !g_bIsBoss[i])
        {
            bots[botCount++] = i
        }
    }

    // Si todos los bots ya son boss, permitir re-aplicar a cualquiera
    if (botCount < 1)
    {
        for (new i = 1; i <= 32; i++)
        {
            if (is_user_connected(i) && is_user_bot(i) && is_user_alive(i))
            {
                bots[botCount++] = i
            }
        }
    }

    if (botCount < 1)
    {
        client_print(caller, print_chat, "^4[BOSS MOD]^1 No hay bots vivos en la partida. Añade uno con ^3bot_t^1.")
        return PLUGIN_HANDLED
    }

    new chosenBot = bots[random_num(0, botCount - 1)]
    ApplyBossBuffs(chosenBot)
    return PLUGIN_HANDLED
}

// 3. DESACTIVAR MODO BOSS PARA UNO MISMO
public cmd_StopBossMode(id)
{
    if (id && is_user_connected(id))
    {
        if (!g_bIsBoss[id])
        {
            client_print(id, print_chat, "^4[BOSS MOD]^1 No eres un Boss actualmente.")
            return PLUGIN_HANDLED
        }

        g_bIsBoss[id] = false
        set_user_rendering(id)
        set_user_gravity(id, 1.0)
        set_user_maxspeed(id, 250.0)
        if (is_user_alive(id))
            set_user_health(id, 100)

        client_print(id, print_chat, "^4[BOSS MOD]^1 Ya no eres Boss. Vuelves a ser un jugador normal.")
    }
    return PLUGIN_HANDLED
}

// 4. DESACTIVAR TODOS LOS BOSSES
public cmd_StopAllBosses()
{
    for (new i = 1; i <= 32; i++)
    {
        if (g_bIsBoss[i])
        {
            g_bIsBoss[i] = false
            if (is_user_connected(i))
            {
                set_user_rendering(i)
                set_user_gravity(i, 1.0)
                set_user_maxspeed(i, 250.0)
                if (is_user_alive(i))
                    set_user_health(i, 100)
            }
        }
    }
    client_print(0, print_chat, "^4[BOSS MOD]^1 Modo Boss desactivado para TODOS los jugadores.")
    return PLUGIN_HANDLED
}

// GESTION DE BOTS
public cmd_AddBotT(id)
{
    server_cmd("bot_add_t")
    client_print(0, print_chat, "^4[BOTS]^2 Se ha añadido un Bot Terrorista.")
    return PLUGIN_HANDLED
}

public cmd_AddBotCT(id)
{
    server_cmd("bot_add_ct")
    client_print(0, print_chat, "^4[BOTS]^2 Se ha añadido un Bot CT.")
    return PLUGIN_HANDLED
}

public cmd_KickBots(id)
{
    server_cmd("bot_kick all")
    client_print(0, print_chat, "^4[BOTS]^1 Se han expulsado todos los bots.")
    return PLUGIN_HANDLED
}

// =========================================================================
// EVENTOS DE RONDA Y SPAWN (PERMANENCIA ENTRE RONDAS)
// =========================================================================
public logevent_RoundStart()
{
    // Re-aplicar buffs al inicio de la ronda para todos los que sean Boss
    set_task(0.2, "task_ReapplyAllBossBuffs")
}

public task_ReapplyAllBossBuffs()
{
    for (new i = 1; i <= 32; i++)
    {
        if (is_user_alive(i) && g_bIsBoss[i])
        {
            ApplyBossBuffs(i)
        }
    }
}

// Al reaparecer cualquier jugador
public fw_PlayerSpawn_Post(id)
{
    if (!is_user_alive(id))
        return HAM_IGNORED

    // Si este jugador era un Boss, reaplicarle los poderes de inmediato
    if (g_bIsBoss[id])
    {
        set_task(0.1, "task_ReapplyOnSpawn", id)
    }
    return HAM_IGNORED
}

public task_ReapplyOnSpawn(id)
{
    if (is_user_alive(id) && g_bIsBoss[id])
    {
        ApplyBossBuffs(id)
    }
}

// Mantener velocidad al cambiar de arma para cualquier Boss
public event_CurWeapon(id)
{
    if (1 <= id <= 32 && is_user_alive(id) && g_bIsBoss[id])
    {
        set_user_maxspeed(id, 420.0)
    }
}

// Balas infinitas en la escopeta para cualquier Boss
public fw_Shotgun_PrimaryAttack_Post(iEnt)
{
    if (!pev_valid(iEnt))
        return HAM_IGNORED

    new id = get_pdata_cbase(iEnt, OFFSET_WEAPON_OWNER, OFFSET_EXTRA_WEAPON)
    if (1 <= id <= 32 && is_user_alive(id) && g_bIsBoss[id])
    {
        cs_set_weapon_ammo(iEnt, 7)
    }
    return HAM_IGNORED
}

// =========================================================================
// MUERTE DEL BOSS (RECOMPENSA SIN PERDER EL STATUS PARA LA SIGUIENTE RONDA)
// =========================================================================
public fw_PlayerKilled_Post(victim, killer)
{
    if (1 <= victim <= 32 && g_bIsBoss[victim])
    {
        new szBossName[32], szKillerName[32]
        get_user_name(victim, szBossName, charsmax(szBossName))

        set_user_rendering(victim) // Quitar brillo mientras este muerto

        if (is_user_connected(killer) && killer != victim)
        {
            get_user_name(killer, szKillerName, charsmax(szKillerName))
            set_hudmessage(0, 255, 0, -1.0, 0.35, 1, 4.0, 4.0)
            show_hudmessage(0, "¡EL BOSS %s HA SIDO DERROTADO!^nAsesinado por: %s", szBossName, szKillerName)

            cs_set_user_money(killer, cs_get_user_money(killer) + 10000)
            client_print(0, print_chat, "^4[BOSS MOD]^2 ¡%s derroto al Boss %s y gano $10,000!", szKillerName, szBossName)
        }
        else
        {
            set_hudmessage(255, 255, 0, -1.0, 0.35, 1, 4.0, 4.0)
            show_hudmessage(0, "¡El Boss %s ha muerto!", szBossName)
        }

        // NO quitamos el status de Boss: reaparecera como Boss la siguiente ronda
        client_print(victim, print_chat, "^4[BOSS MOD]^3 Moriste en esta ronda, pero reapareceras como BOSS la proxima ronda.")
    }
    return HAM_IGNORED
}

// =========================================================================
// HUD EN TIEMPO REAL (MUESTRA LA VIDA DE TODOS LOS BOSSES ACTIVOS)
// =========================================================================
public task_ShowBossHUD()
{
    new szHUD[256], szName[32], len = 0
    new bossCount = 0

    for (new i = 1; i <= 32; i++)
    {
        if (is_user_alive(i) && g_bIsBoss[i])
        {
            bossCount++
            get_user_name(i, szName, charsmax(szName))
            new iHp = get_user_health(i)
            len += formatex(szHUD[len], charsmax(szHUD) - len, "[ BOSS: %s | %d HP ]^n", szName, iHp)
        }
    }

    if (bossCount > 0)
    {
        set_hudmessage(255, 50, 50, -1.0, 0.05, 0, 0.0, 0.6, 0.0, 0.0, -1)
        show_hudmessage(0, "%s", szHUD)
    }
}
