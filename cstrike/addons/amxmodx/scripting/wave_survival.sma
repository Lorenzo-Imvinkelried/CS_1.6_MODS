#include <amxmodx>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>

#define PLUGIN  "Wave Survival Co-op"
#define VERSION "1.0"
#define AUTHOR  "Antigravity"

// Estado de la partida
new g_iWave = 1

// Atributos y mejoras de cada jugador humano (1..32)
new g_iLevel[33]
new g_iExp[33]
new g_iHpLevel[33]       // +50 HP por nivel
new g_iDamageLevel[33]   // +20% daño por nivel
new g_iRegenLevel[33]    // +5 HP cada 2 seg
new g_iSpeedLevel[33]    // +25 velocidad
new bool:g_bInfiniteAmmo[33]

// Offsets para armas
#define OFFSET_WEAPON_OWNER 41
#define OFFSET_EXTRA_WEAPON 4

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    // Ajustar servidor
    set_cvar_float("sv_maxspeed", 1000.0)
    set_cvar_num("mp_autoteambalance", 0)
    set_cvar_num("mp_limitteams", 0)

    // Eventos de ronda
    register_logevent("logevent_RoundStart", 2, "1=Round_Start")
    register_logevent("logevent_RoundEnd", 2, "1=Round_End")
    register_event("CurWeapon", "event_CurWeapon", "be", "1=1")

    // Hooks de combate
    RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Pre")
    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
    RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)

    // Hook para municion infinita si esta comprada
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ak47", "fw_PrimaryAttack_Post", 1)
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m4a1", "fw_PrimaryAttack_Post", 1)
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_awp", "fw_PrimaryAttack_Post", 1)
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_PrimaryAttack_Post", 1)
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_deagle", "fw_PrimaryAttack_Post", 1)
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_mp5navy", "fw_PrimaryAttack_Post", 1)

    // COMANDO ULTRA RAPIDO PARA INICIAR: "go" o "start"
    register_clcmd("say go", "cmd_QuickStart")
    register_clcmd("say /go", "cmd_QuickStart")
    register_clcmd("say start", "cmd_QuickStart")
    register_clcmd("say /start", "cmd_QuickStart")
    register_clcmd("say oleada", "cmd_QuickStart")
    register_clcmd("go", "cmd_QuickStart")
    register_clcmd("start", "cmd_QuickStart")

    // COMANDOS ULTRA CORTOS PARA EL MENU: "m" o "b" (1 sola letra)
    register_clcmd("say m", "cmd_OpenUpgradeMenu")
    register_clcmd("say /m", "cmd_OpenUpgradeMenu")
    register_clcmd("say b", "cmd_OpenUpgradeMenu")
    register_clcmd("say /b", "cmd_OpenUpgradeMenu")
    register_clcmd("say menu", "cmd_OpenUpgradeMenu")
    register_clcmd("say /menu", "cmd_OpenUpgradeMenu")
    register_clcmd("say mejoras", "cmd_OpenUpgradeMenu")
    register_clcmd("say upgrade", "cmd_OpenUpgradeMenu")
    register_clcmd("say armas", "cmd_OpenWeaponMenu")
    register_clcmd("m", "cmd_OpenUpgradeMenu")

    // COMANDO ULTRA RAPIDO PARA REINICIAR: "r"
    register_clcmd("say r", "cmd_ResetWaves")
    register_clcmd("say /r", "cmd_ResetWaves")
    register_clcmd("say reset", "cmd_ResetWaves")

    // Tareas repetitivas (HUD y Regeneracion)
    set_task(1.0, "task_ShowHUD", _, _, _, "b")
    set_task(2.0, "task_Regeneration", _, _, _, "b")
}

public client_putinserver(id)
{
    g_iLevel[id] = 1
    g_iExp[id] = 0
    g_iHpLevel[id] = 0
    g_iDamageLevel[id] = 0
    g_iRegenLevel[id] = 0
    g_iSpeedLevel[id] = 0
    g_bInfiniteAmmo[id] = false
}

// =========================================================================
// 1. GESTION DE OLEADAS Y SPAWNS
// =========================================================================
public logevent_RoundStart()
{
    new szMsg[128]
    if (g_iWave % 5 == 0)
    {
        formatex(szMsg, charsmax(szMsg), "¡¡ALERTA!! ¡OLEADA %d (RONDA DE BOSS)!^n¡Los enemigos son monstruos gigantes!", g_iWave)
        set_hudmessage(255, 0, 0, -1.0, 0.25, 1, 5.0, 5.0)
    }
    else
    {
        formatex(szMsg, charsmax(szMsg), "--- OLEADA %d INICIADA ---^n¡Eliminen a todos los enemigos para avanzar!", g_iWave)
        set_hudmessage(0, 200, 255, -1.0, 0.25, 1, 4.0, 4.0)
    }
    show_hudmessage(0, szMsg)
}

