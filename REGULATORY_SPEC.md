# Instalador Electricista CBA — Especificación Normativa

## 1. Propósito

Este documento registra las reglas normativas utilizadas por la aplicación.

Ninguna regla AEA, ERSeP, IRAM, de una distribuidora eléctrica o de otra autoridad debe implementarse como comportamiento definitivo de la aplicación si no se encuentra documentada y validada aquí.

Este documento no reproduce las reglamentaciones completas. Registra únicamente los criterios necesarios para implementar y auditar los cálculos y validaciones de la aplicación.

---

## 2. Estados de las reglas

Cada regla tendrá uno de los siguientes estados:

- VERIFIED: fuente, edición y referencia verificadas.
- PENDING_SOURCE: conocemos o sospechamos el criterio, pero falta verificar la fuente.
- PENDING_INTERPRETATION: existe una fuente, pero debemos confirmar cómo aplicarla.
- DISTRIBUTOR_DEPENDENT: depende de la distribuidora o prestador.
- NOT_APPLICABLE: regla analizada pero fuera del alcance actual.

Codex nunca deberá transformar una regla PENDING en VERIFIED por su cuenta.

---

## 3. Formato de una regla

Cada regla deberá documentarse aproximadamente así:

RULE-ID

Nombre:
Estado:

Fuente:
Edición:
Referencia:

Alcance:

Entradas:

Regla:

Resultado:

Casos límite:

Impacto en otras reglas:

Tests requeridos:

Notas:

---

# REGLAS CONFIRMADAS

## RULE-SLA-001

Nombre:
Cálculo de la superficie límite de aplicación.

Estado:
VERIFIED

Fuente:
AEA 90364-7-770

Edición:
2017

Referencia:
770.7.3 — Grado de electrificación.

Alcance:
Viviendas comprendidas por la sección 770.

Entradas:
- Superficie cubierta en m².
- Superficie semicubierta en m².

Regla:

SLA = superficie cubierta + 50% de la superficie semicubierta.

Resultado:
Superficie límite de aplicación expresada en m².

Casos límite:
- Superficie cubierta igual a cero.
- Superficie semicubierta igual a cero.
- Valores negativos deben considerarse inválidos.

Impacto:
La SLA se utiliza para determinar el grado de electrificación preliminar.

Tests requeridos:
- Sólo superficie cubierta.
- Superficie cubierta + semicubierta.
- Valores en los límites de cada grado.
- Valores inválidos negativos.

---

## RULE-GE-001

Nombre:
Grado de electrificación preliminar según SLA.

Estado:
VERIFIED

Fuente:
AEA 90364-7-770

Edición:
2017

Referencia:
770.7.3 y Tabla 770.7.I.

Regla:

SLA <= 60 m²:
Grado mínimo.

SLA > 60 m² y <= 130 m²:
Grado medio.

SLA > 130 m² y <= 200 m²:
Grado elevado.

SLA > 200 m²:
Grado superior.

Resultado:
Grado de electrificación preliminar.

Casos límite:
60 m² pertenece a mínimo.
130 m² pertenece a medio.
200 m² pertenece a elevado.

Tests requeridos:
- 0 m².
- 60 m².
- Valor inmediatamente superior a 60 m².
- 130 m².
- Valor inmediatamente superior a 130 m².
- 200 m².
- Valor inmediatamente superior a 200 m².

---

## RULE-BOARD-RESERVE-001

Nombre:
Reserva mínima del tablero.

Estado:
VERIFIED

Fuente:
AEA 90364-7-770

Edición:
2017

Referencia:
770.16.4 — Forma constructiva de los tableros.

Regla:
Los tableros deben disponer de una reserva para futuras ampliaciones de al menos el 20% de su capacidad total, medida en módulos de 18 mm.

Resultado:
El tablero seleccionado debe disponer de capacidad suficiente para los módulos utilizados y la reserva reglamentaria.

Notas:
No utilizar 50% como reserva reglamentaria salvo que posteriormente se identifique otra exigencia aplicable de ERSeP, distribuidora o una edición normativa diferente.

La forma exacta de redondear y seleccionar tamaños comerciales deberá definirse separadamente.

---

## RULE-CIRCUITS-001

Nombre:
Cantidad y tipo mínimo de circuitos según grado de electrificación.

Estado:
VERIFIED

Fuente:
AEA 90364-7-770

Edición:
2017

Referencia:
770.7.4 — Tabla 770.7.II.

Regla:

Grado mínimo:
- mínimo total: 2 circuitos.
- 1 IUG.
- 1 TUG.

Grado medio:
- mínimo total: 3 circuitos.
- Variante A: 2 IUG + 1 TUG.
- Variante B: 1 IUG + 2 TUG.

