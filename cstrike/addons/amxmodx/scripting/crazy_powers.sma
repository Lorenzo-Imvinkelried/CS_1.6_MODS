#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN  "Crazy Powers Mod"
#define VERSION "1.0"
#define AUTHOR  "Antigravity"

// Offsets para armas y jugador (CS 1.6 Windows/Linux)
#define OFFSET_WEAPON_OWNER      41
#define OFFSET_EXTRA_WEAPON      4
#define OFFSET_NEXT_PRIMARY_ATTACK 46
#define OFFSET_PLAYER_NEXT_ATTACK  83
#define OFFSET_EXTRA_PLAYER      5

// Estados de cada poder por jugador
new bool:g_bGravity[33]
new bool:g_bSpeed[33]
new bool:g_bFastFire[33]
new bool:g_bGodmode[33]

// Lista de armas para interceptar ataque primario
new const g_szWeaponNames[][] = {
    "weapon_p228", "weapon_scout", "weapon_xm1014", "weapon_mac10", "weapon_aug",
    "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil",
    "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy",
    "weapon_m249", "weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1",
    "weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_p90"
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    set_cvar_float("sv_maxspeed", 1000.0)
    if (is_dedicated_server())
    {
        set_cvar_num("sv_lan", 0)
    }

    // Comandos de consola directa (para bindear con: bind v crazy_menu)
    register_clcmd("crazy_menu", "cmd_OpenMenu")
    register_clcmd("menu_poderes", "cmd_OpenMenu")

    // Comandos de chat (con y sin barra '/')
    register_clcmd("say /menu", "cmd_OpenMenu")
    register_clcmd("say menu", "cmd_OpenMenu")
    register_clcmd("say /poderes", "cmd_OpenMenu")
    register_clcmd("say poderes", "cmd_OpenMenu")
    register_clcmd("say /locuras", "cmd_OpenMenu")
    register_clcmd("say locuras", "cmd_OpenMenu")
    register_clcmd("say /crazy", "cmd_OpenMenu")
    register_clcmd("say crazy", "cmd_OpenMenu")
    register_clcmd("say_team /menu", "cmd_OpenMenu")
    register_clcmd("say_team menu", "cmd_OpenMenu")
    register_clcmd("say_team /poderes", "cmd_OpenMenu")
    register_clcmd("say_team poderes", "cmd_OpenMenu")

    // Comandos directos de chat (con y sin barra '/')
    register_clcmd("say /gravedad", "cmd_ToggleGravity")
    register_clcmd("say gravedad", "cmd_ToggleGravity")
    register_clcmd("say /velocidad", "cmd_ToggleSpeed")
    register_clcmd("say velocidad", "cmd_ToggleSpeed")
    register_clcmd("say /disparo", "cmd_ToggleFastFire")
    register_clcmd("say disparo", "cmd_ToggleFastFire")
    register_clcmd("say /dios", "cmd_ToggleGodmode")
    register_clcmd("say dios", "cmd_ToggleGodmode")
    register_clcmd("say /dinero", "cmd_GiveMoney")
    register_clcmd("say dinero", "cmd_GiveMoney")

    // Eventos
    register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
    RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)

    // Hook para disparar a ultra velocidad (Fast Fire)
    for (new i = 0; i < sizeof(g_szWeaponNames); i++)
    {
        RegisterHam(Ham_Weapon_PrimaryAttack, g_szWeaponNames[i], "fw_WeaponPrimaryAttack_Post", 1)
    }
}

public client_putinserver(id)
{
    g_bGravity[id] = false
    g_bSpeed[id] = false
    g_bFastFire[id] = false
    g_bGodmode[id] = false
}

public client_disconnected(id)
{
    g_bGravity[id] = false
    g_bSpeed[id] = false
    g_bFastFire[id] = false
    g_bGodmode[id] = false
}

