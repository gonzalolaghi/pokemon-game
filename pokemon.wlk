import wollok.game.*

class Pokemon {
    const property nombre
    var property vida
    var property vidaMaxima
    var property ataque
    var property defensa
    const property tipo
    var property imagen
    var property position = game.at(0, 0)
    var property esRival = false
    var property golpesParaEspecial = 0
    var property puedeAtacar = true
    var property puedeCurarse = true
    var property curacionesUsadas = 0
    var property especialesUsados = 0
    var property evolucionado = false

    method golpesParaEspecialMaximo() = if (self.evolucionado()) 10 else 5

    method estaVivo() = vida > 0

    method recibirDanio(danio) {
        const danioReal = (danio - defensa).max(0)
        vida = (vida - danioReal).max(0)
        if (esRival) {
            game.sound("dano_minecraft.mp3").play()
            const imagenOriginal = imagen
            const nombreRojo = nombre.toLowerCase() + "_rojo.png"
            imagen = nombreRojo
            game.schedule(1000, { imagen = imagenOriginal })
        }
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
            self.animarAtaque()
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
        if (self.estaVivo() && otroPokemon.estaVivo() && golpesParaEspecial >= self.golpesParaEspecialMaximo()) {
            self.animarAtaque()
            game.schedule(200, {
                if (self.evolucionado()) {
                    // Si el atacante está evolucionado, insta-kill
                    otroPokemon.vida(0)
                    otroPokemon.animarGolpe()
                    game.say(otroPokemon, "¡KO!")
                } else {
                    const danioEspecial = (otroPokemon.vidaMaxima() * 0.5).roundUp()
                    otroPokemon.recibirDanio(danioEspecial)
                    otroPokemon.animarGolpe()
                    game.say(otroPokemon, "-" + danioEspecial.roundUp() + " HP!!")
                }
                if (callback != null) callback.apply()
            })
            golpesParaEspecial = 0
        }
    }

    method animarAtaque() {
        const posOriginal = position
        const desplazamiento = if (esRival) -1 else 1
        position = game.at(posOriginal.x() + desplazamiento, posOriginal.y())
        game.schedule(300, { position = posOriginal })
    }

    method animarGolpe() {
        const posOriginal = position
        const direccion = if (esRival) -1 else 1
        game.schedule(0, { position = game.at(posOriginal.x() + (0.4 * direccion), posOriginal.y()) })
        game.schedule(80, { position = game.at(posOriginal.x() - (0.4 * direccion), posOriginal.y()) })
        game.schedule(160, { position = game.at(posOriginal.x() + (0.2 * direccion), posOriginal.y()) })
        game.schedule(240, { position = posOriginal })
    }

    method porcentajeVida() = vida / vidaMaxima

    method porcentajeEspecial() = golpesParaEspecial / self.golpesParaEspecialMaximo()

    method incrementarGolpes() {
        golpesParaEspecial = (golpesParaEspecial + 1).min(self.golpesParaEspecialMaximo())
    }

    method curarse(cantidad) {
        vida = (vida + cantidad).min(vidaMaxima)
        game.say(self, "Curado!")
    }

    method image() = imagen

    method mostrarEstado() {
        return nombre + ": " + vida + "/" + vidaMaxima + " HP"
    }

    method verificarEvolucion() {
        if (!evolucionado && !esRival && curacionesUsadas >= 3 && especialesUsados >= 2) {
            self.evolucionar()
        }
    }

    method evolucionar() {
        evolucionado = true
        curacionesUsadas = 0
        especialesUsados = 0
        golpesParaEspecial = 0
        
        // Cambiar imagen según el Pokémon
        const imagenActual = nombre.toLowerCase()
        var nuevaImagen = imagen
        if (imagenActual == "pikachu") {
            nuevaImagen = "raichu.png"
        } else if (imagenActual == "squirtle") {
            nuevaImagen = "wartortle.png"
        } else if (imagenActual == "bulbasaur") {
            nuevaImagen = "ivysaur.png"
        } else if (imagenActual == "charmander") {
            nuevaImagen = "charmeleon.png"
        }
        
        // Aumentar stats
        const vidaMaximaAnterior = vidaMaxima
        vidaMaxima = (vidaMaximaAnterior * 2).roundUp()
        vida = vidaMaxima
        ataque = (ataque * 1.8).roundUp()
        defensa = (defensa * 1.6).roundUp()
        
        // Reproducir sonido de evolución y mostrar efecto titilante
        game.sound("evolucion.mp3").play()
        
        const imagenAnterior = imagen
        self.efectoTitilante(imagenAnterior, nuevaImagen, 0)
        
        game.schedule(1800, { game.say(self, "¡" + nombre + " evolucionó!") })
    }

