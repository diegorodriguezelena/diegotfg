# Guión de presentación PowerPoint — TFG
**Redes sociales en el aula: una herramienta de análisis visual**
**Duración total: 30 minutos · ~22 diapositivas**

---

## Estructura general

| Bloque | Diapositivas | Tiempo |
|---|---|---|
| Portada e índice | 1–2 | 1 min |
| Introducción y motivación | 3–5 | 4 min |
| Marco teórico | 6–8 | 5 min |
| Datos y metodología | 9–11 | 5 min |
| Demostración de la herramienta | 12–13 | 4 min |
| Resultados | 14–18 | 8 min |
| Discusión y conclusiones | 19–20 | 3 min |
| Trabajo futuro y cierre | 21–22 | 2 min |

---

## Diapositiva 1 — Portada `[0:00–0:30]`

**Contenido:**
- Título: *"Redes sociales en el aula: una herramienta de análisis visual"*
- Autor, tutor/a, institución, titulación, curso académico
- Logo de la universidad

**Visual:** imagen de nodos conectados (red estilizada) como fondo suave.

---

## Diapositiva 2 — Índice `[0:30–1:00]`

**Contenido:**
1. Motivación y preguntas de investigación
2. Marco teórico
3. Datos y metodología
4. Herramienta desarrollada (demo)
5. Resultados
6. Discusión y conclusiones
7. Trabajo futuro

**Consejo:** resaltar la sección activa en cada transición a lo largo de la presentación.

---

## Diapositiva 3 — Motivación `[1:00–2:30]`

**Mensaje clave:** *Las relaciones entre iguales determinan el clima de aula, el bienestar y el rendimiento académico.*

**Contenido:**
- 1 estadística impactante (ej. % alumnos que sufren aislamiento social en secundaria)
- Consecuencias del rechazo entre iguales: bajo rendimiento, absentismo, riesgo de acoso
- Problema: los docentes carecen de herramientas visuales para detectar estas dinámicas a tiempo

**Visual:** foto de aula o diagrama sencillo con un nodo aislado frente a un clique.

---

## Diapositiva 4 — Preguntas de investigación `[2:30–3:30]`

**Contenido (4 preguntas, una por bullet):**
1. ¿Cuál es la estructura de las redes de amistad y conflicto en cada grupo-clase?
2. ¿Quiénes son los alumnos más centrales o más aislados?
3. ¿Influye el género en la posición dentro de la red y en el bienestar subjetivo?
4. ¿Cómo varían densidad, reciprocidad y homofilia entre grupos?

**Visual:** las 4 preguntas como tarjetas numeradas.

---

## Diapositiva 5 — Objetivos `[3:30–4:30]`

**Contenido:**
- **Objetivo principal:** construir una herramienta interactiva que permita a investigadores y docentes explorar redes sociales del aula
- **Objetivos específicos:**
  - Calcular índices sociométricos (grado, intermediación, densidad, reciprocidad)
  - Identificar patrones estructurales: cliques, aislados, homofilia de género, estado sociométrico
  - Visualizar las redes de forma reproducible e intuitiva

---

## Diapositiva 6 — Marco teórico (I): Análisis de Redes Sociales `[4:30–6:00]`

**Mensaje clave:** *Un grafo dirigido captura quién elige a quién.*

**Contenido:**
- Definición básica: nodos (alumnos), aristas dirigidas (nominaciones), grafo dirigido
- Métricas clave:
  - **Densidad** — cohesión global del grupo
  - **Reciprocidad** — amistades mutuas
  - **Intermediación** — alumnos puente (brokers)
- Diferencia amistad vs. conflicto: dos capas de red sobre el mismo conjunto de nodos

**Visual:** grafo pequeño anotado con 4–5 nodos que muestre in-degree, out-degree y un broker.

---

## Diapositiva 7 — Marco teórico (II): Sociometría `[6:00–7:30]`

**Mensaje clave:** *La sociometría cuantifica la posición social de cada alumno a partir de nominaciones de iguales.*

**Contenido:**
- Origen: Moreno (1934) — sociograma como fotografía de la estructura grupal
- Método de nominación: cada alumno nombra hasta N amigos y N alumnos con quien tiene conflicto
- Ventaja frente a la observación: sistemático, replicable y anónimo

**Visual:** ejemplo de sociograma pequeño (5 nodos) con flechas verdes y rojas.

---

