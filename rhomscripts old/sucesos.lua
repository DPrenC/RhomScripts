-------------------------------------------------------------------------------
-- Modulo: sucesos
-- Migracion funcional desde Sucesos.set, Efectos.set e Items.set.
-------------------------------------------------------------------------------

local audio = require("audio")
local eventos = require("eventos")

local sucesos = {}

sucesos.inventario_completo = false

local function play(path, opts)
  audio.play(path, opts or { volume = 80 })
end

local function add_sound(triggers, pattern, sound, name, desc)
  table.insert(triggers, {
    pattern = pattern,
    action = function()
      play(sound)
    end,
    name = name,
    desc = desc or name
  })
end

local function add_event_sound(triggers, pattern, sound, name, desc)
  table.insert(triggers, {
    pattern = pattern,
    action = function()
      eventos.registrar(matches[1] or line or "")
      play(sound)
    end,
    name = name,
    desc = desc or name
  })
end

local triggers = {}

-- Abrir, cerrar y cerraduras.
add_sound(triggers, "^.*Abres .*taquilla.*\\.$", "RL/Sucesos/Abrir taquilla.wav", "abrir_taquilla")
add_sound(triggers, "^.*Abres .*puerta.*\\.$", "RL/Sucesos/Abrir puerta.wav", "abrir_puerta")
add_sound(triggers, "^.*Abres .*cofre.*\\.$", "RL/Sucesos/Abrir cofre.wav", "abrir_cofre")
add_sound(triggers, "^.*abre .*puerta.*\\.$", "RL/Sucesos/Abrir puerta.wav", "abre_puerta")
add_sound(triggers, "^.*Cierras .*taquilla.*\\.$", "RL/Sucesos/Cerrar taquilla.wav", "cerrar_taquilla")
add_sound(triggers, "^.*Cierras .*puerta.*\\.$", "RL/Sucesos/Cerrar puerta.wav", "cerrar_puerta")
add_sound(triggers, "^.*Cierras .*cofre.*\\.$", "RL/Sucesos/Cerrar cofre.wav", "cerrar_cofre")
add_sound(triggers, "^.*cierra .*puerta.*\\.$", "RL/Sucesos/Cerrar puerta.wav", "cierra_puerta")
add_sound(triggers, "^Acerrojas la cerradura de .*\\.$", "RL/Sucesos/Cerradura bloquear.wav", "cerradura_bloquear")
add_sound(triggers, "^Descerrojas la cerradura de .*\\.$", "RL/Sucesos/Cerradura desbloquear.wav", "cerradura_desbloquear")
add_sound(triggers, "^.*La puerta .* se abre\\.$", "RL/Sucesos/Abrir puerta.wav", "puerta_se_abre")
add_sound(triggers, "^.*La puerta .* se cierra\\.$", "RL/Sucesos/Cerrar puerta.wav", "puerta_se_cierra")

-- Mano, armas y equipo.
table.insert(triggers, {
  pattern = "^.*Equilibras tu .* para sostenerl.* con una sola mano\\.$",
  action = function()
    play("RL/Contador/1P.wav")
    play("RL/Sucesos/1 mano.wav")
  end,
  name = "arma_una_mano",
  desc = "Sonido de arma a una mano"
})
table.insert(triggers, {
  pattern = "^.*Pones tu mano libre sobre la empu.adura de tu .* sosteni.ndol.* a 2 manos\\.$",
  action = function()
    play("RL/Contador/2P.wav")
    play("RL/Sucesos/2 manos.wav")
  end,
  name = "arma_dos_manos",
  desc = "Sonido de arma a dos manos"
})
add_sound(triggers, "^.*Finalmente equilibras .*\\.$", "RL/Sucesos/Equilibrar.wav", "equilibrar")
add_sound(triggers, "^.*Empu.as tu .*\\.$", "RL/Sucesos/Empuñar.wav", "empunar")
add_sound(triggers, "^.*Dejas de sostener tu .*\\.$", "RL/Sucesos/Dejas de sostener.wav", "dejar_sostener")
add_sound(triggers, "^.*Desenvainas .*$", "RL/Sucesos/Desenvainar.wav", "desenvainar")
add_sound(triggers, "^.*Equilibras, con la destreza de tod. un. maestr., .*$", "RL/Sucesos/Equilibrar.wav", "equilibrar_maestro")
add_sound(triggers, "^.*Equilibras r.pidamente .*$", "RL/Sucesos/Equilibrar.wav", "equilibrar_rapido")
add_sound(triggers, "^.*Envainas tu .* en .*$", "RL/Sucesos/Envainar.wav", "envainar")
add_sound(triggers, "^.*Intercambias de mano .*$", "RL/Sucesos/Intercambiar mano.wav", "intercambiar_mano")
add_sound(triggers, "^.*Comienzas a ponerte tu.*$", "RL/Sucesos/Equiparse inicio.wav", "equiparse_inicio")
add_sound(triggers, "^.*Terminas de ponerte tu.*$", "RL/Sucesos/Equiparse fin.wav", "equiparse_fin")
add_sound(triggers, "^.*Te quitas .*$", "RL/Sucesos/Quitarse.wav", "quitarse")
add_sound(triggers, "^.*Dejas de usar .*\\.$", "RL/Sucesos/Quitarse.wav", "dejar_usar")
add_sound(triggers, "^.*Abres el frasco que contiene el elixir.*$", "RL/Sucesos/Beber pocion.wav", "beber_pocion")