Grado elevado:
- mínimo total: 5 circuitos.
- Variante A: 2 IUG + 3 TUG.
- Variante B: 3 IUG + 2 TUG.

Grado superior:
- mínimo total: 6 circuitos.
- Variante A: 2 IUG + 3 TUG + 1 circuito de libre elección.
- Variante B: 3 IUG + 2 TUG + 1 circuito de libre elección.

Regla de producto:
Cuando exista más de una variante válida, el motor no deberá elegir silenciosamente una.
La elección deberá quedar representada explícitamente en el proyecto.

Tests requeridos:
- Grado mínimo: 2 circuitos, 1 IUG + 1 TUG.
- Grado medio: 3 circuitos, variantes A y B.
- Grado elevado: 5 circuitos, variantes A y B.
- Grado superior: 6 circuitos, variantes A y B, incluyendo el circuito de libre elección.
- Elección explícita de la variante en el proyecto cuando exista más de una válida.

---

## RULE-ROOM-POINTS-001

Nombre:
Puntos mínimos de utilización por ambiente.

Estado:
VERIFIED

Fuente:
AEA 90364-7-770

Edición:
2017

Referencia:
770.7.5 — Tabla 770.7.III.

Regla:

Sala de estar, comedor, comedor diario, escritorio, estudio, biblioteca o similar:
- IUG = una boca por cada 18 m² o fracción, mínimo 1.
- TUG = una boca por cada 6 m² o fracción, mínimo 2.

Dormitorio menor a 10 m²:
- IUG = 1.
- TUG = 2.

Dormitorio desde 10 m² hasta 36 m² inclusive:
- IUG = 1.
- TUG = 3.

Dormitorio mayor a 36 m²:
- IUG = 2.
- TUG = 3.
- Aplicar la nota normativa indicada más abajo para viviendas cuyo grado preliminar pudiera ser inferior al elevado.

Cocina:
- los mínimos dependen del grado de electrificación;
- GE mínimo: 1 IUG; 3 bocas TUG + 2 módulos para electrodomésticos de ubicación fija.
- GE medio: 2 IUG; 3 bocas TUG + 2 módulos para electrodomésticos de ubicación fija.
- GE elevado: 2 IUG; 3 bocas TUG + 3 módulos para electrodomésticos de ubicación fija.
- GE superior: 2 IUG; 4 bocas TUG + 3 módulos para electrodomésticos de ubicación fija.

Los módulos destinados a electrodomésticos de ubicación fija son equipamiento de
los tomacorrientes de cocina y pueden compartir una boca con otros tomacorrientes.
Se validan separadamente de las bocas: 3 bocas TUG + 2 módulos adicionales no
equivalen a 5 bocas TUG. Los módulos adicionales se materializan dentro de esas
3 bocas (por ejemplo, 2 + 2 + 1 módulos/tomacorrientes, 5 en total).
No constituyen por sí mismos circuitos ni cargas específicas.
Aclaración semántica confirmada por el titular en esta revisión, con la misma
referencia AEA 90364-7-770:2017, 770.7.5, Tabla 770.7.III.

Baño:
- IUG = 1.
- TUG = 1.

Lavadero:
- IUG = 1.
- GE mínimo: TUG = 1.
- GE medio/elevado/superior: TUG = 2.

Vestíbulo, garaje, hall, vestidor o similares:
- GE mínimo: 1 IUG + 1 TUG.
- GE medio/elevado/superior:
  IUG = una boca cada 12 m² o fracción, mínimo 1.
  TUG = una boca cada 12 m² o fracción, mínimo 1.

Pasillos cubiertos:
- Calcular los puntos utilizando longitud y no superficie.
- IUG: una boca cada 5 m de longitud o fracción, mínimo una, para todos los grados.
- Para grados medio, elevado y superior, TUG: una boca cada 5 m de longitud o fracción cuando la longitud sea mayor a 2 m.
- Para grado mínimo no exigir TUG por esta regla.

Balcones, galerías, atrios o similares espacios semicubiertos y pasillos descubiertos:
- IUG: una boca cada 5 m de longitud o fracción.
- La tabla no establece TUG mínimo para este caso.

Notas normativas:
1. Para viviendas con superficie inferior a 130 m² que excepcionalmente tengan dormitorios mayores a 36 m², los puntos mínimos correspondientes deben tratarse con el criterio de grado elevado.
2. En viviendas tipo loft, el grado de electrificación se determina según la superficie total.

Consecuencia de modelado:
Room deberá poder proporcionar, según su tipo:
- superficie;
- longitud;
- grado de electrificación del proyecto.

Los datos que no sean necesarios para determinado ambiente no deben exigirse arbitrariamente.

