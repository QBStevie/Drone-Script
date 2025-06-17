# Drone-Script
Spectator style drone script for FiveM servers. Works with both **ESX** and **QBCore**.

## Installation
1. Drop the `m1_drn` folder into your server's `resources` directory.
2. Add `ensure m1_drn` to your `server.cfg`.
3. Make sure `ox_inventory` is installed for the drone item.

## Configuration
Adjust settings inside `config.lua` to tweak speeds, return speed, signal range, battery drain and taser cooldown.
You can also set thresholds for automatically returning the drone when battery or signal is low.
`config.lua` also contains options for the new autonomous patrol radius and speed.

## Controls
- **F10** – Toggle or pick up the drone
- **G** – Cycle drone modes
- **H** – Cycle vision modes
- **E** – Context action (scan/tase/boost/track)
- **F6** – Give yourself a drone (test command)
- **Return Mode** – Cycle modes with `G` until RETURN is shown to have the drone automatically fly back to you
- **Patrol Mode** – Cycle modes with `G` until PATROL is shown to have the drone circle around its start position
- The drone will auto-return when battery or signal falls below configured thresholds

## Changelog
### 1.2.0
- Added configuration file
- Added battery mechanic with HUD indicator
- Updated manifest version

### 1.3.0
- Added new **Return** mode (cycle with `G`) that automatically flies the drone
  back to your position and stores it when close enough

### 1.4.0
- Drone automatically returns when battery or signal drops below configured thresholds

### 1.5.0
- Added **Patrol** mode for autonomous circular patrols

Any questions/problems contact me via discord: notacuteegirl

Model is included in the file. Model was not made by me: https://www.gta5-mods.com/vehicles/dji-mavic-pro-add-on (drone model)
