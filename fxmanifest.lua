fx_version 'cerulean'
game 'gta5'
lua54 'yes'
shared_script '@es_extended/imports.lua'
author 'LFScripts, xLaugh, Firgyy'
shared_scripts {
    'config.lua'
}

client_scripts {
    'loc/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'loc/server.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    'ui/faggio.webp',
    'ui/kalahari.webp'
}
