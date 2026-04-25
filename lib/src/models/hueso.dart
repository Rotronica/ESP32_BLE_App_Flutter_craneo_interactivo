// Importa el paquete de Flutter para usar la clase Color
import 'package:flutter/material.dart';

// Clase que representa un hueso del cráneo humano
// Contiene toda la información necesaria para mostrar y controlar cada hueso
class HuesoCraneo {
  // Identificador único del hueso (usado para comandos Bluetooth)
  final int id;
  // Nombre común del hueso en español
  final String nombre;
  // Nombre científico del hueso en latín
  final String nombreCientifico;
  // Descripción anatómica del hueso
  final String descripcion;
  // Dato curioso o histórico sobre el hueso
  final String datoCurioso;
  // Color único para identificar visualmente el hueso en el modelo 3D
  final Color color;

  // Constructor constante que requiere todos los parámetros
  const HuesoCraneo({
    required this.id,
    required this.nombre,
    required this.nombreCientifico,
    required this.descripcion,
    required this.datoCurioso,
    required this.color,
  });
}

// Lista constante con todos los huesos del cráneo disponibles en la aplicación
// Esta lista se puede modificar para agregar, quitar o cambiar huesos
// Los IDs deben ser únicos y consecutivos para los comandos Bluetooth
const List<HuesoCraneo> huesosCraneo = [
  // Hueso Temporal Izquierdo - ID 1
  HuesoCraneo(
    id: 1,
    nombre: 'Temporal Izquierdo',
    nombreCientifico: 'Os temporale sinistrum',
    descripcion:
        'Hueso par que protege estructuras del oído y articulación temporomandibular.',
    datoCurioso:
        'La apófisis mastoides (bulto detrás de la oreja) tarda años en desarrollarse completamente.',
    color: Color(0xFFFFDCA0), // Color crema claro
  ),
  // Hueso Cigomático Izquierdo - ID 2
  HuesoCraneo(
    id: 2,
    nombre: 'Cigomático Izquierdo',
    nombreCientifico: 'Os zygomaticum sinistrum',
    descripcion: 'Forma el pómulo izquierdo y parte de la órbita ocular.',
    datoCurioso:
        'Es el hueso más prominente de la cara, por eso es el que más se fractura en accidentes.',
    color: Color(0xFFFF0000), // Color rojo
  ),
  // Hueso Maxilar Izquierdo - ID 3
  HuesoCraneo(
    id: 3,
    nombre: 'Maxilar Izquierdo y derecho',
    nombreCientifico: 'Maxilla sinistra',
    descripcion:
        'Los huesos maxilares izquierdo y derecho son estructuras pares y simétricas que forman la parte superior de la boca, el paladar y el suelo de la órbita, uniéndose en la línea media. Albergan los dientes superiores y los senos maxilares, cavidades aéreas importantes para la respiración y la resonancia de la voz',
    datoCurioso:
        'Las dos mitades del maxilar se fusionan alrededor de los 4-6 meses de vida fetal.',
    color: Color(0xFF00FF00), // Color verde
  ),
  // Hueso Cigomático Derecho - ID 4
  HuesoCraneo(
    id: 4,
    nombre: 'Cigomático Derecho',
    nombreCientifico: 'Os zygomaticum dextrum',
    descripcion:
        'Forma el pómulo derecho. Da estructura y anclaje a músculos faciales.',
    datoCurioso:
        'También se le llama "malar" y su forma define en gran parte la estructura facial.',
    color: Color(0xFF0000FF), // Color azul
  ),
  // Hueso Temporal Derecho - ID 5
  HuesoCraneo(
    id: 5,
    nombre: 'Temporal Derecho',
    nombreCientifico: 'Os temporale dextrum',
    descripcion:
        'Protege el oído interno y forma la fosa temporal. Contiene el conducto auditivo.',
    datoCurioso:
        'Es el hueso que alberga el martillo, yunque y estribo (los huesos más pequeños del cuerpo).',
    color: Color(0xFF00FFFF), // Color cian
  ),
  // Hueso Esfenoides - ID 6
  HuesoCraneo(
    id: 6,
    nombre: 'Esfenoides',
    nombreCientifico: 'Os sphenoidale',
    descripcion:
        'Hueso con forma de mariposa o murciélago. Conecta casi todos los huesos del cráneo.',
    datoCurioso:
        'Es el hueso más complejo del cráneo, con forma de mariposa y agujeros para nervios y arterias.',
    color: Color(0xFFFF00FF), // Color magenta
  ),
  // Hueso Occipital - ID 7
  HuesoCraneo(
    id: 7,
    nombre: 'Occipital',
    nombreCientifico: 'Os occipitale',
    descripcion:
        'Forma la parte posterior e inferior del cráneo. Contiene el foramen magno.',
    datoCurioso:
        'El agujero magno es por donde pasa la médula espinal conectándose con el cerebro.',
    color: Color(0xFFFFA500),
  ),
  // Hueso Parietal Derecho - ID 8
  HuesoCraneo(
    id: 8,
    nombre: 'Parietal Derecho',
    nombreCientifico: 'Os parietale dextrum',
    descripcion:
        'Forma la parte superior y lateral del cráneo. Se articula con el hueso parietal izquierdo.',
    datoCurioso:
        'En la antigüedad, se usaba para hacer trepanaciones (agujeros para liberar "espíritus malignos").',
    color: Color(0xFFFFFF00), // Color amarillo
  ),
  // Hueso Parietal Izquierdo - ID 9
  HuesoCraneo(
    id: 9,
    nombre: 'Parietal Izquierdo',
    nombreCientifico: 'Os parietale sinistrum',
    descripcion: 'Forma la parte superior y lateral izquierda del cráneo.',
    datoCurioso: 'Es uno de los huesos más resistentes del cuerpo humano.',
    color: Color(0xFFC80000), // Color rojo oscuro
  ),
  // Hueso Frontal - ID 10
  HuesoCraneo(
    id: 10,
    nombre: 'Frontal',
    nombreCientifico: 'Os frontale',
    descripcion:
        'Forma la frente y la parte superior de las órbitas oculares. Contiene los senos frontales.',
    datoCurioso:
        'Es el hueso que más varía entre diferentes personas, dando características únicas a cada rostro.',
    color: Color(0xFFFF69B4), // Color rosa fuerte
  ),

  /*/ Hueso Etmoides - ID 11
  HuesoCraneo(
    id: 11,
    nombre: 'Etmoides',
    nombreCientifico: 'Os ethmoidale',
    descripcion:
        'Hueso poroso que forma parte de la cavidad nasal y las órbitas oculares.',
    datoCurioso:
        'Su nombre viene del griego "ethmós" (criba) porque tiene muchos agujeros pequeños.',
    color: Color(0xFFFFFF00), // Color amarillo
  ),
  // Hueso Mandíbula - ID 12
  HuesoCraneo(
    id: 12,
    nombre: 'Mandíbula',
    nombreCientifico: 'Mandíbula',
    descripcion:
        'Único hueso móvil del cráneo. Permite la masticación y el habla.',
    datoCurioso:
        'Es el hueso más fuerte de la cara y el segundo más resistente del cuerpo después del fémur.',
    color: Color(0xFFC80000), // Color rojo oscuro
  ),
  // Hueso Maxilar Derecho - ID 13
  HuesoCraneo(
    id: 13,
    nombre: 'Maxilar Derecho',
    nombreCientifico: 'Maxilla dextra',
    descripcion:
        'Forma el maxilar superior. Contiene los dientes superiores y el paladar duro.',
    datoCurioso: 'Es el hueso facial más grande después de la mandíbula.',
    color: Color(0xFFFF69B4), // Color rosa fuerte
  ),

  // Hueso Nasal Derecho - ID 14
  HuesoCraneo(
    id: 14,
    nombre: 'Nasal Derecho',
    nombreCientifico: 'Os nasale dextrum',
    descripcion: 'Forma el puente de la nariz derecha.',
    datoCurioso:
        'Son los huesos más pequeños de la cara y los que más varían entre etnias.',
    color: Color(0xFFCD853F), // Color marrón claro
  ),
  // Hueso Nasal Izquierdo - ID 15
  HuesoCraneo(
    id: 15,
    nombre: 'Nasal Izquierdo',
    nombreCientifico: 'Os nasale sinistrum',
    descripcion: 'Forma el puente de la nariz izquierda.',
    datoCurioso:
        'La mayoría de las fracturas nasales ocurren en la unión de estos dos huesos.',
    color: Color(0xFFA0522D), // Color marrón oscuro
  ),
  // Hueso Lagrimal Derecho - ID 16
  HuesoCraneo(
    id: 16,
    nombre: 'Lagrimal Derecho',
    nombreCientifico: 'Os lacrimale dextrum',
    descripcion:
        'Hueso diminuto en la pared medial de la órbita. Contiene el conducto lagrimal.',
    datoCurioso: 'Es el hueso más frágil y pequeño del cuerpo humano.',
    color: Color(0xFF7FFFD4), // Color aguamarina
  ),
  // Hueso Lagrimal Izquierdo - ID 17
  HuesoCraneo(
    id: 17,
    nombre: 'Lagrimal Izquierdo',
    nombreCientifico: 'Os lacrimale sinistrum',
    descripcion: 'Hueso par que alberga el sistema de drenaje de lágrimas.',
    datoCurioso: 'Si se fractura, puede causar lagrimeo constante.',
    color: Color(0xFF40E0D0),
  ),
  // Hueso Palatino Derecho - ID 18
  HuesoCraneo(
    id: 18,
    nombre: 'Palatino Derecho',
    nombreCientifico: 'Os palatinum dextrum',
    descripcion: 'Forma parte del paladar duro y la fosa pterigopalatina.',
    datoCurioso:
        'Tiene forma de "L" y participa en el techo de la boca y en el suelo de la órbita.',
    color: Color(0xFFFFD700), // Color dorado
  ),
  // Hueso Palatino Izquierdo - ID 19
  HuesoCraneo(
    id: 19,
    nombre: 'Palatino Izquierdo',
    nombreCientifico: 'Os palatinum sinistrum',
    descripcion: 'Hueso par que forma la parte posterior del paladar duro.',
    datoCurioso:
        'La úvula (campanilla) se inserta en el borde posterior del paladar duro.',
    color: Color(0xFFC0C0C0), // Color plata
  ),
  // Hueso Cornete Derecho - ID 20
  HuesoCraneo(
    id: 20,
    nombre: 'Cornete Derecho',
    nombreCientifico: 'Concha nasalis inferior dextra',
    descripcion:
        'Estructura ósea en forma de concha en la cavidad nasal derecha.',
    datoCurioso:
        'Ayuda a humidificar y calentar el aire que respiras, además de filtrar partículas.',
    color: Color(0xFFFA8072), // Color salmón
  ),
  // Hueso Cornete Izquierdo - ID 21
  HuesoCraneo(
    id: 21,
    nombre: 'Cornete Izquierdo',
    nombreCientifico: 'Concha nasalis inferior sinistra',
    descripcion: 'Concha nasal inferior izquierda, independiente del etmoides.',
    datoCurioso:
        'Es el único cornete que es un hueso independiente, los demás son parte del etmoides.',
    color: Color(0xFFFF7F50), // Color coral
  ),
  // Hueso Vómer - ID 22
  HuesoCraneo(
    id: 22,
    nombre: 'Vómer',
    nombreCientifico: 'Vomer',
    descripcion:
        'Hueso delgado que forma el tabique nasal inferior y posterior.',
    datoCurioso:
        'Su nombre en latín significa "reja de arado" por su forma característica.',
    color: Color(0xFFFFF8DC), // Color crema
  ),*/
];

// Fin de la lista de huesos del cráneo
// Esta lista contiene todos los 22 huesos principales del cráneo humano
// Cada hueso tiene información educativa y un color único para identificación visual
