# Instalador Electricista CBA

## Proyecto
App iOS en Swift y SwiftUI para asistir a instaladores electricistas habilitados de Córdoba en el diseño y cálculo de instalaciones. Es un proyecto personal, independiente de los repositorios y herramientas de Naranja X.

## Desarrollo
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