-- Inventario y objetos comunes.
add_sound(triggers, "^.* coge .*$", "RL/Sucesos/Coge.mp3", "otro_coge")
add_sound(triggers, "^.* te ofrece .*$", "RL/Sucesos/Te ofrece.wav", "te_ofrece")
add_sound(triggers, "^.*Finalmente logras cargar .*$", "RL/Sucesos/Cargar.wav", "cargar")
table.insert(triggers, {
  pattern = "^Llevas demasiadas cosas y se te pueden caer\\.$",
  action = function()
    if not sucesos.inventario_completo then
      sucesos.inventario_completo = true
      play("RL/Sucesos/Inventario completo.wav")
    end
  end,
  name = "inventario_completo",
  desc = "Aviso de inventario completo"
})
table.insert(triggers, {
  pattern = "^Dejas caer .*\\.$",
  action = function()
    sucesos.inventario_completo = false
    play("RL/Sucesos/Se te cae.wav")
  end,
  name = "dejas_caer",
  desc = "Sonido al dejar caer"
})
add_sound(triggers, "^Recibes .*, pero no puedes cargar con .* y se te cae\\.$", "RL/Sucesos/Se te cae.wav", "se_te_cae")
add_sound(triggers, "^Oyes el ru.do de algo cayendo al suelo\\.$", "RL/Sucesos/Dejar oculto.wav", "dejar_oculto")
add_sound(triggers, "^\\[Recibes .+\\]\\.$", "RL/Items/Generales/Recibes.wav", "recibes_item")
add_sound(triggers, "^Coges .* de .*\\.$", "RL/Sucesos/Coger contenedor.wav", "coger_contenedor")
add_sound(triggers, "^Pones .* en .*$", "RL/Sucesos/Poner en mochila.wav", "poner_en_mochila")
add_sound(triggers, "^. Pones .* en .*$", "RL/Sucesos/Poner en mochila.wav", "poner_en_mochila_eco")
add_sound(triggers, "^Cuerpo de .*\\.$", "RL/Items/Generales/Cuerpo*2.wav", "cuerpo")
add_sound(triggers, "^.* cuerpos de .*\\.$", "RL/Items/Generales/Cuerpos*2.wav", "cuerpos")
add_sound(triggers, "^Enciendes tu Antorcha\\.$", "RL/Items/Generales/Encender antorcha.wav", "antorcha_on")
add_sound(triggers, "^Apagas tu Antorcha\\.$", "RL/Items/Generales/Apagar antorcha.wav", "antorcha_off")
add_sound(triggers, "^.*Disfraz de .*\\.$", "RL/Items/Generales/Disfraz.wav", "disfraz")
add_sound(triggers, "^Mejoras tu maestr.a en .* gracias a la experiencia adquirida durante los combates\\.$", "RL/Sucesos/Maestria.wav", "maestria_mejora")
add_sound(triggers, "^Obtienes la maestr.a en .* gracias a la experiencia adquirida durante los combates\\.$", "RL/Sucesos/Maestria.wav", "maestria_obtiene")
add_sound(triggers, "^\\[Mejoras tu maestr.a en .*\\]$", "RL/Sucesos/Maestria.wav", "maestria_mensaje")
add_event_sound(triggers, "^\\[Subes a nivel .*\\]$", "RL/Sucesos/Nivel*3.wav", "nivel_propio")
add_sound(triggers, "^.* sube de nivel\\.$", "RL/Sucesos/Nivel otro.wav", "nivel_otro")
add_sound(triggers, "^.*Te sientes restablecid.* por el poder curativo de tu .*\\.$", "RL/Sucesos/Cura recibida.wav", "cura_item")
add_event_sound(triggers, "^.* te paga .* .*\\.$", "RL/Sucesos/Te paga.wav", "te_paga")
add_sound(triggers, "^.* recupera .* .* de .* de su caja de caudales.*$", "RL/Sucesos/Recuperar monedas.wav", "recuperar_monedas")
add_sound(triggers, "^Pagas .*$", "RL/Sucesos/Pagas.wav", "pagas")
add_sound(triggers, "^Le entregas una bolsa de monedas a .*", "RL/Sucesos/Ingresar monedas.wav", "ingresar_monedas")
add_event_sound(triggers, "^.*Has iniciado la misi.n '.*'!$", "RL/Sucesos/Misión iniciada.wav", "mision_iniciada")
add_event_sound(triggers, "^.*Has completado la misi.n '.*'!$", "RL/Sucesos/Misión completada.wav", "mision_completada")
add_event_sound(triggers, "^Un nuevo hito se ha escrito en tu diario de la misi.n '.*'\\.$", "RL/Sucesos/Hito.wav", "mision_hito")
add_event_sound(triggers, "^\\[Obtienes el logro '.*' \\(.*\\)\\]$", "RL/Sucesos/Logro.wav", "logro")
add_sound(triggers, "^Ganas experiencia debido al conocimiento adquirido con tus exploraciones\\.$", "RL/Sucesos/Punto exploracion.wav", "punto_exploracion")
add_sound(triggers, "^Tu .* se rompe en mil pedazos inservibles\\.$", "RL/Sucesos/Rotura equipo.wav", "rotura_equipo")
add_sound(triggers, "^.*Te agachas\\.$", "RL/Sucesos/Agacharse.wav", "agacharse")
add_sound(triggers, "^.*Te reincorporas\\.$", "RL/Sucesos/Levantarse.wav", "levantarse")
add_sound(triggers, "^.*Te vendas tu .*\\.$", "RL/Sucesos/Vendar.wav", "vendar")
add_sound(triggers, "^.*Aplicas tu .* sobre tus heridas\\.$", "RL/Sucesos/Vendar.wav", "aplicar_venda")
add_event_sound(triggers, "^El sonido de un cuerno retumba en el entorno: .*$", "RL/Sucesos/Cuerno*2.wav", "cuerno_entorno")
add_sound(triggers, "^.* empu.a con fuerza su Cuerno.*$", "RL/Sucesos/Cuerno*2.wav", "cuerno_otro")
add_sound(triggers, "^.*Empu.as con fuerza tu Cuerno.*$", "RL/Sucesos/Cuerno*2.wav", "cuerno_propio")
add_sound(triggers, "^.* observa a su alrededor buscando algo\\.$", "RL/Sucesos/Busqueda.wav", "buscar_otro")
add_sound(triggers, "^.*Te haces consciente de la presencia de .*\\.$", "RL/Sucesos/Consciente presencia.wav", "descubrir_presencia")
add_event_sound(triggers, "^.*Descubres a .* intentando moverse en silencio!$", "RL/Sucesos/Descubierto.wav", "descubres_sigilo")
add_sound(triggers, "^.* empieza a inspeccionar la zona detenidamente\\.$", "RL/Sucesos/Busqueda.wav", "inspecciona_zona")
add_sound(triggers, "^.* detiene su b.squeda\\.$", "RL/Sucesos/Busqueda detenida.wav", "busqueda_fin_otro")
add_event_sound(triggers, "^.* descubre a .* intentando moverse en silencio!$", "RL/Sucesos/Descubierto.wav", "descubre_sigilo_otro")
add_sound(triggers, "^.*Cuidadosamente rastreas el suelo buscando algo de inter.s\\.$", "RL/Sucesos/Busqueda.wav", "rastrear")
add_sound(triggers, "^.*Buscas atentamente a tu alrededor.*$", "RL/Sucesos/Busqueda.wav", "buscar_alrededor")
add_sound(triggers, "^.*Remueves todo a tu alrededor buscando algo interesante\\.$", "RL/Sucesos/Busqueda.wav", "remover_buscar")
add_sound(triggers, "^.*Examinas toda la zona buscando algo.*$", "RL/Sucesos/Busqueda.wav", "examinar_zona")
add_sound(triggers, "^.*Buscas esforzadamente algo en tu entorno\\.$", "RL/Sucesos/Busqueda.wav", "buscar_esfuerzo")
add_sound(triggers, "^.*Empiezas a inspeccionar la zona.*$", "RL/Sucesos/Busqueda.wav", "inspeccion_inicio")
add_sound(triggers, "^.*Tu movimiento ha interrumpido la b.squeda\\.$", "RL/Sucesos/Busqueda interrumpida.wav", "busqueda_interrumpida")
add_sound(triggers, "^.*Est.s demasiado cansad. para buscar ahora\\.$", "RL/Generales/Error.wav", "buscar_cansado")
add_event_sound(triggers, "^.*Tu estatus con .* ha aumentado.*$", "RL/Sucesos/Estatus sube.wav", "estatus_sube")
add_event_sound(triggers, "^.*Tu estatus con .* ha disminu.do.*$", "RL/Sucesos/Estatus baja.wav", "estatus_baja")
add_event_sound(triggers, "^\\[Tu alineamiento ha aumentado\\]$", "RL/Sucesos/Alineamiento mejora.wav", "alineamiento_sube")
add_event_sound(triggers, "^\\[Tu alineamiento ha disminu.do\\]$", "RL/Sucesos/Alineamiento empeora.wav", "alineamiento_baja")
add_event_sound(triggers, "^Tus recientes acciones han provocado que .* aumente su confianza en ti\\.$", "RL/Sucesos/Estatus sube.wav", "confianza_sube")
add_sound(triggers, "^Veta de .*$", "RL/Sucesos/Veta.wav", "veta")
add_sound(triggers, "^.* y veta de .*$", "RL/Sucesos/Veta.wav", "veta_multiple")
add_event_sound(triggers, "^.*Se inicia la jornada de XP Doble.*$", "RL/Sucesos/XP doble inicio.wav", "xp_doble_inicio")
add_event_sound(triggers, "^- XP doble durante.*$", "RL/Sucesos/XP doble inicio.wav", "xp_doble_info")
add_event_sound(triggers, "^.*Comienza el d.a de gloria.*$", "RL/Combate/Gloria.wav", "gloria_inicio")
add_event_sound(triggers, "^.*Termina el d.a de gloria.*$", "RL/Combate/Gloria.wav", "gloria_fin")
add_sound(triggers, "^La gran puerta de piedra se abre lentamente.*$", "RL/Sucesos/Abrir puerta.wav", "gran_puerta_abre")
add_sound(triggers, "^La entrada de la monta.a se cierra lenta y pesadamente\\.$", "RL/Sucesos/Cerrar puerta.wav", "gran_puerta_cierra")
add_event_sound(triggers, "^.* canta: .*$", "RL/Sucesos/Cantar aliado*2.wav", "canta")
add_sound(triggers, "^Entierras .* bajo tierra\\.$", "RL/Sucesos/Enterrar*4.wav", "enterrar")
add_sound(triggers, "^.* entierra .* bajo tierra\\.$", "RL/Sucesos/Enterrar*4.wav", "entierra_otro")
add_sound(triggers, "^Del fondo de la taberna, te llega el siguiente rumor:$", "RL/Sucesos/Rumor.wav", "rumor")
add_event_sound(triggers, "^\\[Has completado el objetivo de saga '.*'\\]$", "RL/Sucesos/Logro.wav", "saga_objetivo")

