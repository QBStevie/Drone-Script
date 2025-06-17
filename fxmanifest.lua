fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'M1-DEV'
description 'Spectator-mode Drone with HUD, Battery & Scanner (ESX/QBCore)'
version '1.5.0'

shared_scripts {
  '@es_extended/imports.lua',
  '@ox_lib/init.lua',
  'config.lua'
}

client_scripts {
  'client/client.lua'
}

server_scripts {
  '@mysql-async/lib/MySQL.lua',
  'server/server.lua',
  'server/commands.lua'
}

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/style.css',
  'html/drone.js',
  'html/Drone.mp3',
  'data/handling.meta',
  'data/vehicles.meta',
  'stream/rcmavic.yft',
  'stream/rcmavic_hi.yft',
  'stream/rcmavic.ytd'
}

data_file 'HANDLING_FILE' 'data/handling.meta'
data_file 'VEHICLE_METADATA_FILE' 'data/vehicles.meta'
