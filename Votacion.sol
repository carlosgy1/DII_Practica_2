// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Votacion {
    struct Opcion {
        string nombre;
        uint256 votos_totales;
    }

    struct Propuesta {
        string descripcion;
        uint256 votantes_minimos;
        uint256 finalizacion;
        bool ponderacion;
        bool cambio_voto;
        mapping(address => uint256) info_votantes;
        Opcion[] opciones;
        uint256 votantes_totales;
        uint256 votos_totales;
    }

    Propuesta[] public propuestas;
    address direccion_token;
    uint256 minimo_mayoria;

    constructor(address direccion_token_aux, uint256 minimo_mayoria_aux) {
        require(minimo_mayoria_aux > 0 && minimo_mayoria_aux <= 100, "Porcentaje debe estar entre 1 y 100");
        direccion_token = direccion_token_aux;
        minimo_mayoria = minimo_mayoria_aux;
    }

    function nueva_propuesta(string memory descripcion_aux, uint256 votantes_minimos_aux, uint256 duracion_aux, bool ponderacion_aux, bool cambio_voto_aux, string[] memory opciones_aux) public {
        require(IERC20(direccion_token).balanceOf(msg.sender) >= 100, "No tienes suficientes tokens para crear la propuesta");
        
        Propuesta storage propuesta = propuestas.push();
        propuesta.descripcion = descripcion_aux;
        propuesta.votantes_minimos = votantes_minimos_aux;
        propuesta.finalizacion = block.timestamp + duracion_aux;
        propuesta.ponderacion = ponderacion_aux;
        propuesta.cambio_voto = cambio_voto_aux;
        propuesta.votantes_totales = 0;
        propuesta.votos_totales = 0;

        for (uint256 i = 0; i < opciones_aux.length; i++) {
            propuesta.opciones.push(Opcion({nombre: opciones_aux[i], votos_totales: 0}));
        }
    }

    function votar(uint256 num_propuesta, uint256 num_opcion) public{
        require(block.timestamp <= propuestas[num_propuesta].finalizacion, "La votacion ha finalizado");
        require(num_propuesta < propuestas.length, "La propuesta no existe");
        require(IERC20(direccion_token).balanceOf(msg.sender) >= 1, "No tienes suficientes tokens para poder votar");
        //Propuesta storage propuesta = propuestas[num_propuesta];
        require(num_opcion < propuestas[num_propuesta].opciones.length, "Opcion no valida");
        uint256 num_votos = 1;

        if (propuestas[num_propuesta].ponderacion) {
            uint256 balance = IERC20(direccion_token).balanceOf(msg.sender);
            num_votos = raiz7(balance);
        }

        if (propuestas[num_propuesta].info_votantes[msg.sender] > 0) {
            require(propuestas[num_propuesta].cambio_voto, "No se permite cambiar el voto");
            propuestas[num_propuesta].opciones[propuestas[num_propuesta].info_votantes[msg.sender]- 1].votos_totales -= num_votos;
            propuestas[num_propuesta].votos_totales -= num_votos;
            propuestas[num_propuesta].votantes_totales -= 1;
        }

        propuestas[num_propuesta].votantes_totales += 1;
        propuestas[num_propuesta].info_votantes[msg.sender] = num_opcion + 1;
        propuestas[num_propuesta].opciones[num_opcion].votos_totales += num_votos;
        propuestas[num_propuesta].votos_totales += num_votos;
    }

    function verificar_propuesta(uint256 num_propuesta) public view returns (string memory) {
        require(num_propuesta < propuestas.length, "La propuesta no existe");
        if (block.timestamp <= propuestas[num_propuesta].finalizacion) {
            return "La propuesta aun esta activa";
        } else {
            if (propuestas[num_propuesta].votantes_totales >= propuestas[num_propuesta].votantes_minimos) {
                uint256 opcion_ganadora = 0;
                uint256 votos_ganadora = propuestas[num_propuesta].opciones[0].votos_totales;
                for (uint256 i = 0; i < propuestas[num_propuesta].opciones.length; i++) {
                    if (propuestas[num_propuesta].opciones[i].votos_totales > votos_ganadora) {
                        votos_ganadora = propuestas[num_propuesta].opciones[i].votos_totales;
                        opcion_ganadora = i;
                    }
                }
                uint256 porcentaje_votos = (votos_ganadora / propuestas[num_propuesta].votos_totales) * 100;
                if (porcentaje_votos >= minimo_mayoria) {
                    return string.concat("La opcion ganadora de la propuesta es la opcion |", propuestas[num_propuesta].opciones[opcion_ganadora].nombre, "| con los siguientes votos: ", Strings.toString(votos_ganadora));
                } else {
                    return "La opcion ganadora no cuenta con los votos necesarios para que la propuesta sea valida";
                }
            } else {
                return "La propuesta ha finalizado pero no se ha alcanzado la cantidad minima de votantes";
            }
        }
    }

    function raiz7(uint256 x) private pure returns (uint256) {
        uint256 z = (x + 6) / 7;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / (z * z * z * z * z * z) + 6 * z) / 7;
        }
        return y;
    }
}