public logevent_RoundEnd()
{
    // Si los CTs (humanos) sobrevivieron y ganaron la ronda:
    new tsAlive = 0
    for (new i = 1; i <= 32; i++)
    {
        if (is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_T)
            tsAlive++
    }

    if (tsAlive == 0)
    {
        g_iWave++
        // Dar recompensa de dinero y XP a todos los humanos
        for (new i = 1; i <= 32; i++)
        {
            if (is_user_connected(i) && !is_user_bot(i))
            {
                cs_set_user_money(i, cs_get_user_money(i) + 2500)
                AddExp(i, 200)
            }
        }

        set_hudmessage(0, 255, 0, -1.0, 0.35, 1, 5.0, 5.0)
        show_hudmessage(0, "¡¡OLEADA SUPERADA CON EXITO!!^nRecompensa: +$2,500 y +200 EXP^nPreparandose para la Oleada %d...", g_iWave)
        client_print(0, print_chat, "^4[OLEADAS]^2 ¡Excelente trabajo! Oleada %d completada. Escribe ^3menu^2 para mejorar.", g_iWave - 1)
    }
}

// Al reaparecer cualquier jugador
public fw_PlayerSpawn_Post(id)
{
    if (!is_user_alive(id))
        return HAM_IGNORED

    new CsTeams:team = cs_get_user_team(id)

    // SI ES TERRORISTA (BOT / ENEMIGO DE LA OLEADA)
    if (team == CS_TEAM_T)
    {
        // La vida del enemigo escala con la oleada
        new enemyHP
        if (g_iWave % 5 == 0)
        {
            // Ronda de BOSS cada 5 oleadas
            enemyHP = 500 + (g_iWave * 150)
            set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 25) // Brillo rojo
            set_user_maxspeed(id, 320.0)
            give_item(id, "weapon_m249")
            cs_set_user_bpammo(id, CSW_M249, 200)
        }
        else
        {
            // Enemigo normal
            enemyHP = 100 + (g_iWave * 30)
            set_user_rendering(id)
            set_user_maxspeed(id, 250.0 + (g_iWave * 5.0))
        }

        set_user_health(id, enemyHP)
        set_user_armor(id, 100 + (g_iWave * 15))
    }
    // SI ES CT (HUMANO)
    else if (team == CS_TEAM_CT && !is_user_bot(id))
    {
        // Aplicar mejoras acumuladas del jugador
        new maxHP = 100 + (g_iHpLevel[id] * 50)
        set_user_health(id, maxHP)
        set_user_armor(id, 100)

        if (g_iSpeedLevel[id] > 0)
        {
            set_user_maxspeed(id, 250.0 + (g_iSpeedLevel[id] * 25.0))
        }

        client_print(id, print_chat, "^4[OLEADAS]^1 Escribe ^3menu^1 para abrir la tienda de mejoras o ^3armas^1 para comprar equipamiento.")
    }

    return HAM_IGNORED
}

public event_CurWeapon(id)
{
    if (!is_user_alive(id) || is_user_bot(id))
        return

    if (g_iSpeedLevel[id] > 0)
    {
        set_user_maxspeed(id, 250.0 + (g_iSpeedLevel[id] * 25.0))
    }
}

// =========================================================================
// 2. SISTEMA DE DAÑO Y EXPERIENCIA (RPG)
// =========================================================================
// Multiplicador de daño por nivel de ataque
public fw_TakeDamage_Pre(victim, inflictor, attacker, Float:damage, damage_bits)
{
    if (!is_user_connected(attacker) || is_user_bot(attacker))
        return HAM_IGNORED

    // Si el atacante tiene mejoras de daño
    if (g_iDamageLevel[attacker] > 0)
    {
        new Float:multiplier = 1.0 + (float(g_iDamageLevel[attacker]) * 0.20) // +20% por nivel
        SetHamParamFloat(4, damage * multiplier)
    }

    return HAM_IGNORED
}