// Al reaparecer un jugador
public fw_PlayerSpawn_Post(id)
{
    if (!is_user_alive(id))
        return HAM_IGNORED

    // Mensaje de bienvenida
    client_print(id, print_chat, "^4[PODERES]^1 Escribe ^3menu^1 o ^3/menu^1 para elegir tus poderes individuales (solo para ti).")

    // Reaplicar poderes si estaban activos
    if (g_bGravity[id])
        set_user_gravity(id, 0.25)
    else
        set_user_gravity(id, 1.0)

    if (g_bGodmode[id])
        set_user_godmode(id, 1)
    else
        set_user_godmode(id, 0)

    if (g_bSpeed[id])
        set_user_maxspeed(id, 650.0)

    return HAM_IGNORED
}

// Counter-Strike resetea la velocidad al cambiar o equipar arma
public Event_CurWeapon(id)
{
    if (!is_user_alive(id))
        return

    if (g_bSpeed[id])
    {
        set_user_maxspeed(id, 650.0)
    }
}

// Fast Fire: reducir tiempo entre disparos
public fw_WeaponPrimaryAttack_Post(iEnt)
{
    if (!pev_valid(iEnt))
        return HAM_IGNORED

    new id = get_pdata_cbase(iEnt, OFFSET_WEAPON_OWNER, OFFSET_EXTRA_WEAPON)

    if (!is_user_alive(id) || !g_bFastFire[id])
        return HAM_IGNORED

    // Tiempo de espera casi nulo entre disparos (modo ametralladora)
    set_pdata_float(iEnt, OFFSET_NEXT_PRIMARY_ATTACK, 0.05, OFFSET_EXTRA_WEAPON)
    set_pdata_float(id, OFFSET_PLAYER_NEXT_ATTACK, 0.05, OFFSET_EXTRA_PLAYER)

    // Recargar cargador automaticamente (municion infinita en clip)
    cs_set_weapon_ammo(iEnt, 35)

    return HAM_IGNORED
}

// MENU PRINCIPAL
public cmd_OpenMenu(id)
{
    if (!is_user_alive(id))
    {
        client_print(id, print_chat, "^4[MOD LOCO]^1 Debes estar vivo para abrir el menu de poderes.")
        return PLUGIN_HANDLED
    }

    new szItem[64]
    new menu = menu_create("\y=== \rMENU DE PODERES \y===^n\d(Poderes individuales - Solo para ti)", "menu_Handler")

    formatex(szItem, charsmax(szItem), "Antigravedad \w(Salto Lunar): %s", g_bGravity[id] ? "\y[ACTIVADO]" : "\d[DESACTIVADO]")
    menu_additem(menu, szItem, "1")

    formatex(szItem, charsmax(szItem), "Super Velocidad \w(Flash): %s", g_bSpeed[id] ? "\y[ACTIVADO]" : "\d[DESACTIVADO]")
    menu_additem(menu, szItem, "2")

    formatex(szItem, charsmax(szItem), "Disparo Rapido + Balas Infinitas: %s", g_bFastFire[id] ? "\y[ACTIVADO]" : "\d[DESACTIVADO]")
    menu_additem(menu, szItem, "3")

    formatex(szItem, charsmax(szItem), "Modo Dios \w(Inmortal): %s", g_bGodmode[id] ? "\y[ACTIVADO]" : "\d[DESACTIVADO]")
    menu_additem(menu, szItem, "4")

    menu_additem(menu, "Dar $16,000 \w(Dinero Maximo)", "5")
    menu_additem(menu, "\r[ACTIVAR TODO] \yModo Caos Total", "6")
    menu_additem(menu, "\d[DESACTIVAR TODO] Restaurar Normalidad", "7")

    menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
    menu_display(id, menu, 0)
    return PLUGIN_HANDLED
}

