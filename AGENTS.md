# Instalador Electricista CBA

## Proyecto
App iOS en Swift y SwiftUI para asistir a instaladores electricistas habilitados de Córdoba en el diseño y cálculo de instalaciones. Es un proyecto personal, independiente de los repositorios y herramientas de Naranja X.

## Desarrollo
- Entorno: Xcode 27.
- Minimum deployment target de iOS: 26.0.
- No usar APIs exclusivas de iOS 27 salvo decisión explícita.
- Trabajar únicamente dentro de este repositorio.
- Mantener los modelos y cálculos separados de las vistas SwiftUI.
- Empezar con una estructura simple; agregar módulos o dependencias solo cuando aporten una necesidad concreta.
- Para cambios en fórmulas o criterios de selección, agregar pruebas con casos normales, límites y entradas inválidas.

## Cálculos eléctricos
- No inventar requisitos de AEA, ERSeP ni de la distribuidora. Antes de implementar una regla normativa, identificar la fuente y edición aplicable; si falta, dejarla como decisión pendiente.
- Mostrar unidades, supuestos y pasos relevantes de cada resultado para que el instalador pueda revisarlo.
- No ajustar coeficientes de utilización ni demandas solo para obtener un suministro monofásico. Aplicar únicamente criterios justificables y mostrar cuándo un proyecto supera un límite.
- Mantener configurables y documentados los valores que dependan de la normativa o del prestador.

## Verificación y Git
- Compilar los cambios de la app cuando sea posible y ejecutar las pruebas relacionadas con los cálculos modificados.
- Antes de confirmar cambios, revisar que no se incluyan contraseñas, tokens, certificados ni archivos generados por Xcode.
- Resumir qué cambió, cómo se verificó y qué reglas normativas siguen pendientes de confirmar.

## Legibilidad y documentación del código

- Agregar `// MARK:` y comentarios/documentación breves en español en las partes importantes del dominio, reglas regulatorias y cálculos.
- Explicar principalmente el propósito o el motivo de una lógica cuando no sea evidente al leer el código.
- En cálculos, indicar brevemente qué magnitud se obtiene o qué criterio se aplica.
- No comentar código trivial ni repetir en palabras lo que el código ya expresa claramente.
- Priorizar comentarios cortos que permitan entender rápidamente el flujo al volver al código tiempo después.