Tests requeridos:
- Cálculos que requieran redondear por fracción.
- Living menor a 18 m².
- Living 18 m².
- Living inmediatamente mayor a 18 m².
- Living 6 m² y valor inmediatamente mayor.
- Dormitorio inmediatamente menor a 10 m².
- Dormitorio exactamente 10 m².
- Dormitorio inmediatamente mayor a 10 m².
- Dormitorio inmediatamente menor a 36 m².
- Dormitorio exactamente 36 m².
- Dormitorio inmediatamente mayor a 36 m².
- Cocina para cada GE.
- Garage en GE mínimo y medio.
- Pasillo de 2 m y apenas mayor a 2 m.
- Vivienda menor a 130 m² con dormitorio mayor a 36 m².

---

## RULE-DPMS-001

Nombre:
Cálculo de DPMS.

Estado:
VERIFIED únicamente para las partes documentadas a continuación.

Fuente:
AEA 90364-7-770

Edición:
2017

Referencia:
770.8.1 — Tabla 770.8.I.

Regla:
El cálculo debe determinar la demanda de los circuitos utilizando los valores mínimos reglamentarios correspondientes y utilizar valores mayores cuando existan cargas conocidas que así lo requieran.

- IUG sin tomacorrientes derivados: DPMS = 2/3 de la potencia resultante de considerar todos los puntos previstos a razón de 60 VA por punto.
- IUG con tomacorrientes derivados: 2200 VA por circuito.
- TUG: 2200 VA por circuito.
- TUE: 3300 VA por circuito.

Estos valores son mínimos. Cuando los consumos sean conocidos y superen los mínimos aplicables, utilizar los valores mayores.

Partes pendientes — PENDING_INTERPRETATION:
- Cualquier otro subtipo de circuito o cálculo cuya fórmula completa todavía no esté documentada en esta especificación.
- No generalizar otros tipos de circuito ni inventar valores faltantes.
- Las cargas específicas se tratan separadamente en RULE-SPECIFIC-LOAD-DEMAND-001.

Consecuencia de modelado:
La implementación deberá separar:
- demanda reglamentaria mínima;
- demanda conocida/proyectada;
- demanda utilizada finalmente.

El resultado utilizado no deberá ocultar cuál de ellas determinó el valor.

Tests requeridos:
- IUG sin tomacorrientes derivados con diferentes cantidades de puntos.
- IUG con tomacorrientes derivados: 2200 VA por circuito.
- TUG: 2200 VA por circuito.
- TUE: 3300 VA por circuito.
- Carga conocida menor al mínimo: utilizar el mínimo aplicable.
- Carga conocida exactamente igual al mínimo: conservar ese valor.
- Carga conocida superior al mínimo: utilizar la carga conocida.

---

## RULE-SIMULTANEITY-001

Nombre:
Coeficientes de simultaneidad.

Estado:
VERIFIED para el coeficiente correspondiente al grado de electrificación.

Fuente:
AEA 90364-7-770

Edición:
2017

Referencia:
770.8.1 — Tabla 770.8.II.

Regla:

Cantidad mínima de circuitos = 2:
coeficiente = 1.00.

Cantidad mínima de circuitos = 3:
coeficiente = 0.80.

Cantidad mínima de circuitos = 5:
coeficiente = 0.70.

Cantidad mínima de circuitos = 6:
coeficiente = 0.60.

El coeficiente se determina por la cantidad mínima de circuitos correspondiente al grado de electrificación y no simplemente por contar todos los circuitos adicionales que el proyectista haya agregado.

Mantener separadas de esta regla:
- utilización de cargas específicas;
- simultaneidad particular de cargas específicas;
- factores Ke/K utilizados para otras verificaciones.

Esos conceptos no deben reutilizar esta tabla automáticamente.

Tests requeridos:
- Cantidad mínima de 2 circuitos: coeficiente 1.00.
- Cantidad mínima de 3 circuitos: coeficiente 0.80.
- Cantidad mínima de 5 circuitos: coeficiente 0.70.
- Cantidad mínima de 6 circuitos: coeficiente 0.60.
- Proyecto con circuitos adicionales: el coeficiente sigue dependiendo del mínimo reglamentario correspondiente al grado de electrificación.
- Un proyecto de grado elevado que instala más de cinco circuitos debe seguir utilizando el coeficiente 0.70, asociado a su cantidad mínima reglamentaria de cinco circuitos, salvo que otra regla normativa verificada indique lo contrario.

Importante:
Estos coeficientes nunca deberán utilizarse arbitrariamente para mantener un suministro monofásico.

---

## RULE-TOTAL-DEMAND-001

Nombre:
Carga total de la vivienda.

Estado:
VERIFIED

Fuente:
AEA 90364-7-770

Edición:
2017

Referencia:
770.8.3.1.

