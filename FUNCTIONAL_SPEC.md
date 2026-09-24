# Instalador Electricista CBA — Especificación Funcional

## 1. Objetivo

Instalador Electricista CBA es una aplicación iOS orientada a asistir al Instalador Electricista Habilitado de Categoría III de la provincia de Córdoba, Argentina, en el proyecto, cálculo, verificación y documentación de instalaciones eléctricas de viviendas.

El alcance inicial estará orientado a viviendas comprendidas dentro de las competencias de Categoría III y de la Guía AEA 770 para viviendas unifamiliares de hasta 10 kW.

La aplicación debe funcionar como asistente técnico y normativo. No debe reemplazar el criterio ni la responsabilidad profesional del instalador.

---

## 2. Principio general

La aplicación no será una colección de calculadoras independientes.

Un proyecto eléctrico será un modelo relacionado donde las decisiones tomadas en una etapa afectarán automáticamente a las siguientes.

Flujo general:

Datos del inmueble
→ SLA
→ Grado de electrificación preliminar
→ Ambientes
→ Puntos mínimos de utilización
→ Circuitos mínimos
→ Cargas previstas
→ DPMS
→ Grado de electrificación definitivo
→ Potencia de proyecto
→ Corriente de proyecto
→ Determinación del suministro
→ Conductores
→ Canalizaciones y agrupamiento
→ Protecciones
→ Caída de tensión
→ Puesta a tierra
→ Tablero
→ Verificación integral
→ Diagrama unifilar
→ Memoria técnica

---

## 3. Alcance inicial

La primera versión estará limitada a:

- Provincia de Córdoba.
- Viviendas.
- Instalaciones de baja tensión.
- Alcance profesional correspondiente a Categoría III.
- Proyectos dentro del límite de potencia aplicable.
- Reglamentación AEA aplicable.
- Guía AEA 770.
- Requisitos aplicables de ERSeP Córdoba.
- Requisitos de seguridad y certificación de materiales aplicables.

Quedan inicialmente fuera de alcance:

- Instalaciones industriales.
- Grandes comercios.
- Instalaciones fotovoltaicas.
- Generación distribuida.
- Cargadores de vehículos eléctricos.
- Automatización/domótica.
- Instalaciones que excedan las competencias de Categoría III.

---

## 4. Nuevo proyecto

El usuario podrá crear un proyecto ingresando inicialmente los datos físicos y administrativos conocidos.

Ejemplos:

- Nombre del proyecto.
- Titular.
- Dirección.
- Localidad.
- Superficie cubierta.
- Superficie semicubierta.
- Datos adicionales necesarios.

El tipo de suministro NO será inicialmente seleccionado por el usuario.

La aplicación deberá determinar posteriormente si el proyecto requiere suministro monofásico o trifásico a partir de los cálculos correspondientes.

---

## 5. SLA y grado de electrificación

La aplicación calculará la Superficie Límite de Aplicación (SLA) según las reglas normativas confirmadas.

A partir de la SLA determinará el grado de electrificación preliminar.

El grado de electrificación deberá posteriormente verificarse nuevamente utilizando la DPMS y demás criterios aplicables.

El grado definitivo nunca deberá obtenerse mediante valores arbitrarios destinados a reducir artificialmente los requisitos del proyecto.

---

## 6. Ambientes

El usuario construirá la vivienda mediante ambientes tipificados.

Ejemplos:

- Cocina.
- Living.
- Comedor.
- Dormitorio.
- Baño.
- Lavadero.
- Pasillo.
- Garage.
- Exterior.
- Otros contemplados por la normativa.

Cada ambiente tendrá dimensiones y/o superficie y estará relacionado con sus puntos de utilización.

El tipo de ambiente deberá formar parte del modelo de dominio y no almacenarse únicamente como texto libre.

---

## 7. Puntos mínimos de utilización

La aplicación determinará los puntos mínimos requeridos para cada ambiente según las reglas aplicables.

Podrá contemplar, entre otros:

- Puntos de iluminación.
- Tomacorrientes.
- Tomas de uso especial.
- Cargas específicas.

La aplicación comparará:

mínimo reglamentario
vs.
proyecto realizado.

Deberá advertir cuando un ambiente no alcance los mínimos correspondientes.

---

## 8. Ayuda para ubicación de elementos

Durante el diseño de cada ambiente, la aplicación ofrecerá ayuda contextual sobre ubicación y restricciones de los elementos eléctricos.

Ejemplos:

