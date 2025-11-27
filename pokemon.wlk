import wollok.game.*

// Clase Pokemon simplificada
class Pokemon {
    const property nombre
    var property vida
    const property vidaMaxima
    const property ataque
    const property defensa
    const property tipo  // "fuego", "agua", "planta", "electrico", "roca"
    var property imagen  // Cambiado a var para poder cambiar imagen en combate
    var property position = game.at(0, 0)
    var property esRival = false  // para identificar si es del jugador o rival
    var property energia = 0  // Energía para ataques especiales
    const energiaMaxima = 100
    const energiaPorAtaqueRapido = 25

    method estaVivo() = vida > 0

    method recibirDanio(danio) {
        // La defensa reduce el daño en un porcentaje menor
        const reduccion = (defensa * 0.3).roundUp()
        const danioReal = (danio - reduccion).max(danio * 0.5)  // Mínimo 50% del daño original
        vida = (vida - danioReal).max(0)
        if (!self.estaVivo()) {
            game.say(self, nombre + " debilitado!")
        }
    }

    method atacar(otroPokemon) {
        if (self.estaVivo() && otroPokemon.estaVivo()) {
            game.say(self, "¡Ataque!")
            otroPokemon.recibirDanio(ataque)
        }
    }

    method ataqueRapido(otroPokemon, callback) {
        if (self.estaVivo() && otroPokemon.estaVivo()) {
            // Animación de ataque
            self.animarAtaque()

            // Hacer daño normal
            const danioRapido = (ataque * 0.6).roundUp()
            game.schedule(200, {
                otroPokemon.recibirDanio(danioRapido)
                otroPokemon.animarGolpe()
                game.say(otroPokemon, "-" + danioRapido.roundUp() + " HP")
                if (callback != null) callback.apply()
            })
        }
    }

    method ataqueEspecial(otroPokemon, callback) {
        if (self.estaVivo() && otroPokemon.estaVivo() && self.tieneEnergiaCompleta()) {
            // Animación de ataque
            self.animarAtaque()

            // Hacer daño alto (4x el daño del ataque rápido)
            const danioEspecial = (ataque * 2.4).roundUp()
            game.schedule(200, {
                otroPokemon.recibirDanio(danioEspecial)
                otroPokemon.animarGolpe()
                game.say(otroPokemon, "-" + danioEspecial.roundUp() + " HP!!")
                if (callback != null) callback.apply()
            })

            // Consumir energía
            energia = 0
        }
    }

    method animarAtaque() {
        const posOriginal = position
        const desplazamiento = if (esRival) -1 else 1

        // Moverse hacia adelante
        position = game.at(posOriginal.x() + desplazamiento, posOriginal.y())

        // Volver a posición original
        game.schedule(300, { position = posOriginal })
    }

    method animarGolpe() {
        const posOriginal = position
        // Sacudir en la dirección opuesta según quién sea
        const direccion = if (esRival) -1 else 1

        // Sacudir con límites para no salirse
        game.schedule(0, { position = game.at(posOriginal.x() + (0.4 * direccion), posOriginal.y()) })
        game.schedule(80, { position = game.at(posOriginal.x() - (0.4 * direccion), posOriginal.y()) })
        game.schedule(160, { position = game.at(posOriginal.x() + (0.2 * direccion), posOriginal.y()) })
        game.schedule(240, { position = posOriginal })
    }

    method tieneEnergiaCompleta() = energia >= energiaMaxima

    method porcentajeEnergia() = energia / energiaMaxima

    method porcentajeVida() = vida / vidaMaxima

    method cargarEnergia(cantidad) {
        if (!esRival && self.estaVivo()) {
            energia = (energia + cantidad).min(energiaMaxima)
        }
    }

    method curarse(cantidad) {
        vida = (vida + cantidad).min(vidaMaxima)
        game.say(self, "Curado!")
    }

    method image() = imagen

    method mostrarEstado() {
        return nombre + ": " + vida + "/" + vidaMaxima + " HP"
    }
}

// BARRA DE VIDA - Fondo (gris)
class BarraVidaFondo {
    var property position
    const longitudMaxima = 15

    method text() = self.repetirCaracter("█", longitudMaxima)

    method repetirCaracter(caracter, veces) {
        var resultado = ""
        veces.times({ _ => resultado += caracter })
        return resultado
    }

    method textColor() = "333333"  // Gris oscuro
    method fontSize() = 16
}

// BARRA DE VIDA - Relleno (verde/amarillo/rojo)
class BarraVida {
    const pokemon
    var property position
    const longitudMaxima = 15

    method porcentajeVida() = pokemon.porcentajeVida()

    method colorBarra() {
        const porcentaje = self.porcentajeVida()
        if (porcentaje > 0.5) return "00FF00"  // Verde
        if (porcentaje > 0.2) return "FFFF00"  // Amarillo
        return "FF0000"  // Rojo
    }