Regla:
Carga total = DPMS correspondiente al grado de electrificación + DPMS de circuitos dedicados a cargas específicas.

Mantener diferenciados los componentes del resultado para permitir su auditoría.
La DPMS general corresponde al bloque RULE-DPMS-001 y RULE-SIMULTANEITY-001; la DPMS de cargas específicas se trata en RULE-SPECIFIC-LOAD-DEMAND-001, con sus propios coeficientes.

Notas de consistencia:
- La carga total calculada no debe confundirse con la potencia contratada; este documento no define una regla para determinar la potencia contratada.
- Mantener diferenciadas las magnitudes y unidades: los mínimos de demanda en VA, la recomendación de suministro en kVA, el límite profesional provisional en kW y las corrientes por fase en A.
- El alcance profesional, la recomendación de suministro y las corrientes por fase son criterios separados.

---

## RULE-THREE-PHASE-CURRENT-001

Nombre:
Corriente del circuito seccional con alimentación trifásica.

Estado:
VERIFIED

Fuente:
AEA 90364-7-770

Edición:
2017

Referencia:
770.8.3.1, Nota 1.

Regla:
Cuando coexistan circuitos monofásicos y trifásicos, calcular las corrientes correspondientes a cada fase y utilizar para el dimensionamiento la corriente de la fase más cargada.

No implementar una simple división uniforme de la carga total entre tres fases cuando existan cargas monofásicas distribuidas de manera desigual.

Notas:
Esta regla define qué corriente utilizar para el dimensionamiento. Las fórmulas y supuestos pendientes de RULE-CURRENT-001 se mantienen separados.

---

## RULE-PHASE-BALANCE-001

Nombre:
Equilibrio de cargas entre fases.

Estado:
VERIFIED

Fuente:
AEA 90364-7-770

Edición:
2017

Referencia:
770.8.3.3.

Regla:
Se recomienda que el máximo desequilibrio entre las corrientes de las distintas fases no supere el 30%.

Modelarlo como recomendación/advertencia y no como incumplimiento bloqueante salvo que otra regla aplicable establezca una exigencia diferente.

---

# REGLAS PENDIENTES DE DOCUMENTAR

## RULE-SPECIFIC-LOAD-DEMAND-001

Nombre:
DPMS de circuitos dedicados a cargas específicas.

Estado:
PENDING_INTERPRETATION

Fuente:
AEA 90364-7-770

Edición:
2017

Referencia:
770.8.2.

Criterio conceptual:
Las cargas específicas deben mantenerse separadas del cálculo general correspondiente al grado de electrificación.

Pendiente:
Documentar completamente los criterios particulares de utilización y simultaneidad aplicables a estas cargas que aún no estén especificados; mantienen el estado PENDING_INTERPRETATION.

Criterio documentado:
Para los circuitos dedicados a cargas específicas se consideran las potencias correspondientes multiplicadas por los coeficientes de utilización de cada carga y de simultaneidad de cada grupo o conjunto que correspondan según criterio del proyectista.

Estos coeficientes deben:
- ser visibles;
- conservarse en el proyecto;
- aparecer en la explicación del cálculo;
- aparecer en la memoria técnica.

No asumir valores por defecto distintos de 1 salvo que posteriormente exista una regla verificada que lo justifique.

Notas:
Estos coeficientes no son el mismo concepto que el coeficiente de simultaneidad de RULE-SIMULTANEITY-001 ni los factores utilizados para cálculos térmicos de tableros.

---

## RULE-SUPPLY-001

Nombre:
Determinación de suministro monofásico o trifásico.

Estado:
PENDING_SOURCE para requisitos obligatorios aún no documentados. La recomendación AEA queda documentada a continuación con su fuente y referencia.

Fuente:
AEA 90364-7-770

Edición:
2017

Referencia:
770.8.3.2.

Regla:
La empresa distribuidora puede definir el valor de potencia a partir del cual un suministro debe ser trifásico.

AEA recomienda solicitar suministro trifásico cuando:
- el proyectista lo considere conveniente; o
- la carga total calculada supere 7 kVA; o
- la corriente correspondiente a una línea monofásica supere 32 A.

Modelar esta regla como recomendación AEA y no como prohibición absoluta de suministro monofásico.
Los requisitos obligatorios particulares del prestador deben modelarse separadamente, mediante RULE-DISTRIBUTOR-001 y RULE-DISTRIBUTOR-SELECTION-001.

Notas:
- Los 32 A corresponden al criterio de recomendación para una línea monofásica; no son una corriente nominal propia de una protección trifásica.
- No asumir 25 A monofásico como regla: su fuente y contexto siguen pendientes.
- El límite profesional de Categoría III se trata separadamente en RULE-CATEGORY-III-SCOPE-001.