- Alturas.
- Distancias.
- Separaciones respecto de mesadas.
- Proximidad a piletas.
- Restricciones en baños.
- Ubicación de tomacorrientes.
- Ubicación de interruptores.
- Zonas con requisitos especiales.

Los valores exactos deberán provenir de reglas normativas verificadas.

La aplicación no deberá inventar distancias ni utilizar recomendaciones no verificadas como requisitos reglamentarios.

---

## 9. Circuitos

La aplicación determinará la cantidad y los tipos mínimos de circuitos requeridos según el grado de electrificación y demás criterios aplicables.

El usuario podrá agregar circuitos adicionales.

Cada punto de utilización deberá poder asociarse a un circuito.

El proyecto deberá permitir representar circuitos tales como:

- IUG.
- TUG.
- TUE.
- Otros tipos contemplados por la normativa.

---

## 10. Cargas y DPMS

Cada circuito tendrá asociadas sus cargas.

La aplicación calculará la demanda correspondiente y finalmente la Demanda de Potencia Máxima Simultánea (DPMS).

Cuando la normativa permita utilizar factores o coeficientes de utilización, simultaneidad u otros factores de demanda, éstos deberán:

- Estar respaldados por una regla documentada.
- Mostrar su valor.
- Mostrar dónde fueron aplicados.
- Mostrar cómo modificaron el resultado.

Nunca deberán utilizarse coeficientes arbitrarios con el único objetivo de reducir la potencia calculada.

---

## 11. Determinación del suministro

El suministro será un resultado del proyecto y no un dato inicial.

A partir de:

- Potencia calculada.
- DPMS.
- Factores reglamentarios aplicables.
- Corriente de proyecto.
- Límites reglamentarios y del prestador.

la aplicación determinará si corresponde suministro:

- Monofásico.
- Trifásico.

Cuando el proyecto esté próximo a superar un límite, la aplicación deberá advertirlo.

Si existen alternativas reglamentariamente válidas que permitan optimizar la demanda, podrá mostrarlas al instalador indicando claramente qué cálculo y criterio se aplica.

La aplicación nunca reducirá silenciosamente la demanda para mantener un suministro determinado.

---

## 12. Conductores

El dimensionamiento de conductores deberá considerar todos los parámetros necesarios según la normativa aplicable.

Entre ellos podrán encontrarse:

- Material.
- Sección.
- Tipo de aislación.
- Método de instalación.
- Temperatura.
- Cantidad de conductores cargados.
- Longitud.
- Condiciones ambientales.
- Factores de corrección.

El resultado deberá mostrar la capacidad base y la capacidad corregida cuando corresponda.

---

## 13. Canalizaciones y agrupamiento

Las canalizaciones serán entidades del proyecto.

Cada canalización conocerá qué circuitos y conductores contiene.

Cuando varios circuitos compartan una canalización, el motor deberá aplicar los factores de corrección por agrupamiento que correspondan.

La capacidad admisible final del conductor deberá calcularse luego de aplicar los factores correspondientes.

Un circuito que sea válido individualmente podrá pasar a ser no conforme debido a las condiciones reales de instalación.

---

## 14. Corriente de proyecto

La corriente deberá calcularse a partir de las características eléctricas reales del sistema.

El cálculo deberá distinguir correctamente entre sistemas monofásicos y trifásicos.

No deberá existir una única fórmula de corriente aplicada indistintamente a ambos sistemas.

En sistemas trifásicos podrá incorporarse posteriormente análisis y asistencia para balance de fases.

---

## 15. Caída de tensión

La aplicación calculará la caída de tensión considerando los parámetros eléctricos correspondientes.

Deberá poder contemplar la caída acumulada a lo largo de distintos tramos de la instalación.

Ejemplo conceptual:

Línea principal
+ circuito seccional
+ circuito terminal
= caída total hasta el punto de utilización.

Los límites deberán provenir de reglas normativas documentadas.

---

## 16. Protecciones

La aplicación asistirá en la selección y verificación de:

- Protección general.
- Interruptores automáticos.
- Interruptores diferenciales.
- Protecciones de circuitos.
- Poder de corte.
- Coordinación conductor/protección.
- Otras protecciones requeridas.

Siempre que sea posible deberá mostrar las relaciones matemáticas que justifican la selección.

Una protección no deberá considerarse válida únicamente por coincidir con un valor comercial.

---

## 17. Puesta a tierra

La aplicación tendrá un módulo específico de puesta a tierra.

Podrá contemplar:

- Electrodo.
- Conductor de protección.
- Conductor principal.
- Equipotencialidad.
- Protección diferencial.
- Valores proyectados.
- Valores medidos durante la verificación de obra.

