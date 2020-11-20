/** SIMUCITIES **/

class Bloque {
	const vecinos = []
	const ciudad
	
	/** Punto 1 */
	method estaCeloso() = vecinos.all{ bloque => bloque.leDaCelosA(self) }
	
	method leDaCelosA(otroBloque) = 
		self.masPlazasQue(otroBloque) || self.mayorAporteEconomicoQue(otroBloque)
		
	method masPlazasQue(otroBloque) = 
		self.cantidadDePlazas() > otroBloque.cantidadDePlazas()
		
	method mayorAporteEconomicoQue(otroBloque) =
		self.aporteEconomico() > otroBloque.aporteEconomico()
		
	method tienePlazas() = self.cantidadDePlazas() > 0
	
	/** Punto 4 */
	method esFeliz() = self.tienePlazas() and 
						self.laPoblacionDeLosVecinosEsMayor() and 
						!self.estaCeloso() and
						ciudad.sinCatastrofeReciente()
	
	method laPoblacionDeLosVecinosEsMayor() = self.poblacionDeLosVecinos() > self.poblacion()

	method poblacionDeLosVecinos() = vecinos.sum{ vecino => vecino.poblacion() }
	
	method tieneSobrePoblacion() = self.poblacion() > 100000
	
	method agregarVecinos(bloques) {
		vecinos.addAll(bloques)
	}
		
	method dividirBloqueEn(_ciudad) {
		//no hace nada
	}
	
	method crecimientoEconomico(porcentaje) 
	method modificarPoblacion(porcentaje)
	method poblacion()
	method parquizar()
	method cantidadDePlazas() 
	method aporteEconomico() 	
}


class BloqueResidencial inherits Bloque {
	var property cantidadDePlazas = 0
	const comercios = []
	var property poblacion = 0

	override method aporteEconomico() = comercios.sum{ comercio => comercio.aporteEconomico() }
	
	override method parquizar() { 
		cantidadDePlazas += poblacion / 10000
	}
	
	override method modificarPoblacion(porcentaje) {
		poblacion += poblacion * porcentaje/100 
	}
	
	override method dividirBloqueEn(_ciudad) {
		poblacion = poblacion / 2
		const nuevoBloque = new BloqueResidencial(poblacion = poblacion, ciudad = _ciudad)
		ciudad.agregarNuevoBloque(nuevoBloque)
	}
	
	override method crecimientoEconomico(porcentaje) {
		comercios.forEach{ comercio => comercio.crecimientoEconomico(porcentaje)}
	}
	
}

class BloqueIndustrial inherits Bloque {
	var property nivelDeProduccion
	const property poblacion = 0
	
	override method cantidadDePlazas() = 0
	
	override method aporteEconomico() = nivelDeProduccion * 1000
	
	override method parquizar() { 
		//No hace nada
	}
	
	override method modificarPoblacion(porcentaje) {
		//No hace nada
	}
	
	override method crecimientoEconomico(porcentaje) {
		nivelDeProduccion += nivelDeProduccion * porcentaje/100
	}
}


class Comercio {
	var property aporteEconomico
	
	method crecimientoEconomico(porcentaje) {
		aporteEconomico += aporteEconomico * porcentaje/100
	}
}



class Ciudad {
	const bloques = []
	const trimestres = []	

	/** Punto 2 */
	method esVerde() = bloques.all{ bloque => bloque.tienePlazas() }
	
	/** Punto 3 */
	method parquizar() {
		 bloques.forEach{ bloque => bloque.parquizar() }	 
	}
	
	/** Punto 5 */
	method pbiPerCapita() =  self.pbi() / self.poblacion()
	
	method poblacion() = bloques.sum { bloque => bloque.poblacion() }
	
	method pbi() = bloques.sum { bloque => bloque.aporteEconomico() }
	
	/** Punto 6 */
	method estaBienEconomicamente() {
		const ultimosTrimestres = trimestres.reverse().take(2)
		return ultimosTrimestres.size() < 2 or
				self.existeMejoraEnPbi(ultimosTrimestres) 	
	}
	
	method existeMejoraEnPbi(ultimosTrimestres) =
				self.pbiPerCapita() > ultimosTrimestres.get(0).pbiPerCapita() and
				ultimosTrimestres.get(0).pbiPerCapita() > ultimosTrimestres.get(1).pbiPerCapita()	
	
	/** Punto 7 */
	method ocurre(evento) {
		const ppc = self.pbiPerCapita()
		evento.apply(self)
		trimestres.add(new Trimestre(pbiPerCapita = ppc, evento = evento))
	}
	
	method modificarPoblacion(porcentaje) {
		bloques.forEach{ bloque => bloque.modificarPoblacion(porcentaje)}
		self.crearBloquesResidenciales()	
	}
	
	
	method crearBloquesResidenciales() {
		bloques.filter{ bloque => bloque.tieneSobrePoblacion() }
				.forEach{ bloque => bloque.dividirBloqueEn(self)}	
	}
	
	
	method agregarNuevoBloque(nuevoBloque) {
		nuevoBloque.agregarVecinos(bloques.reverse().take(3))
		bloques.add(nuevoBloque)
	}
	
	
	method promedioProduccion() = self.pbi() / bloques.size() / 1000
	
	method crecimientoEconomico(porcentaje) {
		bloques.forEach{ bloque => bloque.crecimientoEconomico(porcentaje) }
		if (self.pbiPerCapita() > 1000) 
			self.crearBloqueIndustrial()
	}
	
	
	method crearBloqueIndustrial() {
		const promedioProduccion = self.promedioProduccion()
		const ultimosBloques = bloques.reverse().take(3)
		const nuevoBloque = new BloqueIndustrial(nivelDeProduccion = promedioProduccion, ciudad = self)
		if (ultimosBloques.any{bloque => bloque.tienePlazas()})
			nuevoBloque.agregarVecinos(ultimosBloques)
		bloques.add(nuevoBloque)
	}
	
	method destruirUltimosBloques(cantidad) {
		bloques.removeAll(bloques.take(cantidad))
	}
	
	method sinCatastrofeReciente() = trimestres.last().noFueCastrofe()
	
}


class Trimestre {
	const property pbiPerCapita
	const evento
	
	method noFueCastrofe() = evento.noFueCastrofe()
}

class Evento {
	
	method noFueCastrofe() = true
}



object cambioPoblacion inherits Evento {
	
	method apply(ciudad) {
		if (ciudad.estaBienEconomicamente())
			ciudad.modificarPoblacion(5)
		else
			ciudad.modificarPoblacion(-1)
	}
}

						
class CrecimientoEconomico inherits Evento {
	
	const porcentaje 
	
	method apply(ciudad) {
		if(ciudad.pbiPerCapita() > crecimientoEconomico.valor() &&
			ciudad.estaBienEconomicamente()) {
				ciudad.crecimientoEconomico(porcentaje)
		}
	}
	
}

object crecimientoEconomico {
	var property valor = 600
}


class CrecimientoMixto inherits Evento {
	const crecimientoEconomico 
	
	method apply(ciudad) {
		cambioPoblacion.apply(ciudad)
		crecimientoEconomico.apply(ciudad)
	}
}

object desastreNatural inherits Evento {
	method apply(ciudad) {
		ciudad.modificarPoblacion(-10)
		ciudad.destruirUltimosBloques(2)
	}
	
	override method noFueCastrofe()  = false 
}