public menu_Handler(id, menu, item)
{
    if (item == MENU_EXIT || !is_user_alive(id))
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    new data[6], iName[64], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), iName, charsmax(iName), callback)
    new key = str_to_num(data)

    switch (key)
    {
        case 1: cmd_ToggleGravity(id)
        case 2: cmd_ToggleSpeed(id)
        case 3: cmd_ToggleFastFire(id)
        case 4: cmd_ToggleGodmode(id)
        case 5: cmd_GiveMoney(id)
        case 6:
        {
            g_bGravity[id] = true
            set_user_gravity(id, 0.25)
            g_bSpeed[id] = true
            set_user_maxspeed(id, 650.0)
            g_bFastFire[id] = true
            g_bGodmode[id] = true
            set_user_godmode(id, 1)
            cs_set_user_money(id, 16000)
            client_print(id, print_chat, "^4[MOD LOCO]^2 !MODO CAOS ACTIVADO! Eres un dios veloz con antigravedad y minigun.")
        }
        case 7:
        {
            g_bGravity[id] = false
            set_user_gravity(id, 1.0)
            g_bSpeed[id] = false
            set_user_maxspeed(id, 250.0)
            g_bFastFire[id] = false
            g_bGodmode[id] = false
            set_user_godmode(id, 0)
            client_print(id, print_chat, "^4[MOD LOCO]^1 Todos los poderes han sido desactivados.")
        }
    }

    menu_destroy(menu)
    // Reabrir menu para ver cambios reflejados
    cmd_OpenMenu(id)
    return PLUGIN_HANDLED
}

// COMANDOS INDIVIDUALES
public cmd_ToggleGravity(id)
{
    if (!is_user_alive(id)) return PLUGIN_HANDLED
    g_bGravity[id] = !g_bGravity[id]
    if (g_bGravity[id])
    {
        set_user_gravity(id, 0.25)
        client_print(id, print_chat, "^4[MOD LOCO]^2 Antigravedad ACTIVADA (Salto al 25%%).")
    }
    else
    {
        set_user_gravity(id, 1.0)
        client_print(id, print_chat, "^4[MOD LOCO]^1 Gravedad normal restaurada.")
    }
    return PLUGIN_HANDLED
}

public cmd_ToggleSpeed(id)
{
    if (!is_user_alive(id)) return PLUGIN_HANDLED
    g_bSpeed[id] = !g_bSpeed[id]
    if (g_bSpeed[id])
    {
        set_user_maxspeed(id, 650.0)
        client_print(id, print_chat, "^4[MOD LOCO]^2 Super Velocidad ACTIVADA (650u/s).")
    }
    else
    {
        set_user_maxspeed(id, 250.0)
        client_print(id, print_chat, "^4[MOD LOCO]^1 Velocidad normal restaurada.")
    }
    return PLUGIN_HANDLED
}

public cmd_ToggleFastFire(id)
{
    if (!is_user_alive(id)) return PLUGIN_HANDLED
    g_bFastFire[id] = !g_bFastFire[id]
    if (g_bFastFire[id])
    {
        client_print(id, print_chat, "^4[MOD LOCO]^2 Disparo Rapido + Balas Infinitas ACTIVADO.")
    }
    else
    {
        client_print(id, print_chat, "^4[MOD LOCO]^1 Disparo normal restaurado.")
    }
    return PLUGIN_HANDLED
}

public cmd_ToggleGodmode(id)
{
    if (!is_user_alive(id)) return PLUGIN_HANDLED
    g_bGodmode[id] = !g_bGodmode[id]
    if (g_bGodmode[id])
    {
        set_user_godmode(id, 1)
        client_print(id, print_chat, "^4[MOD LOCO]^2 Modo Dios (Inmortalidad) ACTIVADO.")
    }
    else
    {
        set_user_godmode(id, 0)
        client_print(id, print_chat, "^4[MOD LOCO]^1 Modo Dios DESACTIVADO.")
    }
    return PLUGIN_HANDLED
}

public cmd_GiveMoney(id)
{
    if (!is_user_alive(id)) return PLUGIN_HANDLED
    cs_set_user_money(id, 16000)
    client_print(id, print_chat, "^4[MOD LOCO]^2 Se te han otorgado $16,000!")
    return PLUGIN_HANDLED
}
