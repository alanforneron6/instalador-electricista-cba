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

Cada boca distribuible deberá poder asociarse a un circuito. Los módulos de
tomacorriente son equipamiento del ambiente, no bocas adicionales.

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

Estado implementado al cierre de Feature 004:

- Feature 001: datos básicos, SLA automática y GE según superficie.
- Feature 002: ambientes, mínimos de bocas y módulos, y comparación con lo proyectado.
- Feature 003: circuitos mínimos, variantes, ACU y distribución de bocas.
- Feature 004: cargas, factor de potencia y DPMS trazable.
- UX-001: flujo guiado de cuatro pasos validado manualmente en Simulator.

Las secciones generales anteriores describen también el alcance futuro del producto.
Suministro, conductores y demás funcionalidades posteriores siguen fuera de la
implementación actual. Features 001–004 cuentan con pruebas unitarias.

## Feature 003 implementada

Después de ambientes, el proyecto permite elegir explícitamente la variante de
circuitos mínimos, completar los tipos faltantes, crear circuitos adicionales,
seleccionar la posición libre de GE Superior y distribuir las bocas IUG/TUG.
Los módulos de cocina se validan como equipamiento del ambiente, sin materializar bocas adicionales. El resumen muestra identificación,
tipo, destino editable, bocas o una carga ACU y potencia declarada con su unidad.
Las validaciones distinguen faltantes, exceso de bocas, bocas sin asignar,
incompatibilidades y decisiones pendientes. La conformidad de composición mínima
no representa conformidad integral. Los cálculos de cargas y DPMS están implementados en Feature 004.

## Feature 004 — Cargas y DPMS

- Se conserva la carga original ACU (valor y unidad). VA es potencia aparente
  directa; W, kW y HP requieren factor de potencia explícito, finito, 0 < fp <= 1.
- El criterio de conversión de este proyecto es HP × 746 W/HP y S = P/fp;
  no se incorpora rendimiento ni un fp por defecto.
- Cada circuito presenta bocas, base, mínimo reglamentario, demanda conocida
  cuando exista y DPMS adoptada. IUG usa el alcance sin tomacorrientes derivados.
- IUG/TUG/TUE admiten una demanda conocida opcional en VA, comparable con el
  mínimo; se adopta el mayor. No se confunde con la suma de potencias de placa.
- Se pueden editar carga y fp de un ACU existente sin cambiar su identidad ni
  reemplazar su declaración por el resultado de la conversión.
- El resumen separa base IUG/TUG/TUE, coeficiente GE, DPMS GE, cargas específicas
  resolubles y total. ACU no recibe el coeficiente GE ni reducciones Ku/Ks.
- Los errores y datos faltantes son estados tipados. Si un ACU no tiene carga o
  fp necesario, se muestra el subtotal resoluble como incompleto y el total
  queda pendiente. Un desbordamiento no se convierte en cero ni infinito válido.
- Los cálculos individuales usan las bocas asignadas a cada circuito. Si quedan
  puntos IUG/TUG sin asignar, el total completo devuelve unassignedPoints y sólo
  puede mostrarse el subtotal resoluble como incompleto, sin asignar puntos
  automáticamente. Asignaciones incompatibles o a circuitos inexistentes producen
  incompatibleAssignments. Los módulos de cocina no generan bocas distribuibles ni demanda independiente
  y no bloquean por sí solos la DPMS. La DPMS no declara
  conformidad integral del proyecto.
- No se calcula Ib, suministro, conductores, Iz, protecciones, caída de tensión,
  canalizaciones, agrupamiento, diagramas ni PDF; no se implementa Feature 005.
  El GE sigue siendo preliminar, sin reclasificación automática por DPMS.


## UX-001 — Iteración 1: flujo guiado

La creación y revisión se organiza en un NavigationStack nativo de cuatro pasos:

1. **Proyecto**: nombre y superficies con etiquetas/unidades visibles. SLA y grado
   de electrificación según superficie se calculan automáticamente con los motores
   existentes, mostrando la semicubierta como división por dos. No hay botón
   Calcular: Continuar se habilita con nombre y superficies válidos, sin confirmación
   previa. Cambiar superficies actualiza SLA/GE; editar el nombre no los invalida.
2. **Ambientes**: tarjetas con cantidades y estado Cumple/Incompleto, contador
   persistente y alta mediante formulario con etiquetas y steppers. Los mínimos
   y faltantes se actualizan mientras se carga el ambiente, utilizando las reglas
   existentes. Al agregar, se limpia el formulario y aparece feedback durante
   aproximadamente 1,5 segundos.
3. **Circuitos**: elección explícita de variante, generación/completado de mínimos,
   circuitos adicionales y tarjetas con bocas/máximo existente. La distribución
   se agrupa por ambiente y muestra asignados/total, excluyendo del denominador
   los módulos, que no constituyen bocas adicionales. Los selectores
   sólo ofrecen circuitos compatibles según las reglas actuales.
4. **Demanda**: detalle de cálculo por circuito, edición de cargas y fp, resumen
   del GE, cargas específicas separadas y DPMS total. Los datos provienen de
   DemandEngine; un subtotal resoluble se identifica siempre como incompleto.