    method efectoTitilante(imagenAnterior, imagenNueva, fase) {
        if (fase < 6) {
            const mostrarNueva = fase % 2 == 0
            if (mostrarNueva) {
                imagen = imagenNueva
            } else {
                imagen = imagenAnterior
            }
            game.schedule(300, { self.efectoTitilante(imagenAnterior, imagenNueva, fase + 1) })
        } else {
            imagen = imagenNueva
        }
    }

    method cooldownCuracionEvolucionado() = if (evolucionado) 20000 else 10000
}

// BARRA DE VIDA
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

// BARRA DE VIDA
class BarraVida {
    const pokemon
    var property position
    const longitudMaxima = 15

    method porcentajeVida() = pokemon.porcentajeVida()

    method colorBarra() {
        const porcentaje = self.porcentajeVida()
        if (porcentaje > 0.5) return "00FF00" 
        if (porcentaje > 0.2) return "FFFF00"
        return "FF0000"  
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

    method textColor() = "333333"  
    method fontSize() = 16
}

// BARRA DE ENERGÍA 
object barraEnergia {
    var property position = game.at(0, 0)
    const longitudMaxima = 15

    method pokemon() = combate.pokemonJugador()

    method porcentajeEspecial() = if (self.pokemon() != null) self.pokemon().porcentajeEspecial() else 0

    method text() {
        const porcentaje = self.porcentajeEspecial()
        const caracteresLlenos = (longitudMaxima * porcentaje).roundUp().max(0)
        return self.repetirCaracter("█", caracteresLlenos)
    }

    method repetirCaracter(caracter, veces) {
        var resultado = ""
        veces.times({ _ => resultado += caracter })
        return resultado
    }

    method textColor() = "00CCFF"  
    method fontSize() = 16
}

// BARRA DE ESPECIAL DEL RIVAL 
object fondoBarraEspecialRival {
    var property position = game.at(0, 0)
    const longitudMaxima = 15

    method text() = self.repetirCaracter("█", longitudMaxima)

    method repetirCaracter(caracter, veces) {
        var resultado = ""
        veces.times({ _ => resultado += caracter })
        return resultado
    }

    method textColor() = "333333"
    method fontSize() = 16
}

// BARRA DE ESPECIAL DEL RIVAL 
object barraEspecialRival {
    var property position = game.at(0, 0)
    const longitudMaxima = 15

    method pokemon() = combate.pokemonRival()

    method porcentajeEspecial() = if (self.pokemon() != null) self.pokemon().porcentajeEspecial() else 0

    method text() {
        const porcentaje = self.porcentajeEspecial()
        const caracteresLlenos = (longitudMaxima * porcentaje).roundUp().max(0)
        return self.repetirCaracter("█", caracteresLlenos)
    }

    method repetirCaracter(caracter, veces) {
        var resultado = ""
        veces.times({ _ => resultado += caracter })
        return resultado
    }

    method textColor() = "FF9900"  
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
    method scale() = 0.15 
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

// POKÉBOLA
object pokebolaAnimacion {
    var property position = game.at(0, 0)

    method image() = "pokebola.png"

    method scale() = 0.5
}

// EXPLOSIÓN
class ExplosionAnimacion {
    var property position
    var property opacidad = 1.0

    method image() = "explosion.png"

    method scale() = 0.6
}

object instruccionesCombate {
    method position() = game.at(4, 1)
    method text() = "ENTER: Ataque | R: Especial | E: Curarse"
    method textColor() = "FFFFFFCC"
    method fontSize() = 12
}

// Popup de victoria
object popupVictoria {
    method position() = game.at(15.5, 8)  
    method image() = "victoria.png"
    method scale() = 0.65
}

// Popup de derrota
object popupDerrota {
    method position() = game.at(15.5, 8) 
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