Se distinguirá entre valores calculados/proyectados y valores efectivamente medidos.

---

## 18. Materiales y seguridad

Los elementos utilizados en la instalación deberán permitir registrar información como:

- Fabricante.
- Modelo.
- Norma aplicable.
- Certificación.
- Características eléctricas.

La aplicación advertirá cuando falte información requerida para comprobar la conformidad de un elemento.

Los requisitos específicos de certificación deberán implementarse únicamente después de verificar la normativa aplicable a cada familia de productos.

---

## 19. Tablero eléctrico

La aplicación construirá el tablero a partir de las protecciones y circuitos del proyecto.

Deberá calcular:

- Cantidad de dispositivos.
- Polos/módulos ocupados.
- Espacio de reserva requerido.
- Capacidad mínima necesaria del tablero.

Luego podrá sugerir el tamaño comercial inmediatamente superior compatible con el cálculo.

El porcentaje o criterio de reserva deberá provenir de una regla normativa confirmada.

---

## 20. Diagrama unifilar

El diagrama unifilar se generará automáticamente a partir del modelo del proyecto.

La fuente de verdad será la instalación modelada, no un dibujo independiente.

Cambios en:

- Suministro.
- Protecciones.
- Conductores.
- Circuitos.
- Tablero.

deberán reflejarse automáticamente en el diagrama.

---

## 21. Verificación integral

La aplicación tendrá una etapa de revisión del proyecto completo.

Los resultados deberán distinguir como mínimo:

- Conforme.
- Advertencia.
- No conforme.
- Pendiente de información.
- Pendiente de validación normativa.

La aplicación deberá verificar la coherencia entre las distintas partes del proyecto y no solamente cada cálculo de forma aislada.

---

## 22. Trazabilidad normativa

Toda regla normativa implementada deberá tener una referencia identificable.

Conceptualmente, una regla deberá poder registrar:

- Identificador.
- Fuente.
- Edición.
- Sección o referencia.
- Descripción.
- Estado de validación.

Los cálculos eléctricos puros deberán mantenerse separados de las reglas normativas.

Cuando una regla no esté confirmada, deberá permanecer explícitamente pendiente y no convertirse en comportamiento definitivo de la aplicación.

---

## 23. Explicación de resultados

Los resultados importantes deberán ser auditables por el instalador.

Siempre que sea razonable, el usuario podrá consultar:

- Datos de entrada.
- Fórmula.
- Unidades.
- Factores aplicados.
- Resultado intermedio.
- Resultado final.
- Regla normativa utilizada.

El objetivo es evitar resultados de tipo "caja negra".

---

## 24. Memoria técnica

La aplicación podrá generar una memoria técnica del proyecto.

La memoria podrá incluir:

1. Datos del inmueble.
2. Datos del profesional.
3. Alcance.
4. Características del suministro.
5. SLA.
6. Grado de electrificación.
7. Puntos de utilización.
8. Circuitos.
9. Cuadro de cargas.
10. DPMS.
11. Corrientes de proyecto.
12. Conductores.
13. Factores de corrección.
14. Canalizaciones.
15. Caídas de tensión.
16. Protecciones.
17. Diferenciales.
18. Puesta a tierra.
19. Tablero.
20. Verificaciones.
21. Diagrama unifilar.
22. Observaciones.
23. Datos y firma del profesional.

El documento deberá generarse utilizando los datos ya existentes en el proyecto, evitando volver a ingresar información.

---

## 25. Principio de seguridad

La aplicación priorizará una instalación segura y reglamentariamente justificable.

No deberá recomendar reducciones de sección, protecciones, demandas, materiales o requisitos con el único objetivo de reducir costos o evitar un cambio de suministro.

Cuando existan varias soluciones válidas podrá mostrarlas y explicar sus diferencias.

---

## 26. MVP

El primer objetivo funcional completo será poder realizar el proyecto de una vivienda dentro del alcance definido mediante:

SLA
→ grado de electrificación
→ ambientes
→ puntos mínimos
→ circuitos
→ cargas
→ DPMS
→ suministro
→ conductores
→ agrupamiento
→ canalizaciones
→ caída de tensión
→ protecciones
→ diferencial
→ puesta a tierra
→ tablero
→ verificación
→ unifilar
→ memoria técnica.

La implementación se realizará incrementalmente.

La primera funcionalidad a implementar será:

Datos básicos del proyecto
→ cálculo de SLA
→ determinación del grado de electrificación preliminar.

Esta primera funcionalidad deberá tener pruebas unitarias antes de continuar con las siguientes etapas.