    method text() {
        const porcentaje = self.porcentajeVida()
        const caracteresLlenos = (longitudMaxima * porcentaje).roundUp().max(0)
        return self.repetirCaracter("█", caracteresLlenos)
    }

    method repetirCaracter(caracter, veces) {
        var resultado = ""
        veces.times({ _ => resultado += caracter })
        return resultado
    }

    method textColor() = self.colorBarra()
    method fontSize() = 16
}

// BARRA DE ENERGÍA - Fondo
object fondoBarraEnergia {
    var property position = game.at(0, 0)
    const longitudMaxima = 15

    method text() = self.repetirCaracter("█", longitudMaxima)

    method repetirCaracter(caracter, veces) {
        var resultado = ""
        veces.times({ _ => resultado += caracter })
        return resultado
    }

    method textColor() = "333333"  // Gris oscuro
    method fontSize() = 16
}

// BARRA DE ENERGÍA - Relleno
object barraEnergia {
    var property position = game.at(0, 0)
    const longitudMaxima = 15

    method pokemon() = combate.pokemonJugador()

    method porcentajeEnergia() = if (self.pokemon() != null) self.pokemon().porcentajeEnergia() else 0

    method text() {
        const porcentaje = self.porcentajeEnergia()
        const caracteresLlenos = (longitudMaxima * porcentaje).roundUp().max(0)
        return self.repetirCaracter("█", caracteresLlenos)
    }

    method repetirCaracter(caracter, veces) {
        var resultado = ""
        veces.times({ _ => resultado += caracter })
        return resultado
    }

    method textColor() = "00CCFF"  // Celeste/Azul
    method fontSize() = 16
}

// ETIQUETAS DE INFORMACIÓN
class EtiquetaHP {
    const pokemon
    var property position

    method text() = "HP: " + pokemon.vida().roundUp() + "/" + pokemon.vidaMaxima()
    method textColor() = "FFFFFFFF"
    method fontSize() = 16
}

class EtiquetaNombre {
    const pokemon
    var property position

    method image() = "nombre_" + pokemon.nombre().toLowerCase() + ".png"
    method scale() = 0.15  // Hacer la imagen más chica
}

class EtiquetaNombreTexto {
    const pokemon
    var property position

    method text() = pokemon.nombre()
    method textColor() = "FFFFFFFF"
    method fontSize() = 18
}

object cartelAtaqueEspecial {
    var property position = game.at(0, 0)

    method pokemon() = combate.pokemonJugador()

    method image() = "ataque-especial.png"
}

object instruccionesCombate {
    method position() = game.at(8, 1)
    method text() = "ENTER: Ataque | SPACE: Ataque especial (4x daño)"
    method textColor() = "FFFFFFCC"
    method fontSize() = 14
}

// Popup de victoria
object popupVictoria {
    method position() = game.at(15.5, 8)  // Centrado
    method image() = "victoria.png"
    method scale() = 0.65
}

// Popup de derrota
object popupDerrota {
    method position() = game.at(15.5, 8)  // Centrado
    method image() = "derrota.png"
    method scale() = 0.65
}

// CONTROLADOR DE COMBATE
object combate {
    var property pokemonJugador = null
    var property pokemonRival = null
    var property barraVidaJugador = null
    var property barraVidaRival = null
    var property enCombate = false
    var tiempoUltimoAtaqueRival = 0
    var property ataqueEspecialEnCooldown = false  // Indica si está en cooldown

    method puedeUsarAtaqueEspecial() {
        return pokemonJugador.tieneEnergiaCompleta() && !ataqueEspecialEnCooldown
    }

    method iniciar(jugador, rival) {
        pokemonJugador = jugador
        pokemonRival = rival
        enCombate = true

        // Resetear estado de combate
        pokemonJugador.energia(0)
        pokemonJugador.vida(pokemonJugador.vidaMaxima())
        pokemonRival.vida(pokemonRival.vidaMaxima())
        ataqueEspecialEnCooldown = false  // Resetear cooldown

        // Cambiar a imágenes de combate para pokémon originales
        const nombrePokemon = pokemonJugador.nombre().toLowerCase()
        if (["pikachu", "charmander", "squirtle", "bulbasaur"].contains(nombrePokemon)) {
            pokemonJugador.imagen(nombrePokemon + "-combate.png")
        }

        // Limpiar pantalla anterior
        game.allVisuals().forEach({ visual => game.removeVisual(visual) })

        // Posicionar pokémon (alineados horizontalmente, frente a frente)
        pokemonJugador.position(game.at(6, 9))
        pokemonRival.position(game.at(28, 9))

        // Crear nombres (imagen para ambos)
        const nombreJugador = new EtiquetaNombre(pokemon = pokemonJugador, position = game.at(6, 16))
        const nombreRival = new EtiquetaNombre(pokemon = pokemonRival, position = game.at(28, 16))

        // Crear barras de vida (fondo + relleno) - ajustadas debajo de nombres
        const fondoVidaJugador = new BarraVidaFondo(position = game.at(7.5, 15.5))
        const fondoVidaRival = new BarraVidaFondo(position = game.at(29.5, 15.5))
        barraVidaJugador = new BarraVida(pokemon = pokemonJugador, position = game.at(7.5, 15.5))
        barraVidaRival = new BarraVida(pokemon = pokemonRival, position = game.at(29.5, 15.5))

        // Agregar visuales (primero los fondos, luego los rellenos para que se superpongan)
        game.addVisual(pokemonJugador)
        game.addVisual(pokemonRival)
        game.addVisual(nombreJugador)
        game.addVisual(nombreRival)
        game.addVisual(fondoVidaJugador)
        game.addVisual(fondoVidaRival)
        game.addVisual(barraVidaJugador)
        game.addVisual(barraVidaRival)

        fondoBarraEnergia.position(game.at(8, 5))
        game.addVisual(fondoBarraEnergia)
        barraEnergia.position(game.at(8, 5))
        game.addVisual(barraEnergia)

        game.addVisual(instruccionesCombate)

        // Mensaje de inicio
        game.schedule(100, { game.say(pokemonJugador, "¡Comienza el combate!") })

        // Configurar controles
        self.configurarControles()

        // Iniciar IA del rival
        self.iniciarIARival()

        // Iniciar carga automática de energía
        self.iniciarCargaEnergia()
    }

