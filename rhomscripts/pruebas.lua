-------------------------------------------------------------------------------
-- MÓDULO: pruebas
-- Descripción: Módulo de pruebas para testear funcionalidad del sistema.
--              Incluye herramientas para simular entradas del MUD y triggers
--              de prueba para verificar que todo funciona correctamente.
-- Autor: RhomScripts
-- Fecha: 2026
-------------------------------------------------------------------------------

local pruebas = {}

-- ============================================================================
-- CONFIGURACIÓN DE ATAJOS DE TECLADO
-- ============================================================================

-- No se registran teclas de diagnostico para no pisar macros funcionales.
-- Las pruebas locales quedan disponibles mediante aliases.
pruebas.key_bindings = {}

-- ============================================================================
-- CONFIGURACIÓN DE TRIGGERS
-- ============================================================================

pruebas.triggers = {
  {
    pattern = "prueba",
    action = function()
      cecho("\n<green>[PRUEBA DETECTADA]<reset> El trigger de prueba se activó correctamente!\n")
    end,
    name = "trigger_prueba",
    desc = "Trigger de prueba que detecta la palabra 'prueba' en cualquier contexto"
  },
}

-- ============================================================================
-- FUNCIONES PÚBLICAS
-- ============================================================================

-------------------------------------------------------------------------------
-- FUNCIÓN: pruebas.test_trigger()
-- Descripción: Función auxiliar para probar manualmente un trigger
-- Parámetros:
--   - texto: (opcional) Texto a simular. Por defecto "esto es una prueba de triggers"
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function pruebas.test_trigger(texto)
  texto = texto or "esto es una prueba de triggers"
  raiseEvent("rhomscripts.test.line", texto)
  echo("\n[TEST] Enviado: '" .. texto .. "'\n")
end

-------------------------------------------------------------------------------
-- FUNCIÓN: pruebas.info()
-- Descripción: Muestra información sobre el módulo de pruebas
-- Parámetros: Ninguno
-- Retorno: Ninguno
-------------------------------------------------------------------------------
function pruebas.info()
  echo("\n")
  echo(string.rep("=", 60) .. "\n")
  echo("MÓDULO DE PRUEBAS\n")
  echo(string.rep("=", 60) .. "\n")
  echo("Aliases de prueba:\n")
  echo("  test trigger [texto] - Simula una linea desde el MUD\n")
  echo("  diag lector - Ejecuta diagnostico del lector\n")
  echo("\nTrigger de prueba:\n")
  echo("  Detecta la palabra 'prueba' en cualquier contexto y muestra un mensaje\n")
  echo("\nFunciones disponibles:\n")
  echo("  pruebas.test_trigger([texto]) - Envía una línea de prueba\n")
  echo("  pruebas.info() - Muestra esta información\n")
  echo(string.rep("=", 60) .. "\n")
  echo("\n")
end

-- ============================================================================
-- ALIASES DEL MÓDULO
-- ============================================================================

pruebas.aliases = {
  {
    pattern = "^test trigger(.*)$",
    action = function()
      local texto = matches[2] and matches[2]:match("^%s*(.-)%s*$")
      if texto and texto ~= "" then
        pruebas.test_trigger(texto)
      else
        pruebas.test_trigger()
      end
    end,
    name = "test_trigger",
    desc = "Envía una línea de prueba para activar triggers (uso: 'test trigger [texto]')"
  },
  {
    pattern = "^pruebas info$",
    action = function()
      pruebas.info()
    end,
    name = "pruebas_info",
    desc = "Muestra información sobre el módulo de pruebas"
  },
  {
    pattern = "^diag lector$",
    action = function()
      if RhomScripts and RhomScripts.modules and RhomScripts.modules.lector then
        RhomScripts.modules.lector.diagnostico()
      else
        print("Error: módulo lector no disponible")
      end
    end,
    name = "diag_lector",
    desc = "Ejecuta el diagnóstico del módulo lector"
  },
}

return pruebas
