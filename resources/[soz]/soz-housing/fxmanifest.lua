fx_version "cerulean"
games {"gta5"}
lua54 "yes"

description "soz-housing"

shared_scripts {"config.lua", "classes/*.lua", "shared/*.lua"}

client_script {"@menuv/menuv.lua", "client/main.lua", "client/functions.lua", "client/property.lua", "client/menu.lua"}

server_script {"@oxmysql/lib/MySQL.lua", "server/*.lua"}

dependencies {"oxmysql", "qb-target", "menuv"}