El indicador «Paso N de 4» y la barra de progreso acompañan cada pantalla.
Un único ProjectForm vive en el estado de la raíz de navegación. Avanzar/volver
sólo cambia la ruta, conservando proyecto, ambientes, puntos, circuitos,
asignaciones, cargas, fp e identidades. Los formularios reutilizan las validaciones
existentes; los datos de carga se guardan con «Aplicar datos de carga».
La conservación es durante la sesión: no se incorpora persistencia en disco.

Los módulos se presentan como «Módulos adicionales para electrodomésticos de
ubicación fija». Se conservan en los mínimos del ambiente; no se convierten en
bocas, TUE ni ACU. Los faltantes se
presentan en naranja, cumplimiento en verde y errores reales en rojo, siempre
con texto/símbolo. Las fuentes y aclaraciones permanecen disponibles mediante
«Ver criterio normativo», sin ocupar el contenido principal.

No se modifican fórmulas, valores, resultados del motor, referencias regulatorias
ni el deployment target iOS 26. No se implementa Feature 005. Las verificaciones
de presentación/estado son unitarias y no dependen del runner de UI.


## UX-001 — Iteración 1.1: ajustes de uso

- El nombre es texto libre (espacios, tildes, abreviaturas, números y puntuación).
  Sólo se rechaza si queda vacío al quitar espacios y saltos de línea externos.
  Cambiar esta etiqueta no invalida un cálculo de superficies válido.
- El GE se presenta como «Grado de electrificación según superficie», determinado
  por la SLA. La nota del dormitorio mayor a 36 m² se explica como criterio
  particular del ambiente, sin alterar el GE global ni su regla existente.
- Se usa «bocas (puntos de utilización)» en la introducción y luego «bocas» en
  cantidades, faltantes y distribución. Los tipos del dominio no se renombran.
- Elegir una variante no crea circuitos. «Crear circuitos mínimos» o «Completar
  circuitos mínimos» ejecuta la acción existente, con confirmación durante
  aproximadamente 1,5 segundos. Repetirla no duplica circuitos; se informa cuando
  ya están completos. La posición libre pendiente no se declara resuelta.
- Cada ambiente explica la asignación de bocas y distingue «Iluminación 1 · IUG»
  de «Tomacorriente 1 · TUG». Sin circuitos compatibles se muestra una explicación;
  con ellos aparece el selector, conservando «Sin asignar». Los módulos
  no se materializan ni aparecen en la distribución.
- «Editar circuito» permite modificar destino, potencia, unidad y fp del ACU
  mediante el formulario existente, manteniendo identidad y relaciones. VA no
  requiere fp; no se agregan valores por defecto para otras unidades.
- Los criterios normativos se presentan con norma, edición y referencias
  documentadas, aclaraciones humanas y Rule ID secundario, sin nombres de
  archivos internos. Las referencias pendientes siguen explícitamente pendientes.
- Los VA se presentan en formato argentino con hasta dos decimales y sin ceros
  finales innecesarios. La explicación HP incluye unidades del multiplicador;
  tanto el resultado como la traza siguen proviniendo del motor sin redondear el
  dominio. No se modifica ninguna regla ni se incorpora Feature 005.


### Corrección posterior a Iteración 1.1 — cálculo automático y teclado

Paso 1 y destinos consultan el mismo ProjectForm mediante bindings al estado raíz.
El resultado se deriva de los datos actuales, sin banderas de cálculo manual ni
copias de superficies. Continuar valida ese resultado y sólo modifica la ruta;
no recrea el formulario ni sus identidades. El fallback de datos inválidos queda
como defensa y no como destino normal de un formulario incompleto.

Los campos de superficies, dimensiones, potencia, factor de potencia y demanda
conocida usan teclado decimal en iOS, con «Listo» para cerrarlo y descarte al
arrastrar el formulario. Los parsers siguen aceptando coma o punto. Los contadores
enteros mantienen sus steppers. La lógica de edición ACU permanece sin cambios.


### Módulos de cocina y bocas distribuibles

Una boca física y un módulo de tomacorriente son dimensiones diferentes.
Los módulos adicionales para electrodomésticos de ubicación fija se materializan
dentro de las bocas TUG existentes, pudiendo compartirlas con otros tomacorrientes.
Por ejemplo, 3 bocas TUG + 2 módulos adicionales pueden materializarse como
2 + 2 + 1 módulos/tomacorrientes: siguen siendo 3 bocas, con 5 módulos totales.
El modelo actual conserva el requisito adicional por ambiente; no registra la
cantidad de módulos dentro de cada boca individual. Se conserva `UtilizationPointKind.fixedApplianceModule`
para la proyección y validación de mínimos del ambiente. `CircuitPointKind`
representa exclusivamente las bocas IUG/TUG que se materializan como
`UtilizationPoint`. Una cocina con 2 IUG, 3 TUG y 2 módulos genera cinco bocas
para distribuir; los módulos no crean circuitos, cargas ni demanda independiente.
No existe una decisión de compatibilidad TUG/TUE/ACU pendiente para esos módulos.
Referencia: AEA 90364-7-770:2017, 770.7.5, Tabla 770.7.III.