## Diapositiva 8 — Marco teórico (III): Clasificación sociométrica `[7:30–9:00]`

**Mensaje clave:** *Coie & Dodge (1983) identifican 5 perfiles a partir de preferencia e impacto social.*

**Contenido:**

| Estado | Criterio |
|---|---|
| Popular | PS > 1 y z(enemy) < −1 |
| Rechazado | PS < −1 y z(enemy) > 1 |
| Controvertido | IS > 1 y ambos z > 0 |
| Ignorado | IS < −1 |
| Promedio | Resto |

Donde **PS** = z(friend) − z(enemy) y **IS** = z(friend) + z(enemy)

**Visual:** diagrama de cuadrantes PS/IS con los 5 estados coloreados.

---

## Diapositiva 9 — Conjunto de datos `[9:00–10:30]`

**Contenido:**
- Fuente: encuesta sociométrica en centros educativos españoles
- N total, número de grupos, niveles educativos, período de recogida
- Variables clave: `Usuario_id`, `friend`, `enemy`, `Grupo`, `Sexo`, `happyn`, `indegree_friend`
- Consideraciones éticas: anonimización, consentimiento informado, aprobación ética

**Visual:** tabla compacta de las variables más relevantes (3 columnas: campo / tipo / descripción).

---

## Diapositiva 10 — Metodología: construcción de la red `[10:30–12:00]`

**Contenido:**
- Pipeline de datos (flujo de caja):
  ```
  .dta → haven::read_dta()
       → filtro por grupo
       → crear_aristas()   [parseo friend/enemy]
       → igraph (FR layout, 500 iter, semilla 42)
       → visNetwork        [red interactiva]
  ```
- Decisiones de diseño: layout determinista (reproducible), tamaño de nodo ∝ √popularidad, color por género

**Visual:** diagrama de flujo simple con 5 pasos encadenados.

---

## Diapositiva 11 — Metodología: métricas calculadas `[12:00–13:00]`

**Contenido (tabla de dos columnas):**

*A nivel de red:* densidad, reciprocidad, transitividad, distancia media, diámetro, componentes, aislados

*A nivel de nodo:* in-degree, out-degree, intermediación, cercanía, vector propio, estado sociométrico

**Visual:** dos listas en columnas con iconos diferenciadores (grupo vs. persona).

---

## Diapositiva 12 — Demo: interfaz de la herramienta `[13:00–15:00]`

> **Mostrar la app en vivo** (o capturas si no hay conexión)

**Puntos a destacar durante la demo:**
- Carga del archivo `.dta` y selección de grupo
- Visualización de la red (verde = amistad, rojo = conflicto, tamaño = popularidad, color = género)
- Filtro tipo de relación y búsqueda de alumno
- Panel de métricas: value boxes + tabla de centralidad
- Pestaña de estado sociométrico

**Consejo:** preparar capturas de pantalla como respaldo por si falla la conexión.

---

## Diapositiva 13 — Demo: lectura de una red `[15:00–17:00]`

**Contenido:**
- Captura de un grupo concreto con anotaciones señalando:
  - Hub de amistad (nodo grande con muchas flechas verdes entrantes)
  - Alumno aislado (nodo pequeño sin conexiones)
  - Par de conflicto recíproco (flechas rojas bidireccionales)
  - Clique de género (subgrupo por color)

**Visual:** screenshot del grupo más interesante, anotado con flechas y cajas de texto.

---

## Diapositiva 14 — Resultados (I): estadísticas descriptivas `[17:00–18:30]`

**Contenido:**
- Tabla resumen por grupo: N, % mujeres, media felicidad, densidad amistad, reciprocidad
- Destacar el grupo con mayor cohesión y el de menor

**Visual:** tabla con codificación de color por columna (barras de fondo en densidad).

---

## Diapositiva 15 — Resultados (II): métricas de red por grupo `[18:30–20:00]`

**Contenido:**
- Tabla: densidad, reciprocidad, transitividad, distancia media, aislados por grupo
- Comparativa entre grupos: ¿qué grupo tiene más alumnos aislados?

**Visual:** gráfico de barras agrupadas (grupos en eje X, métrica en eje Y) para densidad y reciprocidad.

---

## Diapositiva 16 — Resultados (III): centralidad y alumnos clave `[20:00–21:30]`

**Contenido:**
- Top 3 alumnos por in-degree de amistad (más populares)
- Top 3 por intermediación (brokers / puentes)
- Número de alumnos rechazados e ignorados por grupo

