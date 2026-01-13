fx_version 'cerulean'

game 'gta5'

name 'polkald'
author 'Mattrick Olesen'
description 'LB Phone police contact app (vRP)'
version '1.0.0'

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/style.css',
  'html/app.js'
}

shared_script 'config.lua'

client_script 'client.lua'

server_scripts {
  '@vrp/lib/utils.lua',
  'server.lua'
}
