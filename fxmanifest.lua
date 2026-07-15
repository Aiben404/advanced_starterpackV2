fx_version 'cerulean'
game 'gta5'

author 'Snowman'
description 'Advanced New Citizen starter pack for ESX'
version '1.2.0'

lua54 'yes'

shared_script 'config.lua'

client_script 'client/main.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/script.js',
    'web/img/*.png',
    'web/img/*.jpg',
    'web/img/*.jpeg',
    'web/img/*.webp'
}

dependencies {
    'es_extended',
    'oxmysql',
    'ox_inventory',
    'ox_target'
}
