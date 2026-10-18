# Counter-Strike 1.6 - Custom AMX Mod X Mods

Colección de mods personalizados y minijuegos para **Counter-Strike 1.6** desarrollados en **Pawn** sobre el framework **AMX Mod X**.

---

## 🎮 Mods Incluidos

### 1. 👹 Mod Boss (Juggernaut Multi-Boss)
Permite transformar a un jugador humano o a un bot en un **Boss Juggernaut** con atributos aumentados, regeneración, brillo especial y escopeta con munición infinita. El resto del servidor debe cooperar para derrotarlo.

* **Características:**
  * Salud aumentada masiva y velocidad configurable.
  * Munición infinita automática para escopetas (`xm1014` y `m3`).
  * Respaldo y persistencia entre rondas.
  * Totalmente controlable por menú interactivo o chat.
* **Comandos en chat:**
  * `say /boss` o `say boss`: Abre el menú interactivo del Boss.
  * `say boss me` / `say boss yo`: Te convierte en Boss inmediatamente.
  * `say boss bot`: Convierte a un bot al azar en Boss.
  * `say noboss` o `say normal`: Vuelve al estado de jugador normal.
  * `say noboss all`: Cancela el modo Boss para todos.
  * `say bot` o `say /bot`: Añade un bot al equipo Terrorista.

---

### 2. ⚡ Crazy Powers Mod (Menú de Superpoderes)
Menú interactivo individual donde cada jugador puede activar y desactivar superpoderes de forma independiente sin afectar a los demás.

* **Poderes disponibles:**
  * 🦘 **Baja Gravedad:** Salta alto estilo gravedad lunar.
  * 🏃 **Super Velocidad:** Corre al doble de velocidad.
  * 🔫 **Disparo Rápido (Fast Fire):** Reduce drásticamente el retardo entre disparos en todas las armas.
  * 🛡️ **Godmode:** Inmunidad contra cualquier daño.
* **Comandos en chat y consola:**
  * `say /menu` o `say menu`
  * `say /poderes` o `say poderes`
  * Comando de consola: `crazy_menu` (puedes bindearlo: `bind v crazy_menu`)

---

### 3. 🧟 Wave Survival Co-op Mod
Mod cooperativo de oleadas de supervivencia estilo horda. Los jugadores humanos se unen para enfrentar oleadas progresivamente más difíciles de bots con escalado de vida, daño y velocidad.

* **Características:**
  * Sistema de niveles y experiencia por baja de enemigo.
  * Tienda de mejoras permanentes: Vida máxima, porcentaje de daño, regeneración pasiva y velocidad.
  * Munición infinita desbloqueable.
* **Comandos:**
  * `say /shop`, `say shop`, `say /tienda`, `say /upgrades`: Abre la tienda de mejoras.

---

## 📂 Estructura del Repositorio

```text
├── README.md
└── cstrike/
    └── addons/
        └── amxmodx/
            ├── plugins/
            │   ├── boss_mod.amxx
            │   ├── crazy_powers.amxx
            │   └── wave_survival.amxx
            └── scripting/
                ├── boss_mod.sma
                ├── crazy_powers.sma
                ├── wave_survival.sma
                ├── compilar_boss.bat
                ├── compilar_crazy.bat
                └── compilar_wave.bat
```

---

## 🚀 Instalación en Counter-Strike 1.6

1. Asegúrate de tener instalado **AMX Mod X** en tu servidor o cliente de Counter-Strike 1.6.
2. Copia la carpeta `cstrike` a la raíz de tu instalación de Counter-Strike 1.6.
3. Abre el archivo de configuración `cstrike/addons/amxmodx/configs/plugins.ini`.
4. Agrega los plugins que desees activar al final del archivo:
   ```ini
   ; Mods Personalizados
   boss_mod.amxx
   crazy_powers.amxx
   wave_survival.amxx
   ```
5. Guarda el archivo e inicia una partida o servidor local.

---

## 🛠️ Compilación desde Código Fuente (.sma)

Cada mod incluye su archivo batch `.bat` que utiliza el compilador oficial de AMX Mod X (`amxxpc.exe`):
* Ejecuta `compilar_boss.bat` para compilar `boss_mod.sma`.
* Ejecuta `compilar_crazy.bat` para compilar `crazy_powers.sma`.
* Ejecuta `compilar_wave.bat` para compilar `wave_survival.sma`.

El binario compilado `.amxx` se depositará automáticamente en la carpeta `addons/amxmodx/plugins/`.