// Al matar a un enemigo
public fw_PlayerKilled_Post(victim, killer)
{
    if (!is_user_connected(killer) || is_user_bot(killer) || killer == victim)
        return HAM_IGNORED

    if (cs_get_user_team(victim) == CS_TEAM_T)
    {
        // Puntos de EXP y dinero por enemigo derrotado
        new expGained = 50 + (g_iWave * 10)
        new moneyGained = 300 + (g_iWave * 50)

        AddExp(killer, expGained)
        cs_set_user_money(killer, cs_get_user_money(killer) + moneyGained)
    }

    return HAM_IGNORED
}

// Añadir experiencia y subir de nivel
AddExp(id, amount)
{
    g_iExp[id] += amount
    new reqExp = g_iLevel[id] * 250

    if (g_iExp[id] >= reqExp)
    {
        g_iExp[id] -= reqExp
        g_iLevel[id]++

        // Curar por completo al subir de nivel
        new maxHP = 100 + (g_iHpLevel[id] * 50)
        set_user_health(id, maxHP)

        set_hudmessage(255, 215, 0, -1.0, 0.40, 1, 4.0, 4.0)
        show_hudmessage(id, "¡¡SUBISTE DE NIVEL!!^n¡Ahora eres Nivel %d!", g_iLevel[id])
        client_print(id, print_chat, "^4[NIVEL]^2 ¡Felicidades! Subiste al nivel ^3%d^2. Abre el ^3menu^2 para gastar tu dinero.", g_iLevel[id])
    }
}

// Municion infinita en disparo si compraron la mejora
public fw_PrimaryAttack_Post(iEnt)
{
    if (!pev_valid(iEnt))
        return HAM_IGNORED

    new id = get_pdata_cbase(iEnt, OFFSET_WEAPON_OWNER, OFFSET_EXTRA_WEAPON)
    if (is_user_alive(id) && g_bInfiniteAmmo[id])
    {
        cs_set_weapon_ammo(iEnt, 35)
    }
    return HAM_IGNORED
}

// Regeneracion de vida pasiva
public task_Regeneration()
{
    for (new i = 1; i <= 32; i++)
    {
        if (is_user_alive(i) && !is_user_bot(i) && g_iRegenLevel[i] > 0)
        {
            new curHP = get_user_health(i)
            new maxHP = 100 + (g_iHpLevel[i] * 50)
            if (curHP < maxHP)
            {
                new newHP = curHP + (g_iRegenLevel[i] * 5)
                if (newHP > maxHP) newHP = maxHP
                set_user_health(i, newHP)
            }
        }
    }
}

// =========================================================================
// 3. MENU DE MEJORAS Y TIENDA
// =========================================================================
public cmd_OpenUpgradeMenu(id)
{
    if (!is_user_alive(id))
    {
        client_print(id, print_chat, "^4[OLEADAS]^1 Debes estar vivo para abrir el menu de mejoras.")
        return PLUGIN_HANDLED
    }

    new szItem[128]
    new menu = menu_create("\y=== \rTIENDA DE MEJORAS CO-OP \y===", "menu_UpgradeHandler")

    formatex(szItem, charsmax(szItem), "Mas Vida Maxima \w(+50 HP) [Lvl %d] \y- $1,500", g_iHpLevel[id])
    menu_additem(menu, szItem, "1")

    formatex(szItem, charsmax(szItem), "Mas Danio de Armas \w(+20%% Danio) [Lvl %d] \y- $2,000", g_iDamageLevel[id])
    menu_additem(menu, szItem, "2")

    formatex(szItem, charsmax(szItem), "Regeneracion de Vida \w(+5 HP/2s) [Lvl %d] \y- $2,500", g_iRegenLevel[id])
    menu_additem(menu, szItem, "3")

    formatex(szItem, charsmax(szItem), "Mas Velocidad \w(+25 u/s) [Lvl %d] \y- $1,200", g_iSpeedLevel[id])
    menu_additem(menu, szItem, "4")

    formatex(szItem, charsmax(szItem), "Balas Infinitas \w(No Recargar) %s \y- $5,000", g_bInfiniteAmmo[id] ? "\d[COMPRADO]" : "")
    menu_additem(menu, szItem, "5")

    menu_additem(menu, "\r[TIENDA DE ARMAS] \wComprar armamento", "6")

    menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
    menu_display(id, menu, 0)
    return PLUGIN_HANDLED
}

