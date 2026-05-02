# Redes sociales en el aula: una herramienta de análisis visual

**Trabajo de Fin de Grado (TFG)**
**Autor:** Diego Rodríguez Elena
**Institución:** [Nombre de la universidad]
**Titulación:** [Nombre del grado]
**Curso académico:** [Año]
**Tutor/a:** [Nombre del tutor/a]

---

## Resumen

[200–300 palabras que resuman la pregunta de investigación, la metodología, los principales hallazgos y las conclusiones. Redactar al final.]

**Palabras clave:** análisis de redes sociales, dinámica de aula, sociometría, redes de amistad, redes de conflicto, R Shiny, igraph, visNetwork.

---

## 1. Introducción

[Motivar el trabajo: ¿por qué es importante comprender las relaciones sociales dentro del aula? Indicar brevemente el vacío en las herramientas o investigaciones existentes que este proyecto aborda.]

### 1.1 Preguntas de investigación

1. ¿Cuál es la estructura de las redes de amistad y conflicto dentro de cada grupo-clase?
2. ¿Quiénes son los alumnos más centrales (populares o aislados socialmente)?
3. ¿Existe un efecto del género sobre la centralidad en la red o el bienestar subjetivo?
4. ¿Cómo varían las métricas de red (densidad, reciprocidad, homofilia) entre grupos?

### 1.2 Objetivos

- Construir una herramienta interactiva que permita a investigadores y docentes explorar las redes sociales del aula a partir de datos de encuesta reales.
- Calcular y visualizar índices sociométricos (grado de entrada, intermediación, densidad, reciprocidad) por grupo.
- Identificar patrones estructurales (cliques, alumnos aislados, homofilia de género, estado sociométrico) en las redes de amistad y conflicto.

---

## 2. Marco teórico

### 2.1 Análisis de redes sociales (ARS)

[Breve introducción al ARS: nodos, aristas, grafos dirigidos frente a no dirigidos, métricas clave.]

### 2.2 Sociometría en el ámbito educativo

[Referenciar la sociometría clásica (Moreno, 1934) y sus aplicaciones en la investigación sobre el aula. Tratar los métodos de nominación de amistades y la medición del conflicto.]

### 2.3 Clasificación sociométrica

El estado sociométrico se calcula siguiendo el método de Coie y Dodge (1983) a partir de dos índices derivados de las nominaciones:

- **Preferencia social (PS)** = $z(\text{indegree\_friend}) - z(\text{indegree\_enemy})$
- **Impacto social (IS)** = $z(\text{indegree\_friend}) + z(\text{indegree\_enemy})$

| Estado | Criterio |
|---|---|
| **Popular** | PS > 1 y $z(\text{enemy}) < -1$ |
| **Rechazado** | PS < −1 y $z(\text{enemy}) > 1$ |
| **Controvertido** | IS > 1 y ambos $z > 0$ |
| **Ignorado** | IS < −1 |
| **Promedio** | Resto |

### 2.4 Trabajos previos relevantes

[Citar 5–8 artículos sobre redes sociales en el aula, rechazo entre iguales y capital social en educación.]

---

## 3. Conjunto de datos

| Campo | Descripción |
|---|---|
| `Usuario_id` | Identificador anónimo del alumno |
| `friend` | Lista de nominaciones de amistad (separadas por barras verticales) |
| `enemy` | Lista de nominaciones de conflicto (separadas por barras verticales) |
| `Grupo` | Etiqueta del grupo / clase |
| `Sexo` | Género (1 = mujer, 2 = hombre) |
| `happy` / `happyn` | Puntuación de bienestar subjetivo (autoinforme) |
| `indegree_friend` | Grado de entrada de amistad precalculado (popularidad) |
| `Año` | Curso / año escolar |
| `atencion` | Puntuación de atención |

**Fuente:** [Describir cómo se recogieron los datos: instrumento de encuesta, niveles educativos, N total, período de recogida.]

**Consideraciones éticas:** [Indicar la aprobación del comité ético/IRB, el procedimiento de anonimización y el proceso de consentimiento informado.]

---

## 4. Metodología

### 4.1 Arquitectura de la herramienta