---

## RULE-CURRENT-001

Nombre:
Corriente de proyecto.

Estado:
PENDING_SOURCE

Pendiente:
Documentar fórmulas y supuestos para:
- monofásico;
- trifásico;
- factor de potencia;
- cargas específicas cuando corresponda.

Distinguir fórmulas electrotécnicas de restricciones normativas.

---

## RULE-CONDUCTOR-001

Nombre:
Selección y capacidad admisible de conductores.

Estado:
PENDING_SOURCE

Pendiente:
Documentar:
- secciones mínimas;
- métodos de instalación;
- capacidad de conducción;
- material;
- aislación;
- temperatura;
- cantidad de conductores cargados;
- factores de corrección.

---

## RULE-GROUPING-001

Nombre:
Factor de corrección por agrupamiento.

Estado:
PENDING_SOURCE

Pendiente:
Documentar tablas y condiciones de aplicación cuando varios circuitos compartan una canalización.

La aplicación deberá utilizar la capacidad corregida resultante y no únicamente la capacidad nominal/base del conductor.

---

## RULE-VOLTAGE-DROP-001

Nombre:
Caída de tensión máxima admisible.

Estado:
PENDING_SOURCE

Pendiente:
Documentar:
- límites aplicables;
- circuitos involucrados;
- caída acumulada;
- condiciones particulares.

---

## RULE-PROTECTION-001

Nombre:
Coordinación entre corriente de proyecto, protección y conductor.

Estado:
PENDING_SOURCE

Pendiente:
Documentar relaciones y condiciones necesarias para validar la protección del conductor.

---

## RULE-RCD-001

Nombre:
Protección diferencial.

Estado:
PENDING_SOURCE

Pendiente:
Documentar:
- sensibilidad;
- corriente nominal;
- cantidad requerida;
- circuitos cubiertos;
- excepciones;
- coordinación correspondiente.

---

## RULE-EARTHING-001

Nombre:
Puesta a tierra.

Estado:
PENDING_SOURCE

Pendiente:
Documentar requisitos de:
- electrodo;
- conductor PE;
- conductor principal;
- equipotencialidad;
- resistencia;
- coordinación con protección diferencial;
- verificaciones y mediciones.

---

## RULE-BOARD-001

Nombre:
Dimensionamiento completo del tablero.

Estado:
PENDING_INTERPRETATION

Regla ya conocida:
Existe una reserva mínima documentada en RULE-BOARD-RESERVE-001.

Pendiente:
Definir:
- contabilización de módulos;
- selección del tamaño comercial;
- dispositivos que deben contemplarse;
- reglas adicionales de construcción e instalación.

---

## RULE-LOCATION-KITCHEN-001

Nombre:
Ubicación de elementos eléctricos en cocina.

Estado:
PENDING_SOURCE

Pendiente:
Verificar distancias y alturas aplicables.

No asumir todavía como reglas:
- 40 cm respecto de pileta;
- 10 cm respecto de mesada;
- otras distancias recordadas.

---

## RULE-LOCATION-BATHROOM-001

Nombre:
Ubicación de elementos eléctricos en baños.

Estado:
PENDING_SOURCE

Pendiente:
Documentar zonas, grados de protección, elementos permitidos y distancias aplicables.

---

## RULE-CERTIFICATION-001

Nombre:
Certificación y conformidad de materiales.

Estado:
PENDING_SOURCE

Pendiente:
Determinar para cada familia de productos:
- norma IRAM aplicable;
- certificación exigida;
- requisitos de seguridad;
- marcado obligatorio;
- autoridad o régimen correspondiente.

No implementar una regla genérica que simplemente exija "certificación IRAM" a todos los componentes sin distinguir el requisito aplicable.

---

# REQUISITOS ESPECÍFICOS DE CÓRDOBA

## RULE-CATEGORY-III-SCOPE-001

Nombre:
Límite de alcance profesional Categoría III Córdoba.

Estado:
PENDING_SOURCE

Alcance provisional:
El proyecto está diseñado para instalaciones en baja tensión dentro del alcance profesional de Categoría III y con límite objetivo de 10 kW.

Pendiente:
Registrar dentro del documento la resolución oficial de ERSeP y la referencia exacta correspondiente. Hasta entonces, no convertir el valor de 10 kW en una validación bloqueante.

Notas:
- Esta regla complementa RULE-ERSEP-SCOPE-001 y mantiene pendiente la misma fuente oficial.
- El límite profesional de Categoría III y la determinación monofásico/trifásico son conceptos diferentes.
- Mantener esta regla separada de RULE-SUPPLY-001.

---

## RULE-ERSEP-SCOPE-001

Nombre:
Alcance profesional Categoría III.

Estado:
PENDING_SOURCE

