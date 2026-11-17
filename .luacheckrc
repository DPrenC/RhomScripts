std = "lua51"
max_line_length = false

globals = {
  "RhomScripts",
  "RhomLoader",
  "RL_vars",
  "gmcp",
  "gmod",
  "getConnectionInfo",
  "getFontSize",
  "isActive",
  "enableKey",
  "disableKey",
  "RL_salvar_opciones",
  "RL_fijar_opcion",
  "RL_gui_reinicializar",
  "RL_gui_fijar_tamanyo_fuente_consola",
  "RL_macros_activar",
  "RL_inicializar_MSP",
  "RL_msp_stop_all",
  "RL_discord_inicializar",
  "getPackages",
  "installPackage",
  "downloadFile",
  "killAnonymousEventHandler",
  "killTimer",
  "killAlias",
  "killKey",
  "killTrigger",
  "feedTriggers",
  "tempTimer",
  "RhomScriptsBasePath",
  "mudlet",
  "lfs",
  "yajl",
  "matches",
  "line",
  "tempKey",
  "tempAlias",
  "tempRegexTrigger",
  "registerAnonymousEventHandler",
  "raiseEvent",
  "send",
  "announce",
  "ansi2string",
  "echo",
  "cecho",
  "playSoundFile",
  "stopSounds",
  "getMudletHomeDir",
  "getProfileName",
  "getLastLineNumber",
  "getLines",
  "setClipboardText",
  "getClipboardText",
}

read_globals = {
  "table.load",
  "table.save",
}

files["scripts/**/*.lua"] = {
  globals = { "validateRegex", "matchRegex", "TEST_PROFILE_PATH", "killAnonymousEventHandler" },
}

files["scripts/tests/mudlet_mock.lua"] = {
  globals = { "table.save", "table.load", "validateRegex", "matchRegex", "TEST_PROFILE_PATH", "killAnonymousEventHandler" },
}

files["scripts/tests/mudlet_integration.lua"] = {
  globals = { "RHOM_TEST_ROOT", "RHOM_TEST_RESULT", "RHOM_TEST_PACKAGE", "RHOM_TEST_OFFICIAL_PACKAGE", "RHOM_TEST_PROFILE", "RHOM_TEST_CLIPBOARD", "getMudletVersion", "getPlayingSounds", "installPackage" },
}

files["scripts/tests/wxlua_probe.lua"] = {
  globals = { "RHOM_WX_ROOT", "RHOM_WX_RESULT", "RHOM_WX_PROFILE", "RHOM_WX_INTERACTIVE", "getMudletVersion" },
}

files["scripts/tests/configurador_wx.lua"] = {
  globals = { "RHOM_WX_ROOT", "RHOM_WX_RESULT", "RHOM_WX_PROFILE", "RHOM_WX_INTERACTIVE", "getMudletVersion" },
}

files["scripts/tests/cffi_probe.lua"] = {
  globals = { "RHOM_WX_ROOT", "RHOM_WX_RESULT", "RHOM_WX_PROFILE", "RHOM_WX_INTERACTIVE", "getMudletVersion" },
}