    method iniciar(jugador, rival) {
        pokemonJugador = jugador
        pokemonRival = rival
        enCombate = true

        pokemonJugador.golpesParaEspecial(0)
        pokemonJugador.puedeAtacar(true)
        pokemonJugador.puedeCurarse(true)
        pokemonRival.puedeAtacar(true)
        pokemonRival.golpesParaEspecial(0)
        pokemonRival.curacionesUsadas(0)
        pokemonRival.especialesUsados(0)  
        pokemonJugador.vida(pokemonJugador.vidaMaxima());
        pokemonRival.vida(pokemonRival.vidaMaxima());


        const nombrePokemon = pokemonJugador.nombre().toLowerCase()
        if (["pikachu", "charmander", "squirtle", "bulbasaur"].contains(nombrePokemon)) {
            if (!pokemonJugador.evolucionado()) {
                pokemonJugador.imagen(nombrePokemon + "-combate.png")
            }
        }

        game.allVisuals().forEach({ visual => game.removeVisual(visual) })

        pokemonJugador.position(game.at(6, 9))
        pokemonRival.position(game.at(28, 9))

        const nombreJugadorVisual = new EtiquetaNombre(pokemon = pokemonJugador, position = game.at(6, 16))
        const nombreRival = new EtiquetaNombre(pokemon = pokemonRival, position = game.at(28, 16))

        const fondoVidaJugador = new BarraVidaFondo(position = game.at(7.5, 15.5))
        const fondoVidaRival = new BarraVidaFondo(position = game.at(29.5, 15.5))
        barraVidaJugador = new BarraVida(pokemon = pokemonJugador, position = game.at(7.5, 15.5))
        barraVidaRival = new BarraVida(pokemon = pokemonRival, position = game.at(29.5, 15.5))

        game.addVisual(pokemonRival)
        game.addVisual(nombreRival)
        game.addVisual(fondoVidaRival)
        game.addVisual(barraVidaRival)

        // Barras de carga del especial: jugador y rival
        fondoBarraEnergia.position(game.at(8, 5))
        game.addVisual(fondoBarraEnergia)
        barraEnergia.position(game.at(8, 5))
        game.addVisual(barraEnergia)

        fondoBarraEspecialRival.position(game.at(29.5, 5))
        game.addVisual(fondoBarraEspecialRival)
        barraEspecialRival.position(game.at(29.5, 5))
        game.addVisual(barraEspecialRival)

        game.addVisual(instruccionesCombate)

        self.iniciarAnimacionPokebola(nombreJugadorVisual, fondoVidaJugador)
    }

    method iniciarAnimacionPokebola(nombreJugadorVisual, fondoVidaJugador) {
        const xDestino = 6
        const yDestino = 9

        pokebolaAnimacion.position(game.at(-5, yDestino))
        game.addVisual(pokebolaAnimacion)

        self.animarPokebolaConSaltos(xDestino, yDestino, 0, nombreJugadorVisual, fondoVidaJugador)
    }

    method animarPokebolaConSaltos(xDestino, yDestino, paso, nombreJugadorVisual, fondoVidaJugador) {
        const pasosTotales = 8
        if (paso < pasosTotales) {
            // Calcular progreso
            const progreso = paso / pasosTotales
            const xActual = -5 + (xDestino + 5) * progreso
            const alturaMaxima = 3 * (1 - progreso)
            const yOscilacion = yDestino + alturaMaxima * (1 - ((paso % 2) / 2 - 0.5).abs() * 4)
            pokebolaAnimacion.position(game.at(xActual, yOscilacion))
            const siguientePaso = paso + 1
            game.schedule(100, { self.animarPokebolaConSaltos(xDestino, yDestino, siguientePaso, nombreJugadorVisual, fondoVidaJugador) })
        } else {
            pokebolaAnimacion.position(game.at(xDestino, yDestino))
            game.schedule(200, { self.mostrarExplosionYPokemon(xDestino, yDestino, nombreJugadorVisual, fondoVidaJugador) })
        }
    }

    method mostrarExplosionYPokemon(xDestino, yDestino, nombreJugadorVisual, fondoVidaJugador) {
        game.removeVisual(pokebolaAnimacion)

        game.addVisual(pokemonJugador)
        game.addVisual(nombreJugadorVisual)
        game.addVisual(fondoVidaJugador)
        game.addVisual(barraVidaJugador)

        const explosion = new ExplosionAnimacion(position = game.at(xDestino - 2.5, yDestino - 2.5))
        game.addVisual(explosion)

        game.sound("pokebola_salida.mp3").play()

        self.desvanecerExplosion(explosion, 0)
    }

    method desvanecerExplosion(explosion, tiempoMs) {
        if (tiempoMs < 3000) {
            // Reducir opacidad gradualmente
            explosion.opacidad(1.0 - (tiempoMs / 3000.0))
            game.schedule(50, { self.desvanecerExplosion(explosion, tiempoMs + 50) })
        } else {
            // Remover explosión
            game.removeVisual(explosion)
            // Iniciar combate
            self.iniciarCombateLuegoDePokebola()
        }
    }

    method iniciarCombateLuegoDePokebola() {
        // Mensaje de inicio
        game.schedule(100, { game.say(pokemonJugador, "¡Comienza el combate!") })

        // Configurar controles
        self.configurarControles()

        // Iniciar IA del rival
        self.iniciarIARival()
    }

    method configurarControles() {
        keyboard.enter().onPressDo({})
        keyboard.r().onPressDo({})
        keyboard.e().onPressDo({})
        keyboard.enter().onPressDo({ self.ataqueRapidoJugador() })
        keyboard.r().onPressDo({ self.ataqueEspecialJugador() })
        keyboard.e().onPressDo({ self.curarJugador() })
    }

