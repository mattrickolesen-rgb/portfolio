fx_version 'cerulean'
game 'gta5'

author 'Mattrick Olesen'
description 'SEA Forensics Tablet (blood type, DNA, fingerprints, saliva)'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

files {
    'html/index.html',
    'html/app.js',
    'html/style.css'
}