public menu_UpgradeHandler(id, menu, item)
{
    if (item == MENU_EXIT || !is_user_alive(id))
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    new data[6], iName[64], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), iName, charsmax(iName), callback)
    new key = str_to_num(data)
    new money = cs_get_user_money(id)

    switch (key)
    {
        case 1: // VIDA
        {
            if (money >= 1500)
            {
                cs_set_user_money(id, money - 1500)
                g_iHpLevel[id]++
                new newMax = 100 + (g_iHpLevel[id] * 50)
                set_user_health(id, newMax)
                client_print(id, print_chat, "^4[MEJORA]^2 ¡Vida maxima aumentada a ^3%d HP^2!", newMax)
            }
            else client_print(id, print_chat, "^4[MEJORA]^1 Dinero insuficiente. Necesitas $1,500.")
        }
        case 2: // DAÑO
        {
            if (money >= 2000)
            {
                cs_set_user_money(id, money - 2000)
                g_iDamageLevel[id]++
                client_print(id, print_chat, "^4[MEJORA]^2 ¡Danio aumentado! (+%d%% de danio adicional).", g_iDamageLevel[id] * 20)
            }
            else client_print(id, print_chat, "^4[MEJORA]^1 Dinero insuficiente. Necesitas $2,000.")
        }
        case 3: // REGEN
        {
            if (money >= 2500)
            {
                cs_set_user_money(id, money - 2500)
                g_iRegenLevel[id]++
                client_print(id, print_chat, "^4[MEJORA]^2 ¡Regeneracion mejorada! (+%d HP cada 2 seg).", g_iRegenLevel[id] * 5)
            }
            else client_print(id, print_chat, "^4[MEJORA]^1 Dinero insuficiente. Necesitas $2,500.")
        }
        case 4: // VELOCIDAD
        {
            if (money >= 1200)
            {
                cs_set_user_money(id, money - 1200)
                g_iSpeedLevel[id]++
                set_user_maxspeed(id, 250.0 + (g_iSpeedLevel[id] * 25.0))
                client_print(id, print_chat, "^4[MEJORA]^2 ¡Velocidad mejorada! (Nivel %d).", g_iSpeedLevel[id])
            }
            else client_print(id, print_chat, "^4[MEJORA]^1 Dinero insuficiente. Necesitas $1,200.")
        }
        case 5: // BALAS INFINITAS
        {
            if (g_bInfiniteAmmo[id])
            {
                client_print(id, print_chat, "^4[MEJORA]^1 Ya tienes las balas infinitas compradas.")
            }
            else if (money >= 5000)
            {
                cs_set_user_money(id, money - 5000)
                g_bInfiniteAmmo[id] = true
                client_print(id, print_chat, "^4[MEJORA]^2 ¡Balas Infinitas ACTIVADAS! Dispara sin recargar.")
            }
            else client_print(id, print_chat, "^4[MEJORA]^1 Dinero insuficiente. Necesitas $5,000.")
        }
        case 6:
        {
            menu_destroy(menu)
            cmd_OpenWeaponMenu(id)
            return PLUGIN_HANDLED
        }
    }

    menu_destroy(menu)
    cmd_OpenUpgradeMenu(id) // Reabrir para seguir comprando
    return PLUGIN_HANDLED
}

// TIENDA DE ARMAS
public cmd_OpenWeaponMenu(id)
{
    new menu = menu_create("\y=== \rTIENDA DE ARMAS \y===", "menu_WeaponHandler")

    menu_additem(menu, "AK-47 Kalashnikov \y- $2,500", "1")
    menu_additem(menu, "M4A1 Carabina \y- $2,500", "2")
    menu_additem(menu, "AWP Francotirador \y- $4,750", "3")
    menu_additem(menu, "M249 Ametralladora Pesada \y- $5,500", "4")
    menu_additem(menu, "Desert Eagle \y- $650", "5")
    menu_additem(menu, "\dVolver al menu de mejoras", "6")

    menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
    menu_display(id, menu, 0)
    return PLUGIN_HANDLED
}