-- Efectos generales.
add_event_sound(triggers, "^.*Tu ataque antim.gico anula parte de los hechizos de tu enemigo!$", "RL/Efectos/Antimagico.wav", "efecto_antimagico")
add_sound(triggers, "^.*Tu c.lera de verdugo golpea a .*!$", "RL/Efectos/Verdugo.wav", "efecto_verdugo")
add_sound(triggers, "^.*Ejecutas a .* con tu ataque!$", "RL/Efectos/Ejecutor.wav", "efecto_ejecutor")
add_sound(triggers, "^.*El alcance de tu arma te permite barrer a tus enemigos!$", "RL/Efectos/Barrido.wav", "efecto_barrido")
add_event_sound(triggers, "^.*Tu ataque derriba a .*$", "RL/Efectos/Derribo.wav", "efecto_derribo")
add_event_sound(triggers, "^.*El ataque de .* te derriba!$", "RL/Efectos/Derribo recibido.wav", "efecto_derribo_recibido")
add_sound(triggers, "^.* se levanta a toda prisa\\.$", "RL/Combate/Se levanta.wav", "se_levanta")
add_sound(triggers, "^.*Tu ataque provoca una horrorosa migra.a a .*!$", "RL/Efectos/Migrana.wav", "efecto_migrana")
add_sound(triggers, "^.*El ataque de .* te deja desorientad.*!$", "RL/Efectos/Desorientar recibido.wav", "desorientar_recibido")
add_sound(triggers, "^Embobad.* y desorientad.* te mueves sin ver saber muy bien por d.nde vas\\.$", "RL/Efectos/Desorientado.wav", "desorientado")
add_sound(triggers, "^.*Tu ataque desorienta a .*!$", "RL/Efectos/Desorientar.wav", "desorientar")
add_sound(triggers, "^Tu cabeza se despeja y dejas de estar desorientad.*$", "RL/Efectos/Efecto off.wav", "desorientar_off")
add_sound(triggers, "^Tras beber la poci.n, notas un cosquilleo por todo el cuerpo\\.$", "RL/Efectos/Celeridad on.wav", "celeridad_on")
add_sound(triggers, "^Tu capacidad de movimiento vuelve a su estado normal\\.$", "RL/Efectos/Celeridad off.wav", "celeridad_off")
add_sound(triggers, "^.*Tus ataques envuelven a .* en luz!$", "RL/Efectos/Iluminacion on.wav", "iluminacion_on")
add_sound(triggers, "^Tu efecto de iluminaci.n que afectaba a .* se termina\\.$", "RL/Efectos/Iluminacion off.wav", "iluminacion_off")
add_sound(triggers, "^.*Tu .* te entrega la energ.a de .*!$", "RL/Efectos/Sanguijuela.wav", "sanguijuela")
add_sound(triggers, "^.* parece haber perdido la visi.n.*$", "RL/Efectos/Ceguera.wav", "ceguera")
add_sound(triggers, "^Tu capacidad destructiva vuelve a su estado normal\\.$", "RL/Efectos/Dano.wav", "dano_off")
add_sound(triggers, "^.*Tu .* ralentiza a .*!$", "RL/Efectos/Ralentizar.wav", "ralentizar")
add_sound(triggers, "^Inspirado por tus camaradas te sientes reforzado para la guerra\\.$", "RL/Efectos/Inspiracion on.wav", "inspiracion_on")
add_sound(triggers, "^.*El ind.mito aullido te enaltece!$", "RL/Efectos/Inspiracion on.wav", "inspiracion_aullido")
add_sound(triggers, "^Sientes como ha finalizado el efecto inspirador de tus camaradas\\.$", "RL/Efectos/Inspiracion off.wav", "inspiracion_off")