Pendiente:
Registrar la resolución vigente de ERSeP, su edición y el alcance exacto de las instalaciones que puede proyectar, ejecutar y certificar un Instalador Electricista Habilitado Categoría III.

El límite de 10 kW utilizado como alcance del proyecto deberá quedar vinculado a su fuente oficial antes de convertirse en una validación bloqueante.

---

## RULE-DISTRIBUTOR-001

Nombre:
Requisitos particulares de distribuidora.

Estado:
DISTRIBUTOR_DEPENDENT

Pendiente:
Modelar requisitos particulares cuando correspondan, por ejemplo:
- EPEC;
- cooperativas eléctricas;
- otros prestadores de Córdoba.

Una exigencia particular del prestador no deberá presentarse como si fuera una regla general de AEA.

---

## RULE-DISTRIBUTOR-SELECTION-001

Nombre:
Prestador eléctrico del proyecto.

Estado:
DISTRIBUTOR_DEPENDENT

Regla de modelado:
El proyecto podrá registrar su prestador eléctrico.

Ejemplos:
- EPEC;
- cooperativa eléctrica;
- otro;
- no definido.

Las reglas particulares de cada prestador deberán mantenerse separadas de las reglas AEA y ERSeP. Sus requisitos se documentarán en RULE-DISTRIBUTOR-001.

---

# PRINCIPIOS DE IMPLEMENTACIÓN

1. Una regla VERIFIED puede convertirse en código y tests.

2. Una regla PENDING no puede producir un incumplimiento normativo definitivo en la aplicación.

3. Los valores normativos no deberán quedar dispersos como números mágicos.

4. Las reglas deberán ser trazables mediante identificadores estables.

5. La UI podrá explicar qué regla produjo cada validación.

6. Los cálculos matemáticos/electrotécnicos deberán mantenerse separados de las decisiones reglamentarias.

7. Si dos fuentes aplicables producen requisitos diferentes, no elegir silenciosamente una. Registrar el conflicto para revisión.

8. Cuando una norma cambie de edición, conservar la trazabilidad de la edición utilizada por cada proyecto.

9. Codex no deberá buscar por su cuenta un valor faltante y convertirlo automáticamente en una regla VERIFIED.

10. La seguridad tendrá prioridad frente a optimizaciones económicas o intentos de reducir artificialmente la demanda.

---

# FEATURE 003 — Circuitos y distribución de puntos

## RULE-CIRCUITS-001 — implementación y alcance

Se conserva el identificador existente (equivalente al nombre propuesto
RULE-MIN-CIRCUITS-001), su estado VERIFIED y la referencia AEA 90364-7-770:2017,
770.7.4, Tabla 770.7.II. Feature 003 implementa exclusivamente los mínimos y
variantes ya documentados arriba. Los circuitos adicionales no son incumplimiento.
La elección A/B se registra junto al GE; al cambiar de GE se pide una nueva
selección cuando corresponda. No se eliminan circuitos ni asignaciones al cambiarla.
La generación completa únicamente los tipos base faltantes y nunca elige la
posición libre. Esta posición referencia un circuito concreto, que no puede
contarse simultáneamente dentro de las posiciones base.

## RULE-CIRCUIT-CLASSIFICATION-001

Estado: VERIFIED para la clasificación expresamente confirmada en Feature 003.
Fuente: AEA 90364-7-770, edición 2017; especificación de Feature 003 aportada por
el titular del proyecto. Referencia puntual de clasificación pendiente de cotejo.
IUG/TUG: uso general. TUE: uso especial. ACU: uso específico, una carga única.
No se extienden a ACU los límites de bocas de otros tipos.

## RULE-CIRCUIT-POINT-LIMIT-001

Estado: VERIFIED para los valores expresamente confirmados en Feature 003.
Fuente: AEA 90364-7-770, edición 2017; valores confirmados por el titular en
la especificación de Feature 003. Sección/tabla puntual: pendiente de cotejo;
no atribuir estos límites a la Tabla 770.7.II de mínimos por GE.
Máximo: 15 bocas por circuito IUG, TUG o TUE. ACU: no aplica esta regla.
Tests: 15 conforme, 16 excedido para cada tipo; ACU sin máximo de bocas;
entrada negativa inválida. El máximo no es una cantidad mínima de puntos.

## RULE-CIRCUIT-POINT-COMPATIBILITY-001

Estado: VERIFIED para IUG → IUG y TUG → TUG, conforme al alcance explícito de
Feature 003. Se aplica exclusivamente a bocas distribuibles, no a módulos.
Fuente: clasificación AEA 90364-7-770:2017 y RULE-ROOM-POINTS-001
(770.7.5, Tabla 770.7.III).
No se permite cruzar IUG/TUG ni reutilizar puntos TUG en TUE/ACU.
Los módulos se conservan como cantidades del ambiente; no se individualizan como
bocas ni tienen compatibilidad de circuito pendiente. Se elimina el anterior
pendiente, que provenía de tratarlos erróneamente como bocas adicionales.
Los puntos propios de TUE todavía no están modelados.