El análisis se presenta como una aplicación web R Shiny (`app/app.R`) con el siguiente flujo de datos:

```
Carga del archivo .dta
    └─► haven::read_dta()
         └─► filtro por grupo (Grupo)
              └─► crear_aristas()   — parsea columnas friend/enemy
                   └─► igraph::layout_with_fr()   — layout Fruchterman-Reingold
                        └─► visNetwork            — grafo interactivo
```

### 4.2 Construcción de aristas

Las columnas `friend` y `enemy` contienen IDs delimitados por barras verticales o comas. La función `crear_aristas()` normaliza los delimitadores, separa las filas y produce una lista de aristas dirigidas con tipo (`amistad` / `conflicto`) y color (`#27ae60` / `#e74c3c`). Las autonominaciones se descartan.

### 4.3 Disposición de la red (*layout*)

Las posiciones de los nodos se precalculan mediante el algoritmo de fuerza dirigida Fruchterman-Reingold (igraph, 500 iteraciones, semilla = 42) y se pasan como coordenadas fijas a visNetwork. Esto proporciona un *layout* estable y reproducible independientemente del orden de interacción.

### 4.4 Tamaño de los nodos

El tamaño del nodo codifica la popularidad social:

$$\text{tamaño}_i = \text{base} + \sqrt{\text{indegree\_friend}_i} \times 4$$

La transformación de raíz cuadrada comprime el rango para que las diferencias de popularidad sean visibles sin que los nodos dominantes saturen el lienzo.

### 4.5 Métricas de red calculadas

#### A nivel de red (por grupo)

| Métrica | Definición |
|---|---|
| Densidad | $\|E\| / (N \times (N-1))$ — proporción de aristas dirigidas posibles presentes |
| Reciprocidad | Fracción de nominaciones de amistad mutuas (bidireccionales) |
| Transitividad | Coeficiente de agrupamiento global (*clustering*) |
| Longitud media de camino | Distancia geodésica media entre todos los pares alcanzables |
| Diámetro | Longitud del camino más largo entre cualquier par de nodos |
| Componentes | Número de componentes débilmente conectados |
| Aislados | Alumnos con grado de entrada = 0 (sin nominaciones de amistad recibidas) |

#### A nivel de nodo (por alumno)

| Métrica | Definición |
|---|---|
| Grado de entrada (*in-degree*) | Nominaciones de amistad / conflicto recibidas |
| Grado de salida (*out-degree*) | Nominaciones de amistad / conflicto emitidas |
| Intermediación (*betweenness*) | Proporción de caminos más cortos que pasan por el nodo (rol de broker) |
| Cercanía (*closeness*) | Inverso de la distancia media al resto de nodos |
| Centralidad de vector propio | Importancia ponderada por la calidad de las conexiones |

### 4.6 Homofilia de género

La homofilia se mide como el porcentaje de aristas de amistad que conectan alumnos del mismo sexo. Un valor superior al 50 % indica tendencia a la homofilia; inferior al 50 %, a la heterofilia.

---

## 5. Resultados

### 5.1 Estadísticas descriptivas

[Insertar tabla generada por `analysis/exploratory.R` — tamaños de grupo, media de felicidad, media de atención, distribución por sexo.]

| Grupo | N | % Mujeres | Media felicidad | SD felicidad | Media atención | Densidad amistad | Reciprocidad |
|---|---|---|---|---|---|---|---|
| … | … | … | … | … | … | … | … |

### 5.2 Métricas de red por grupo

[Insertar tabla `outputs/metricas_grupo.csv`.]

| Grupo | N | Amistades | Conflictos | Densidad | Reciprocidad | Transitividad | Long. media camino | Aislados |
|---|---|---|---|---|---|---|---|---|
| … | … | … | … | … | … | … | … | … |

### 5.3 Visualizaciones de red

> **Cómo capturar:** En la aplicación Shiny, seleccionar un grupo → clic derecho sobre el lienzo de la red → "Guardar imagen como…" → guardar en `outputs/figures/`. Insertar aquí.

#### Grupo [X]

![Red — Grupo X](../outputs/figures/group_X.png)

