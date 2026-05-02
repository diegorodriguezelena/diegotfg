# Red social del aula

An interactive R Shiny application that visualises **friendship and conflict social networks** inside classroom groups, built as a Final Degree Project (TFG).

---

## Prerequisites

- **R ≥ 4.2** — [download here](https://cran.r-project.org/)
- **RStudio ≥ 2023** — [download here](https://posit.co/download/rstudio-desktop/)

---

## Quick start

### 1 — Open the project in RStudio

Double-click **`diegotfg.Rproj`** in the project folder.  
RStudio opens with the correct working directory already set.

### 2 — Install dependencies (once)

Open the **Console** panel in RStudio and run:

```r
install.packages(c(
  "shiny", "bslib", "shinycssloaders", "DT",
  "haven", "dplyr", "stringr", "tidyr", "ggplot2",
  "visNetwork", "tibble", "igraph"
))
```

### 3 — Run the app

Open **`app/app.R`** in RStudio and click the **Run App** button (top-right of the editor), or run from the Console:

```r
shiny::runApp("app")
```

### 4 — Load the dataset

In the sidebar of the running app:

1. Click **"Sube el archivo .dta"**
2. Navigate to `data/raw/ES_TFG_DAN.dta` and select it
3. Use the **"Filtrar por grupo"** dropdown to select a classroom group

---

## Using the app

| Control | Effect |
|---|---|
| **Filtrar por grupo** | Show only one classroom group (recommended — full dataset may exceed 250 nodes) |
| **Mostrar relaciones** | Toggle between All / Friendships only / Conflicts only |
| **Tamaño base del nodo** | Global size floor for all nodes |
| **Mostrar etiquetas** | Display student IDs on nodes |
| **Mostrar alumnos sin conexión** | Include/exclude isolated students |
| **Buscar alumno** | Highlight a specific student by ID |

**Reading the network:**

- **Node size** — proportional to √(friendship in-degree); larger = more popular
- **Node colour** — pink = female, blue = male, grey = unknown
- **Green edge** — friendship nomination
- **Red edge** — conflict nomination
- **Click a node** — highlights its direct neighbours

---

## Project structure

```
diegotfg/
├── app/
│   ├── app.R          ← Shiny application entry point
│   └── helpers.R      ← crear_aristas() — edge parsing function
├── analysis/
│   ├── setup.R        ← first-run package install + data inspection
│   └── exploratory.R  ← descriptive stats and per-group network metrics
├── data/
│   └── raw/
│       └── ES_TFG_DAN.dta   ← survey dataset (Stata format, not committed)
├── outputs/
│   └── figures/       ← save network screenshots here for the deliverable
├── docs/
│   └── deliverable.md ← scientific TFG document — fill in results here
├── diegotfg.Rproj     ← open this to start an RStudio session
└── README.md
```

---

## Running the analysis scripts

The exploratory analysis scripts load the dataset directly from `data/raw/`:

```r
# From RStudio Console (project root as working dir)
source("analysis/setup.R")       # dataset overview
source("analysis/exploratory.R") # stats + per-group density/reciprocity tables
```

---

## Scientific deliverable

Open **`docs/deliverable.md`** to find the structured TFG document.  
Fill in each `[TODO]` section with:

- Tables produced by `analysis/exploratory.R`
- Network screenshots saved to `outputs/figures/` (right-click → "Save image as…" inside the app)

---

## Dataset

| Field | Description |
|---|---|
| `Usuario_id` | Anonymous student ID |
| `friend` | Pipe-separated friendship nominations |
| `enemy` | Pipe-separated conflict nominations |
| `Grupo` | Classroom group |
| `Sexo` | Gender (1 = female, 2 = male) |
| `happy` / `happyn` | Self-reported happiness |
| `indegree_friend` | Pre-computed friendship in-degree (popularity) |
| `Año` | School year |
| `atencion` | Attention score |

The raw `.dta` file is excluded from version control (see `.gitignore`). Distribute it separately.