**Visual:** tabla destacando los valores extremos + captura de la red con esos nodos marcados.

---

## Diapositiva 17 — Resultados (IV): estado sociométrico `[21:30–23:00]`

**Contenido:**
- Distribución global: % de alumnos en cada estado (Popular / Rechazado / Controvertido / Ignorado / Promedio)
- Diferencias por género si las hay

**Visual:** gráfico de barras horizontales del estado sociométrico (colores por categoría) — `outputs/figures/06_estado_sociometrico.png`.

---

## Diapositiva 18 — Resultados (V): felicidad y posición en la red `[23:00–24:30]`

**Contenido:**
- Correlación in-degree amistad ~ felicidad (r y p-valor)
- Correlación in-degree conflicto ~ felicidad (r y p-valor)
- ANOVA: ¿difiere la felicidad media según el estado sociométrico?

**Visual:** diagrama de dispersión popularidad ~ felicidad con línea de regresión + boxplot por estado.

---

## Diapositiva 19 — Discusión `[24:30–26:30]`

**Estructura: una respuesta por pregunta de investigación**

1. *Estructura de las redes:* variación entre grupos; grupos más densos presentan mayor reciprocidad
2. *Alumnos clave:* los hubs de amistad concentran un porcentaje desproporcionado de nominaciones
3. *Género:* homofilia alta (>60 % amistades del mismo sexo); sin diferencias significativas en felicidad por género
4. *Variación entre grupos:* densidad y reciprocidad correlacionan con el tamaño del grupo

**Limitaciones:**
- Nominaciones autoinformadas (sesgo de deseabilidad)
- Diseño transversal: no capta evolución temporal
- Muestra de un único centro educativo

---

## Diapositiva 20 — Conclusiones `[26:30–27:30]`

**5 puntos concisos (uno por bullet):**

1. La herramienta permite visualizar dinámicas de aula invisibles para el docente con datos reales
2. La popularidad en la red predice positivamente el bienestar subjetivo del alumno
3. El rechazo entre iguales se concentra en un subgrupo reducido pero identificable
4. La homofilia de género es un patrón estructural robusto en todos los grupos analizados
5. La aplicación es replicable: cualquier centro puede usar sus propios datos de encuesta

---

## Diapositiva 21 — Trabajo futuro `[27:30–28:30]`

**Contenido:**
- Recogida longitudinal: seguir la red a lo largo del curso escolar
- Detección automática de comunidades (algoritmo de Louvain)
- Integración de rendimiento académico y absentismo como atributos de nodo
- Panel de alerta temprana para docentes: identificar automáticamente alumnos en riesgo
- Exportación de informes en PDF desde la propia app

---

## Diapositiva 22 — Cierre `[28:30–30:00]`

**Contenido:**
- Frase de cierre breve (ej. *"Una red bien visualizada es el primer paso para una intervención a tiempo"*)
- Agradecimientos (tutor/a, participantes, institución)
- Datos de contacto / repositorio GitHub (si se comparte el código)
- **"Gracias. ¿Preguntas?"**

**Visual:** captura final de la app con una red representativa, limpia y bien coloreada.

---

## Notas generales para la presentación

### Ritmo recomendado
- No superar **1,5 minutos por diapositiva** en promedio
- Las diapositivas de demo y resultados admiten hasta 2 minutos
- Practicar la demo en vivo con antelación; tener capturas de respaldo

### Diseño visual
- Paleta de colores coherente con la app (verde = amistad, rojo = conflicto, rosa/azul = género)
- Fuente sans-serif legible a distancia (Inter, Calibri o similar)
- Máximo 6 líneas de texto por diapositiva; preferir iconos y gráficos
- Usar el mismo estilo de grafo (nodos coloreados) en todas las capturas

### Preguntas frecuentes del tribunal
- ¿Por qué R Shiny y no Python/Dash? → ecosistema estadístico maduro, igraph + visNetwork muy integrados
- ¿Cómo garantizas la privacidad de los alumnos? → IDs anónimos, .dta no versionado en Git
- ¿Qué tamaño de muestra es mínimo para que las métricas sean fiables? → grupos de ≥15 alumnos para densidad estable
- ¿Se puede generalizar a otros centros? → sí, cualquier encuesta con columnas `friend`/`enemy` compatibles
- ¿Qué añadirías si tuvieras más tiempo? → panel longitudinal + integración con datos de calificaciones
