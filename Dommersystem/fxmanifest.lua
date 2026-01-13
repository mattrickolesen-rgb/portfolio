fx_version 'cerulean'
game 'gta5'

author 'Mattrick Olesen'
description 'Dommersystem (vRP1) med NUI soegning'

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/style.css',
  'html/app.js'
}

client_scripts {
  'client.lua'
}

server_scripts {
  '@vrp/lib/utils.lua',
  'config.lua',
  'server.lua'
}