    method ataqueRapidoJugador() {
        if (enCombate && pokemonJugador.estaVivo() && pokemonJugador.puedeAtacar()) {
            pokemonJugador.puedeAtacar(false)
            pokemonJugador.ataqueRapido(pokemonRival, { self.verificarFinCombate() })
            pokemonJugador.incrementarGolpes()
            game.schedule(2000, { pokemonJugador.puedeAtacar(true) })
        }
    }

    method ataqueEspecialJugador() {
        if (enCombate && pokemonJugador.estaVivo() && pokemonJugador.puedeAtacar()) {
            if (pokemonJugador.golpesParaEspecial() >= pokemonJugador.golpesParaEspecialMaximo()) {
                game.say(pokemonJugador, "¡Ataque especial!")
                pokemonJugador.puedeAtacar(false)
                pokemonJugador.ataqueEspecial(pokemonRival, { self.verificarFinCombate() })
                pokemonJugador.especialesUsados(pokemonJugador.especialesUsados() + 1)
                pokemonJugador.verificarEvolucion()
                game.schedule(2000, { pokemonJugador.puedeAtacar(true) })
            } else {
                const falta = pokemonJugador.golpesParaEspecialMaximo() - pokemonJugador.golpesParaEspecial()
                game.say(pokemonJugador, "¡Faltan " + falta + " golpes!")
            }
        }
    }

    method curarJugador() {
        if (enCombate && pokemonJugador.estaVivo() && pokemonJugador.puedeCurarse()) {
            if (pokemonJugador.vida() < pokemonJugador.vidaMaxima()) {
                const curacion = (pokemonJugador.vidaMaxima() * 0.25).roundUp()
                pokemonJugador.vida((pokemonJugador.vida() + curacion).min(pokemonJugador.vidaMaxima()))
                game.say(pokemonJugador, "¡Curado +" + curacion + " HP!")
                // Reproducir sonido de curación para el jugador
                game.sound("curacion.mp3").play()
                pokemonJugador.curacionesUsadas(pokemonJugador.curacionesUsadas() + 1)
                pokemonJugador.verificarEvolucion()
                pokemonJugador.puedeCurarse(false)
                const cooldown = pokemonJugador.cooldownCuracionEvolucionado()
                game.schedule(cooldown, { pokemonJugador.puedeCurarse(true) })
            } else {
                game.say(pokemonJugador, "¡Vida completa!")
            }
        }
    }

    method iniciarIARival() {
        game.onTick(3000, "ataque_rival", { self.ataqueRival() })
    }

    method ataqueRival() {
        if (enCombate && pokemonRival.estaVivo() && pokemonJugador.estaVivo() && pokemonRival.puedeAtacar()) {
            // Priorizar curarse si está debajo del 50% y tiene cooldown disponible
            if (pokemonRival.puedeCurarse() && pokemonRival.vida() < (pokemonRival.vidaMaxima() * 0.5)) {
                const curacion = (pokemonRival.vidaMaxima() * 0.25).roundUp()
                pokemonRival.vida((pokemonRival.vida() + curacion).min(pokemonRival.vidaMaxima()))
                game.say(pokemonRival, "¡Curado +" + curacion + " HP!")
                pokemonRival.puedeCurarse(false)
                // gastar turno y aplicar cooldown
                pokemonRival.puedeAtacar(false)
                game.schedule(10000, { pokemonRival.puedeCurarse(true) })
                game.schedule(2000, { pokemonRival.puedeAtacar(true) })
            } else if (pokemonRival.golpesParaEspecial() >= pokemonRival.golpesParaEspecialMaximo()) {
                // Usar ataque especial cuando esté cargado
                pokemonRival.puedeAtacar(false)
                pokemonRival.ataqueEspecial(pokemonJugador, { self.verificarFinCombate() })
                game.schedule(2000, { pokemonRival.puedeAtacar(true) })
            } else {
                // Ataque rápido normal
                pokemonRival.puedeAtacar(false)
                pokemonRival.ataqueRapido(pokemonJugador, { self.verificarFinCombate() })
                pokemonRival.incrementarGolpes()
                game.schedule(2000, { pokemonRival.puedeAtacar(true) })
            }
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

        if (victoria) {
            game.sound("victoria.mp3").play()
            game.schedule(600, {
                game.addVisual(popupVictoria)
                game.schedule(150, { game.removeVisual(popupVictoria) })
                game.schedule(300, { game.addVisual(popupVictoria) })
                game.schedule(450, { game.removeVisual(popupVictoria) })
                game.schedule(600, { game.addVisual(popupVictoria) })
            })

        } else {
            game.sound("derrota.mp3").play()
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