public menu_WeaponHandler(id, menu, item)
{
    if (item == MENU_EXIT || !is_user_alive(id))
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    new data[6], iName[64], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), iName, charsmax(iName), callback)
    new key = str_to_num(data)
    new money = cs_get_user_money(id)

    switch (key)
    {
        case 1:
        {
            if (money >= 2500)
            {
                cs_set_user_money(id, money - 2500)
                give_item(id, "weapon_ak47")
                cs_set_user_bpammo(id, CSW_AK47, 90)
                client_print(id, print_chat, "^4[ARMAS]^2 Compraste una AK-47.")
            }
            else client_print(id, print_chat, "^4[ARMAS]^1 Dinero insuficiente.")
        }
        case 2:
        {
            if (money >= 2500)
            {
                cs_set_user_money(id, money - 2500)
                give_item(id, "weapon_m4a1")
                cs_set_user_bpammo(id, CSW_M4A1, 90)
                client_print(id, print_chat, "^4[ARMAS]^2 Compraste una M4A1.")
            }
            else client_print(id, print_chat, "^4[ARMAS]^1 Dinero insuficiente.")
        }
        case 3:
        {
            if (money >= 4750)
            {
                cs_set_user_money(id, money - 4750)
                give_item(id, "weapon_awp")
                cs_set_user_bpammo(id, CSW_AWP, 30)
                client_print(id, print_chat, "^4[ARMAS]^2 Compraste un AWP.")
            }
            else client_print(id, print_chat, "^4[ARMAS]^1 Dinero insuficiente.")
        }
        case 4:
        {
            if (money >= 5500)
            {
                cs_set_user_money(id, money - 5500)
                give_item(id, "weapon_m249")
                cs_set_user_bpammo(id, CSW_M249, 200)
                client_print(id, print_chat, "^4[ARMAS]^2 Compraste una M249.")
            }
            else client_print(id, print_chat, "^4[ARMAS]^1 Dinero insuficiente.")
        }
        case 5:
        {
            if (money >= 650)
            {
                cs_set_user_money(id, money - 650)
                give_item(id, "weapon_deagle")
                cs_set_user_bpammo(id, CSW_DEAGLE, 35)
                client_print(id, print_chat, "^4[ARMAS]^2 Compraste una Desert Eagle.")
            }
            else client_print(id, print_chat, "^4[ARMAS]^1 Dinero insuficiente.")
        }
        case 6:
        {
            menu_destroy(menu)
            cmd_OpenUpgradeMenu(id)
            return PLUGIN_HANDLED
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public cmd_ResetWaves(id)
{
    g_iWave = 1
    client_print(0, print_chat, "^4[OLEADAS]^1 Las oleadas han sido reiniciadas a la Oleada 1.")
    server_cmd("sv_restart 1")
    return PLUGIN_HANDLED
}

// INICIO RAPIDO: Escribe "go" en el chat y se configura todo solo!
public cmd_QuickStart(id)
{
    g_iWave = 1

    // 1. Configurar servidor para cooperativo (Sin balance forzado)
    server_cmd("mp_autoteambalance 0")
    server_cmd("mp_limitteams 0")

    // 2. Mover bots a Terroristas como oleadas
    server_cmd("bot_join_after_player 0")
    server_cmd("bot_join_team t")
    server_cmd("bot_quota 9")

    // 3. Mover a todos los jugadores humanos a CT (supervivientes)
    new players[32], count
    get_players(players, count)
    for (new i = 0; i < count; i++)
    {
        new target = players[i]
        if (is_user_connected(target) && !is_user_bot(target))
        {
            cs_set_user_team(target, CS_TEAM_CT, CS_DONTCHANGE)
        }
    }

    client_print(0, print_chat, "^4[OLEADAS]^2 ¡Partida configurada! Humanos en CT vs Bots en T. Oleada 1 iniciada.")
    server_cmd("sv_restart 1")
    return PLUGIN_HANDLED
}

// =========================================================================
// 4. HUD EN TIEMPO REAL
// =========================================================================
public task_ShowHUD()
{
    new tsAlive = 0
    for (new i = 1; i <= 32; i++)
    {
        if (is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_T)
            tsAlive++
    }

    for (new i = 1; i <= 32; i++)
    {
        if (is_user_connected(i) && !is_user_bot(i))
        {
            new curHP = is_user_alive(i) ? get_user_health(i) : 0
            new maxHP = 100 + (g_iHpLevel[i] * 50)
            new reqExp = g_iLevel[i] * 250

            // Mostrar estado arriba a la izquierda
            set_hudmessage(0, 220, 255, 0.02, 0.20, 0, 0.0, 1.1, 0.0, 0.0, -1)
            show_hudmessage(i, "[ OLEADA %d | ENEMIGOS: %d ]^nNivel: %d (EXP: %d/%d)^nVida: %d/%d HP | Danio: +%d%%",
                g_iWave, tsAlive, g_iLevel[i], g_iExp[i], reqExp, curHP, maxHP, g_iDamageLevel[i] * 20)
        }
    }
}
