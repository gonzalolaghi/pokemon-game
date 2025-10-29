import wollok.game.*

// Clase Pokemon simplificada
class Pokemon {
    const property nombre
    var property vida
    const property vidaMaxima
    const property ataque
    const property defensa
    const property tipo  // "fuego", "agua", "planta", "electrico", "roca"
    const property imagen
    var property position = game.at(0, 0)
    var property esRival = false  // para identificar si es del jugador o rival

    method estaVivo() = vida > 0

    method recibirDanio(danio) {
        const danioReal = (danio - defensa).max(1)  // Mínimo 1 de daño
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

    method curarse(cantidad) {
        vida = (vida + cantidad).min(vidaMaxima)
        game.say(self, "Curado!")
    }

    method image() = imagen

    method mostrarEstado() {
        return nombre + ": " + vida + "/" + vidaMaxima + " HP"
    }
}