*Descripción: Red de amistad (verde) y conflicto (rojo) dirigida para el Grupo X (N = ?). El tamaño del nodo es proporcional a √(grado de entrada de amistad). Rosa = mujer, azul = hombre.*

[Describir el patrón estructural: ¿Hay cliques visibles? ¿Alumnos aislados? ¿Agrupamientos por género? ¿Hubs de conflicto?]

#### Grupo [Y]

![Red — Grupo Y](../outputs/figures/group_Y.png)

*Descripción: …*

[Repetir para cada grupo.]

### 5.4 Análisis de centralidad y estado sociométrico

[Listar los 5 alumnos con mayor grado de entrada de amistad, los 5 con mayor intermediación e identificar los alumnos rechazados e ignorados por grupo. Insertar tabla `outputs/centralidad_alumnos.csv`.]

| Grupo | Más popular (in-degree) | Broker principal (betweenness) | Rechazados (n) | Aislados (n) |
|---|---|---|---|---|
| … | … | … | … | … |

**Distribución del estado sociométrico:**

![Estado sociométrico](../outputs/figures/06_estado_sociometrico.png)

*Descripción: Clasificación de todos los alumnos según el método de Coie y Dodge (1983).*

### 5.5 Felicidad y posición en la red

[Reportar las correlaciones obtenidas y el resultado del ANOVA. Insertar gráfico.]

| Relación | r de Pearson | p-valor |
|---|---|---|
| In-degree amistad ~ felicidad | … | … |
| In-degree conflicto ~ felicidad | … | … |
| Betweenness ~ felicidad | … | … |

![Popularidad y felicidad](../outputs/figures/04_popularidad_felicidad.png)

*Descripción: Diagrama de dispersión entre popularidad (in-degree de amistad) y bienestar subjetivo (happyn). Línea de regresión con intervalo de confianza al 95 %.*

![Felicidad por estado sociométrico](../outputs/figures/07_felicidad_estado.png)

*Descripción: Diagrama de caja de la felicidad según el estado sociométrico.*

### 5.6 Homofilia de género

[Reportar el porcentaje de amistades del mismo sexo por grupo. Insertar gráfico y tabla `outputs/homofilia_genero.csv`.]

![Homofilia de género](../outputs/figures/08_homofilia_genero.png)

*Descripción: Porcentaje de amistades entre alumnos del mismo sexo por grupo (línea de referencia = 50 %).*

---

## 6. Discusión

[Interpretar los hallazgos a la luz del marco teórico. Dar respuesta a cada pregunta de investigación. Señalar las limitaciones: nominaciones autoinformadas, diseño transversal, muestra de un único centro educativo.]

---

## 7. Conclusiones

[3–5 puntos que resuman los principales hallazgos e implicaciones prácticas para docentes y orientadores.]

---

## 8. Trabajo futuro

- Recogida de datos longitudinal para seguir la evolución de la red a lo largo del curso escolar.
- Detección automática de comunidades mediante el algoritmo de Louvain.
- Integración de datos de rendimiento académico y absentismo.
- Panel de alerta temprana para docentes que identifique alumnos aislados o en situación de alto conflicto.

---

## Referencias

[Formato APA 7.ª edición.]

- Coie, J. D., & Dodge, K. A. (1983). Continuities and changes in children's social status: A five-year longitudinal study. *Merrill-Palmer Quarterly, 29*(3), 261–282.
- Moreno, J. L. (1934). *Who shall survive? Foundations of sociometry, group psychotherapy and sociodrama.* Nervous and Mental Disease Publishing.
- [Añadir 8–12 referencias revisadas por pares sobre ARS en el aula, rechazo entre iguales y psicología educativa.]

---

## Apéndice A — Versiones de los paquetes

```r
sessionInfo()
```

[Pegar la salida aquí antes de la entrega.]

## Apéndice B — Tablas de métricas completas

[Tablas completas por grupo y por alumno exportadas desde `analysis/exploratory.R`.]

- `outputs/metricas_grupo.csv` — métricas a nivel de red por grupo
- `outputs/centralidad_alumnos.csv` — centralidad y estado sociométrico por alumno
- `outputs/homofilia_genero.csv` — homofilia de género por grupo