## RULE-FREE-CIRCUIT-ELIGIBILITY-001

Estado: PENDING_INTERPRETATION para condiciones particulares TUE/ACU.
Fuente: AEA 90364-7-770:2017, 770.7.4, Tabla 770.7.II.
La posición libre de GE Superior no presupone un tipo. El instalador puede
referenciar un circuito IUG/TUG/TUE/ACU. IUG/TUG satisfacen la composición;
para TUE/ACU se muestra revisión normativa pendiente, sin declarar conformidad
integral ni prohibición. Falta confirmar las condiciones específicas aplicables.

## Carga declarada ACU — decisión de dominio

Una carga identificable por destino y una declaración con valor finito >= 0 y
unidad explícita VA/W/kW/HP. Cero es válido; no se inventa prohibición normativa.
Se conserva exactamente el valor/unidad. Sólo VA constituye potencia aparente
declarada; W/kW no se equiparan a VA. Feature 003 no normaliza HP ni calcula DPMS.
Feature 004 incorpora fp explícito y el criterio de conversión HP × 746 solicitado
por el titular; ver CALC-APPARENT-POWER-001. No se supone rendimiento.

## RULE-CONDUCTOR-MINIMUM-001

Estado: PENDING_SOURCE. Regla futura, sin lógica de selección en Feature 003.
Fuente: material de referencia aportado por el titular del proyecto; falta
identificar fuente primaria, edición y sección/tabla exactas antes de verificar.
Valores a cotejar: principal 4 mm²; seccional 2,5 mm²; IUG 1,5 mm²;
TUG 2,5 mm²; uso especial 2,5 mm²; uso específico excepto MBTF 2,5 mm²;
uso específico MBTF 1,5 mm²; PE 2,5 mm².
La sección mínima es un piso reglamentario, no una selección automática.
La futura selección considerará Ib, Iz, método de instalación, factores de
corrección, agrupamiento, temperatura, caída de tensión, sección mínima y
protección. Complementa RULE-CONDUCTOR-001, sin cambiar su estado pendiente.

## Decisiones técnicas de Feature 003

Los resúmenes UtilizationPoints siguen siendo la fuente de cantidades por ambiente.
La individualización sólo abarca bocas IUG/TUG y conserva UUID, ambiente, tipo y ordinal; al reducir cantidades
retira los ordinales finales, al quitar un ambiente elimina sus puntos, y al quitar
un circuito deja sus puntos sin asignar. Recalcular no cambia identidades.
La app continúa en memoria, sin persistencia añadida en esta feature.
Se limita la materialización a 100.000 puntos por recursos de la aplicación:
este valor NO es normativo. Ante exceso se conserva el resumen y se suspende
la revisión de asignaciones hasta que pueda sincronizarse nuevamente.


---

# FEATURE 004 — Cargas y DPMS

## CALC-APPARENT-POWER-001

Estado: criterio de cálculo del proyecto, explícitamente aprobado por el titular
para Feature 004; no se atribuye a una prescripción AEA/ERSeP.
Fuente: especificación de Feature 004. Edición/referencia AEA: no aplica a esta
convención de conversión; no se inventa una cita normativa.

Se conserva DeclaredLoad como dato original. Resultado: ApparentPower en VA.
- VA: S = valor declarado, sin fp.
- W: S = W/fp.
- kW: P = kW × 1000 W/kW; S = P/fp.
- HP: criterio adoptado por el proyecto P = HP × 746 W/HP; S = P/fp.

PowerFactor debe ser finito y cumplir 0 < fp <= 1. No tiene valor por defecto.
No se aplica rendimiento/eficiencia a HP. Esta convención no pretende resolver
un modelo general de motores ni inferir parámetros de placa no ingresados.
W/kW/HP sin fp producen missingPowerFactor, incluso para valor declarado cero.
VA no requiere ni utiliza fp. Valores no finitos en resultados producen error
numérico estructurado, no valores válidos ni sustitución por cero.

## RULE-DPMS-IUG-001

Estado: VERIFIED, desglose de RULE-DPMS-001 ya documentada.
Fuente: AEA 90364-7-770. Edición: 2017.
Referencia: 770.8.1, Tabla 770.8.I.
Alcance implementado: IUG residencial sin tomacorrientes derivados.
Base = bocas IUG asignadas × 60 VA/boca.
DPMS mínima = base × 2/3. No se fija 600 VA por circuito.
Se conserva por separado una demanda conocida opcional y se adopta el mayor
entre dicha demanda y el mínimo. Una cantidad negativa de bocas es inválida.
IUG con tomacorrientes derivados sigue fuera del modelo actual; no se extiende
la fórmula implementada a ese subtipo.