-- Items especiales frecuentes.
add_sound(triggers, "^Tu Anillo Antim.gico comienza a calentarse y chispear en tu mano\\.$", "RL/Items/Anillo antimagico inicio.wav", "anillo_antimagico")
add_sound(triggers, "^.*Un refulgente destello de tu Lucero del Sol Resplandeciente ciega por completo a .*!$", "RL/Hechizos/Cegar.wav", "lucero_cegar")
add_sound(triggers, "^Tocas la aquamarina de tu Cintur.n Robacuraciones.*$", "RL/Items/Robacuraciones on.wav", "robacuraciones_on")
add_sound(triggers, "^El aura m.gica de tu cintur.n se desvanece tan r.pido como vino\\.$", "RL/Items/Robacuraciones off.wav", "robacuraciones_off")
add_event_sound(triggers, "^.* toca la aquamarina de su Cintur.n Robacuraciones.*$", "RL/Items/Robacuraciones ajeno.wav", "robacuraciones_ajeno")
add_sound(triggers, "^El Ojo del cintur.n brilla con fuerza dispersando.*$", "RL/Items/Contemplador rebotar 1.wav", "contemplador_rebotar_1")
add_sound(triggers, "^.*El Ojo de tu cintur.n brilla y fuerza al hechizo.*$", "RL/Items/Contemplador rebotar 2.wav", "contemplador_rebotar_2")
add_sound(triggers, "^Un flash de energ.a blanca surge del Ojo del cintur.n.*$", "RL/Items/Contemplador disipar.wav", "contemplador_disipar")
add_sound(triggers, "^Se.alas a tu objetivo con Martillo del Trueno.*$", "RL/Items/Martillo trueno.wav", "martillo_trueno_1")
add_sound(triggers, "^Blandes con fuerza tu Martillo del Trueno.*$", "RL/Items/Martillo trueno.wav", "martillo_trueno_2")
add_sound(triggers, "^Tocas la joya .* de tus Botas de Cuero de Drag.n Negro.*$", "RL/Items/Botas dragon1.wav", "botas_dragon_on")
add_sound(triggers, "^Los efectos de Botas de Cuero de Drag.n Negro se terminan\\.$", "RL/Items/Botas dragon2.wav", "botas_dragon_off")
add_sound(triggers, "^.*Murmullas unas palabras de poder y acaricias tu Anillo del H.roe .*$", "RL/Items/Anillo heroe1.wav", "anillo_heroe_1")
add_sound(triggers, "^.*El poder de tu Anillo del H.roe .* inunda tu cuerpo.*$", "RL/Items/Anillo heroe2.wav", "anillo_heroe_2")
add_sound(triggers, "^.*Ante la necesidad de alimentarte, muerdes tu Brazalete de Kraken.*$", "RL/Sucesos/Cura recibida.wav", "brazalete_kraken_propio")
add_sound(triggers, "^.* muerde su Brazalete de Kraken.*$", "RL/Hechizos/Se cura.wav", "brazalete_kraken_otro")
add_sound(triggers, "^\\[Tu Trabajo duro te bonifica con .* de oficio\\]$", "RL/Items/Servidumbre.wav", "servidumbre")
add_sound(triggers, "^La magia regenerativa de tu Brazalete del dolor velado termina.*$", "RL/Items/Velado.wav", "velado")
add_sound(triggers, "^La Espada Aullante comienza a silbar\\.$", "RL/Items/Espada aullante 1.wav", "espada_aullante_1")
add_sound(triggers, "^.* se alza del cad.ver de tu enemigo.*$", "RL/Items/Servidumbre.wav", "muerto_viviente")
add_sound(triggers, "^.*Tus ataques liberan un escalofriante aullido.*$", "RL/Items/Espada aullante 2.wav", "espada_aullante_2")
add_sound(triggers, "^.*El viento arrastra un escalofriante aullido.*$", "RL/Items/Espada aullante 3.wav", "espada_aullante_3")
add_sound(triggers, "^.*Una nauseabunda cacofon.a de carne y huesos.*Mochila Carn.vora.*$", "RL/Items/Carnivora 1.wav", "carnivora")
add_sound(triggers, "^Coges la l.grima del collar y te pinchas.*llena.*$", "RL/Items/Lagrima llena.wav", "lagrima_llena")
add_sound(triggers, "^.*Coges la l.grima del collar y te pinchas.*vaciarse.*$", "RL/Items/Lagrima vacia.wav", "lagrima_vacia")
add_sound(triggers, "^Tu Escudo pav.s de Obkaeklox emite un intenso destello.*$", "RL/Items/Obkaeklox.wav", "obkaeklox")
add_sound(triggers, "^Tu R.brica de Nyel'phax responde a las palabras de poder con extra.os susurros.*$", "RL/Items/Rubrica responde.wav", "rubrica_responde")
add_sound(triggers, "^Antes de que puedas comprender los horrores.*fogonazo.*$", "RL/Items/Rubrica expulsa.wav", "rubrica_expulsa")
add_sound(triggers, "^La Fisura C.smica comienza a retorcerse lentamente.*$", "RL/Items/Fisura disipada.wav", "fisura_disipada")
add_sound(triggers, "^Tu R.brica de Nyel'phax responde.*brusco destello.*$", "RL/Items/Fisura creada.wav", "fisura_creada")
add_sound(triggers, "^Fisura C.smica\\.$", "RL/Items/Fisura activa.wav", "fisura_activa")
add_sound(triggers, "^.*Cuerno de hueso del Pr.ncipe Demonio.*pulveriza tus.*$", "RL/Items/Cuerno demonio 2.wav", "cuerno_demonio_2")
add_sound(triggers, "^Empu.as con fuerza tu Cuerno de hueso del Pr.ncipe Demonio.*$", "RL/Items/Cuerno demonio 1.wav", "cuerno_demonio_1")
add_sound(triggers, "^.* aprieta su Collar de Tinta de Kraken.*$", "RL/Items/Collar tinta otro 1.wav", "collar_tinta_1")
add_event_sound(triggers, "^.*Pierdes de vista a .*!$", "RL/Items/Collar tinta otro 2.wav", "collar_tinta_2")
add_sound(triggers, "^.*Una nube de tinta vaporizada oscurece todo a tu alrededor!$", "RL/Items/Collar tinta.wav", "collar_tinta_3")

sucesos.triggers = triggers

return sucesos