    method configurarControles() {
        // Limpiar controles anteriores
        keyboard.enter().onPressDo({})
        keyboard.space().onPressDo({})

        // Ataque rápido con ENTER
        keyboard.enter().onPressDo({ self.ataqueRapidoJugador() })

        // Ataque especial con SPACE
        keyboard.space().onPressDo({ self.ataqueEspecialJugador() })
    }

    method ataqueRapidoJugador() {
        if (enCombate && pokemonJugador.estaVivo()) {
            pokemonJugador.ataqueRapido(pokemonRival, { self.verificarFinCombate() })
        }
    }

    method ataqueEspecialJugador() {
        if (enCombate && pokemonJugador.estaVivo()) {
            if (self.puedeUsarAtaqueEspecial()) {
                game.say(pokemonJugador, "¡Ataque especial!")
                // Remover el cartel
                game.removeVisual(cartelAtaqueEspecial)
                pokemonJugador.ataqueEspecial(pokemonRival, { self.verificarFinCombate() })
                // Activar cooldown por 5 segundos
                ataqueEspecialEnCooldown = true
                game.schedule(5000, { ataqueEspecialEnCooldown = false })
            } else if (!pokemonJugador.tieneEnergiaCompleta()) {
                game.say(pokemonJugador, "¡Necesito más energía!")
            } else {
                game.say(pokemonJugador, "¡Aún no está listo!")
            }
        }
    }

    method iniciarIARival() {
        // El rival ataca cada 2 segundos
        game.onTick(2000, "ataque_rival", { self.ataqueRival() })
    }

    method iniciarCargaEnergia() {
        // Posicionar el cartel de ataque especial (a la izquierda de la barra azul)
        cartelAtaqueEspecial.position(game.at(6.5, 5.5))

        // Cargar energía automáticamente cada 700ms (se llena en ~7 segundos)
        game.onTick(700, "carga_energia", {
            if (pokemonJugador != null) {
                const energiaAntes = pokemonJugador.energia()
                pokemonJugador.cargarEnergia(10)
                // Mostrar cartel cuando se llena la energía
                if (energiaAntes < 100 && pokemonJugador.tieneEnergiaCompleta()) {
                    game.addVisual(cartelAtaqueEspecial)
                }
            }
        })
    }

    method ataqueRival() {
        if (enCombate && pokemonRival.estaVivo() && pokemonJugador.estaVivo()) {
            pokemonRival.ataqueRapido(pokemonJugador, { self.verificarFinCombate() })
        }
    }

    method verificarFinCombate() {
        if (!pokemonJugador.estaVivo()) {
            self.finalizarCombate(false)
        } else if (!pokemonRival.estaVivo()) {
            self.finalizarCombate(true)
        }
    }

    method finalizarCombate(victoria) {
        enCombate = false
        game.removeTickEvent("ataque_rival")
        game.removeTickEvent("carga_energia")

        // Efecto de parpadeo del popup para llamar la atención
        if (victoria) {
            game.schedule(600, {
                game.addVisual(popupVictoria)
                game.schedule(150, { game.removeVisual(popupVictoria) })
                game.schedule(300, { game.addVisual(popupVictoria) })
                game.schedule(450, { game.removeVisual(popupVictoria) })
                game.schedule(600, { game.addVisual(popupVictoria) })
            })
        } else {
            game.schedule(600, {
                game.addVisual(popupDerrota)
                game.schedule(150, { game.removeVisual(popupDerrota) })
                game.schedule(300, { game.addVisual(popupDerrota) })
                game.schedule(450, { game.removeVisual(popupDerrota) })
                game.schedule(600, { game.addVisual(popupDerrota) })
            })
        }

    }
}
