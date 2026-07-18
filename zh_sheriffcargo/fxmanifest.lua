fx_version "cerulean"
lua54 "yes"

games {"rdr3"}

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author "Zhonix"
name "qq-cargo"
description "Manual or scheduled cargo wagon event for VORP RedM servers."
version "1.0.0"

ui_page 'html/index.html'

files {
   'html/index.html',
   'html/style.css',
   'html/app.js',
   'html/IMFellEnglish-Regular.ttf',
   'html/img/*.png',
   'html/item/*.png',
   'html/item/*.jpg',
   'html/item/*.jpeg',
   'html/item/*.webp'
}

client_scripts {
   'config.lua',
   'client.lua'
}

server_scripts {
   'config.lua',
   'server.lua'
}

dependencies {
   'vorp_core',
   'vorp_inventory'
}

escrow_ignore{
   'config.lua',
   'README.md'
}