## RULE-DPMS-TUG-001 / RULE-DPMS-TUE-001

Estado: VERIFIED, desgloses de RULE-DPMS-001 ya documentada.
Fuente: AEA 90364-7-770. Edición: 2017.
Referencia: 770.8.1, Tabla 770.8.I.
Mínimo TUG = 2200 VA/circuito. Mínimo TUE = 3300 VA/circuito.
Se adopta el mayor entre mínimo y demanda conocida opcional en VA.
Estos mínimos no son techos para demandas conocidas. No se aplican a ACU.
TUE conserva su mínimo aun cuando sus puntos específicos no estén modelados.

## RULE-SIMULTANEITY-001 — aplicación en Feature 004

Estado y referencia conservados: VERIFIED; AEA 90364-7-770:2017,
770.8.1, Tabla 770.8.II. La fuente, edición y referencia puntual estaban
registradas en este documento antes de Feature 004; no se agregó una cita nueva.
Correspondencia con RULE-CIRCUITS-001: mínimo 1,0; medio 0,8; elevado 0,7;
superior 0,6. Se usa el GE, no la cantidad de circuitos instalados.

Base GE = suma de DPMS adoptadas de todos los IUG/TUG/TUE modelados,
incluidos los adicionales. DPMS GE = base GE × coeficiente del GE.
ACU queda fuera de esta base y de esta multiplicación.

## RULE-TOTAL-DEMAND-001 / RULE-SPECIFIC-LOAD-DEMAND-001 — alcance actual

Se conserva RULE-TOTAL-DEMAND-001 VERIFIED, AEA 90364-7-770:2017,
770.8.3.1, y RULE-SPECIFIC-LOAD-DEMAND-001 PENDING_INTERPRETATION,
misma fuente/edición, 770.8.2.

Decisión explícita del titular para Feature 004: cuando un ACU sea resoluble,
su demanda considerada es su potencia aparente, sin reducciones. Se mantienen
magnitudes separadas en el resultado para el futuro tratamiento de Ku/Ks.
No se crean coeficientes específicos editables ni se infieren valores.
El tratamiento completo de Ku/Ks queda pendiente; esta implementación no lo
convierte en una regla normativa definitiva.

Total resoluble actual = DPMS GE + suma de demandas consideradas de ACU
resolubles. Si hay ACU pendientes se muestra como subtotal incompleto y el total
completo queda pendiente, identificando los circuitos con carga/fp faltante.
Como condición de integridad del proyecto (no una nueva fórmula normativa),
los puntos IUG/TUG sin asignar también impiden informar un total completo:
se devuelve unassignedPoints reutilizando CircuitEngine.validate. Se conserva el
subtotal de lo resoluble, sin inferir asignaciones ni sumar bocas arbitrariamente.
Asignaciones incompatibles o a circuitos inexistentes producen incompatibleAssignments.
Los módulos de cocina no generan puntos distribuibles ni demanda independiente y no bloquean el total.
La traza conserva entradas, base, mínimo, demanda conocida, demanda adoptada,
conversión de carga, coeficiente GE, aportes específicos e IDs de regla.

## RULE-CIRCUIT-POINT-LIMIT-SHARED-CONDUIT-001

Estado: PENDING_SOURCE / PENDING_INTERPRETATION.
Fuente/edición/sección puntual: pendientes de cotejo. Origen: requisito futuro
identificado por el titular en Feature 004.
Cuando varios circuitos compartan una canalización, el máximo aplicable de bocas
puede cambiar. El dominio todavía no modela canalizaciones, por lo que no se
infiere ese contexto ni se reduce el máximo. RULE-CIRCUIT-POINT-LIMIT-001
permanece sin cambios: 15 para IUG/TUG/TUE, sin aplicar ese límite a ACU.
Resolver con la futura feature de canalizaciones/agrupamiento, con fuente y
condiciones de aplicación confirmadas.

## Límites de implementación

La revisión de mínimos, asignaciones y reglas pendientes de Feature 003 sigue
independiente del resultado aritmético. Calcular DPMS no certifica conformidad.
Los módulos de cocina son equipamiento del ambiente: no se suman como bocas
ni se convierten artificialmente en cargas ACU. Sin sincronización de puntos,
la UI no presenta resultados calculados sobre el estado anterior.
No se calcula Ib ni suministro, conductores, Iz, protecciones, caída de tensión,
Ku/Ks editables, canalizaciones o agrupamiento. No se implementa Feature 005.
