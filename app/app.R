options(shiny.maxRequestSize = 100 * 1024^2)

library(shiny)
library(bslib)
library(shinycssloaders)
library(DT)
library(ggplot2)
library(haven)
library(dplyr)
library(stringr)
library(tidyr)
library(visNetwork)
library(tibble)
library(igraph)

source("helpers.R")

# ── Palettes shared between UI and server ──────────────────────────────────────
COLORES_ESTADO <- c(
  "Popular"       = "#27ae60",
  "Rechazado"     = "#e74c3c",
  "Controvertido" = "#f39c12",
  "Ignorado"      = "#95a5a6",
  "Promedio"      = "#4361ee"
)
BG_ESTADO <- c(
  "Popular"       = "#d4edda",
  "Rechazado"     = "#f8d7da",
  "Controvertido" = "#fff3cd",
  "Ignorado"      = "#e2e3e5",
  "Promedio"      = "#d6e0fb"
)

z_safe <- function(x) {
  s <- sd(x, na.rm = TRUE)
  if (is.na(s) || s == 0) return(rep(0, length(x)))
  (x - mean(x, na.rm = TRUE)) / s
}

# ── Theme ──────────────────────────────────────────────────────────────────────
app_theme <- bs_theme(
  version      = 5,
  primary      = "#4361ee",
  success      = "#27ae60",
  danger       = "#e74c3c",
  warning      = "#f39c12",
  base_font    = font_google("Inter"),
  heading_font = font_google("Inter"),
  "sidebar-bg"           = "#ffffff",
  "sidebar-border-color" = "#e9ecef",
  "card-border-color"    = "#e9ecef",
  "card-cap-bg"          = "#f8f9fa"
)

# ── UI ─────────────────────────────────────────────────────────────────────────
ui <- page_sidebar(
  title = tagList(
    tags$span("Red social del aula", style = "font-weight:700;"),
    tags$span("· TFG", style = "opacity:.55; margin-left:6px; font-size:.85rem;")
  ),
  theme = app_theme,
  lang  = "es",

  tags$head(
    tags$link(
      rel  = "stylesheet",
      href = "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"
    ),
    tags$style(HTML("
      body { background: #f4f6fb !important; }

      .bslib-sidebar-layout > .sidebar { box-shadow: 2px 0 8px rgba(0,0,0,.06); }
      .sidebar .accordion-button {
        font-weight:600; font-size:.82rem; letter-spacing:.03em;
        text-transform:uppercase; color:#4361ee; background:transparent;
      }
      .sidebar .accordion-button:not(.collapsed) { box-shadow:none; }
      .sidebar .accordion-body { padding-top:6px; }

      .card-header { font-weight:600; font-size:.85rem; letter-spacing:.02em; }
      .card { box-shadow:0 2px 8px rgba(0,0,0,.07); }

      .value-box .value-box-area { padding:12px 16px; }
      .vbox-link {
        font-size:.76rem; color:rgba(255,255,255,.78);
        text-decoration:none; display:inline-flex; align-items:center; gap:3px;
        margin-top:4px;
      }
      .vbox-link:hover { color:#fff; text-decoration:underline; }

      .welcome-box {
        display:flex; flex-direction:column; align-items:center;
        justify-content:center; height:480px; color:#adb5bd; gap:12px;
      }
      .welcome-box .bi { font-size:3.5rem; }
      .welcome-box p   { font-size:1rem; margin:0; }

      .metric-def { font-size:.78rem; color:#6c757d; margin:0 0 2px 0; }
      .metric-val { font-size:1.4rem; font-weight:700; color:#343a40; }

      .nav-tabs .nav-link { font-size:.83rem; font-weight:600; }
    "))
  ),

  # ── Sidebar ──────────────────────────────────────────────────────────────────
  sidebar = sidebar(
    width = 290, padding = "12px",

    card(
      class = "mb-2",
      card_header(tags$i(class = "bi bi-database me-2 text-primary"), "Datos"),
      card_body(
        class = "pt-2 pb-3",
        fileInput(
          "archivo_dta", NULL,
          buttonLabel = tagList(tags$i(class = "bi bi-folder2-open me-1"), "Abrir .dta"),
          placeholder = "Sin archivo", accept = ".dta", width = "100%"
        )
      )
    ),

    accordion(
      id = "acc", open = "Filtros",

      accordion_panel(
        "Filtros", icon = tags$i(class = "bi bi-funnel"),
        uiOutput("filtro_grupo_ui"),
        selectInput(
          "tipo_enlace", "Tipo de relación",
          choices  = c("Todas"="all","Solo amistades"="amistad","Solo conflictos"="conflicto"),
          selected = "all"
        )
      ),

      accordion_panel(
        "Apariencia", icon = tags$i(class = "bi bi-sliders"),
        sliderInput("tam_nodo_base", "Tamaño base del nodo",
                    min=5, max=30, value=12, ticks=FALSE),
        checkboxInput("mostrar_etiquetas", "Mostrar IDs sobre los nodos",  value=FALSE),
        checkboxInput("mostrar_aislados",  "Mostrar alumnos sin conexión", value=TRUE)
      ),

      accordion_panel(
        "Leyenda", icon = tags$i(class = "bi bi-info-circle"),
        uiOutput("leyenda_ui")
      )
    )
  ),

  # ── Main ─────────────────────────────────────────────────────────────────────

  # Row 1: summary counts
  uiOutput("metric_row"),

  # Row 2: network metrics (clickable → switch tab)
  uiOutput("metric_row_2"),

  # Main tabset
  navset_card_tab(
    id          = "tabs_main",
    full_screen = TRUE,

    # ── Tab 1: Network ────────────────────────────────────────────────────────
    nav_panel(
      title = tagList(tags$i(class = "bi bi-diagram-3-fill me-1"), "Red"),
      value = "Red",
      card_body(padding = 0, uiOutput("red_or_welcome"))
    ),

    # ── Tab 2: Network metrics ────────────────────────────────────────────────
    nav_panel(
      title = tagList(tags$i(class = "bi bi-bar-chart-fill me-1"), "Métricas de red"),
      value = "Metricas",
      layout_columns(
        col_widths = c(12, 12),
        card(
          card_header(
            tags$i(class = "bi bi-speedometer2 me-2 text-primary"),
            "Indicadores globales del grupo"
          ),
          card_body(uiOutput("tabla_metricas_ui"))
        ),
        card(
          card_header(
            tags$i(class = "bi bi-sort-down me-2 text-primary"),
            "Centralidad por alumno"
          ),
          card_body(
            class = "p-2",
            DT::dataTableOutput("tabla_centralidad")
          )
        )
      )
    ),

    # ── Tab 3: Sociometry ─────────────────────────────────────────────────────
    nav_panel(
      title = tagList(tags$i(class = "bi bi-people-fill me-1"), "Sociometría"),
      value = "Sociometria",
      layout_columns(
        col_widths = c(5, 7),
        card(
          card_header(
            tags$i(class = "bi bi-pie-chart-fill me-2 text-primary"),
            "Distribución de estados"
          ),
          card_body(plotOutput("plot_estado", height = "360px"))
        ),
        card(
          card_header(
            tags$i(class = "bi bi-table me-2 text-primary"),
            "Clasificación por alumno"
          ),
          card_body(
            class = "p-2",
            DT::dataTableOutput("tabla_socio")
          )
        )
      )
    )
  )
)

# ── Server ─────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {

  # ── Data ────────────────────────────────────────────────────────────────────

  datos <- reactive({
    req(input$archivo_dta)
    haven::read_dta(input$archivo_dta$datapath)
  })

  grupo_label <- function(x) {
    trimws(tryCatch(as.character(haven::as_factor(x)), error = function(e) as.character(x)))
  }

  output$filtro_grupo_ui <- renderUI({
    req(datos())
    grupos <- sort(unique(grupo_label(datos()$Grupo)))
    grupos <- grupos[!is.na(grupos) & grupos != "" & grupos != "-"]
    selectInput("grupo_sel", "Grupo / clase", choices = c("Todos", grupos), selected = "Todos")
  })

  datos_filtrados <- reactive({
    req(datos())
    df <- datos()
    if (!is.null(input$grupo_sel) && input$grupo_sel != "Todos")
      df <- df %>% filter(grupo_label(Grupo) == input$grupo_sel)
    df
  })

  # ── Edges ───────────────────────────────────────────────────────────────────

  # All edges (for metrics — unaffected by the relationship-type filter)
  aristas_todas <- reactive({
    req(datos_filtrados())
    df  <- datos_filtrados()
    ids <- as.character(df$Usuario_id)
    crear_aristas(df, id_col = "Usuario_id") %>% filter(from %in% ids, to %in% ids)
  })

  # Edges filtered by tipo_enlace (for the visual network only)
  aristas <- reactive({
    req(aristas_todas())
    e <- aristas_todas()
    if (!is.null(input$tipo_enlace) && input$tipo_enlace != "all")
      e <- e %>% filter(tipo == input$tipo_enlace)
    e
  })

  # ── Nodes ───────────────────────────────────────────────────────────────────

  nodos <- reactive({
    req(datos_filtrados())
    df    <- datos_filtrados()
    edges <- aristas()

    ids_con_enlace <- union(edges$from, edges$to)
    todos_ids      <- as.character(df$Usuario_id)
    ids_mostrar    <- if (isTRUE(input$mostrar_aislados)) todos_ids else ids_con_enlace

    tibble(id = ids_mostrar) %>%
      left_join(
        df %>% mutate(
          Usuario_id = as.character(Usuario_id),
          sexo_label = tolower(trimws(tryCatch(
            as.character(haven::as_factor(Sexo)), error = function(e) as.character(Sexo)
          )))
        ) %>% select(Usuario_id, sexo_label, Grupo, happy, indegree_friend),
        by = c("id" = "Usuario_id")
      ) %>%
      mutate(
        label = if (isTRUE(input$mostrar_etiquetas)) id else "",
        value = {
          ind <- suppressWarnings(as.numeric(indegree_friend))
          ifelse(!is.na(ind) & ind > 0, input$tam_nodo_base + sqrt(ind)*4, input$tam_nodo_base)
        },
        es_mujer  = sexo_label %in% c("mujer","femenino","female","f","chica","1"),
        es_hombre = sexo_label %in% c("hombre","masculino","male","m","chico","2"),
        color        = case_when(es_mujer ~ "#E8A0BF", es_hombre ~ "#89CFF0", TRUE ~ "#CCCCCC"),
        sexo_display = case_when(es_mujer ~ "Mujer",   es_hombre ~ "Hombre",  TRUE ~ paste0("— (",sexo_label,")")),
        title = paste0(
          "<b>Alumno:</b> ", id,
          "<br><b>Sexo:</b> ",      sexo_display,
          "<br><b>Grupo:</b> ",     ifelse(is.na(Grupo),"—",as.character(Grupo)),
          "<br><b>Felicidad:</b> ", ifelse(is.na(happy),"—",as.character(happy)),
          "<br><b>Popularidad:</b> ",ifelse(is.na(indegree_friend),"—",as.character(indegree_friend))
        )
      )
  })

  # ── igraph graphs + layout (shared by viz and all metric tabs) ───────────────

  igraph_redes <- reactive({
    req(nodos(), aristas_todas())
    n   <- nodos()
    all <- aristas_todas()

    make_g <- function(e_sub) {
      if (nrow(e_sub) > 0) {
        igraph::graph_from_data_frame(e_sub %>% select(from,to), vertices = n$id, directed = TRUE)
      } else {
        g <- igraph::make_empty_graph(n = nrow(n), directed = TRUE)
        igraph::V(g)$name <- n$id; g
      }
    }

    g_f <- make_g(all %>% filter(tipo == "amistad"))
    g_e <- make_g(all %>% filter(tipo == "conflicto"))

    set.seed(42)
    coords <- if (igraph::ecount(g_f) > 0) {
      igraph::layout_with_fr(g_f, niter = 500)
    } else {
      igraph::layout_in_circle(g_f)
    }
    max_c <- max(abs(coords))
    if (max_c > 0) coords <- coords / max_c * 600

    list(g_f = g_f, g_e = g_e, coords = coords)
  })

  # ── Group-level network metrics ──────────────────────────────────────────────

  metricas_red <- reactive({
    req(igraph_redes())
    ig <- igraph_redes()
    g  <- ig$g_f; ge <- ig$g_e
    list(
      densidad_f    = round(igraph::edge_density(g), 3),
      densidad_e    = round(igraph::edge_density(ge), 3),
      reciprocidad  = round(igraph::reciprocity(g), 3),
      transitividad = round(igraph::transitivity(g, type = "global"), 3),
      apl           = tryCatch(round(igraph::mean_distance(g, directed=TRUE, unconnected=TRUE),3), error=function(e) NA),
      diametro      = tryCatch(igraph::diameter(g, directed=TRUE), error=function(e) NA),
      n_componentes = igraph::components(g, mode="weak")$no,
      n_aislados    = sum(igraph::degree(g, mode="in") == 0)
    )
  })

  # ── Node-level centrality ────────────────────────────────────────────────────

  centralidad_completa <- reactive({
    req(igraph_redes(), nodos())
    ig <- igraph_redes(); n <- nodos()
    g  <- ig$g_f; ge <- ig$g_e

    tibble(
      id          = igraph::V(g)$name,
      indegree_f  = igraph::degree(g,  mode = "in"),
      outdegree_f = igraph::degree(g,  mode = "out"),
      indegree_e  = igraph::degree(ge, mode = "in"),
      betweenness = round(igraph::betweenness(g, directed=TRUE, normalized=TRUE), 4),
      closeness   = round(igraph::closeness(g, mode="in", normalized=TRUE), 4),
      eigenvector = tryCatch(
        round(igraph::eigen_centrality(g, directed=TRUE)$vector, 4),
        error = function(e) rep(NA_real_, igraph::vcount(g))
      )
    ) %>%
    left_join(n %>% select(id, sexo_display, color), by = "id")
  })

  # ── Sociometric status (Coie & Dodge, 1983) ──────────────────────────────────

  estado_socio <- reactive({
    req(centralidad_completa())
    centralidad_completa() %>%
      mutate(
        z_f    = z_safe(indegree_f),
        z_e    = z_safe(indegree_e),
        PS     = round(z_f - z_e, 3),
        IS     = round(z_f + z_e, 3),
        Estado = case_when(
          PS >  1 & z_e < -1           ~ "Popular",
          PS < -1 & z_e >  1           ~ "Rechazado",
          IS >  1 & z_f > 0 & z_e > 0  ~ "Controvertido",
          IS < -1                       ~ "Ignorado",
          TRUE                          ~ "Promedio"
        )
      ) %>%
      select(-z_f, -z_e)
  })

  # ── Tab switching via metric value box footer links ──────────────────────────

  observeEvent(input$ir_metricas,    nav_select("tabs_main", "Metricas",    session = session))
  observeEvent(input$ir_reciprocidad,nav_select("tabs_main", "Metricas",    session = session))
  observeEvent(input$ir_aislados,    nav_select("tabs_main", "Metricas",    session = session))
  observeEvent(input$ir_socio,       nav_select("tabs_main", "Sociometria", session = session))

  # ── Legend ───────────────────────────────────────────────────────────────────

  output$leyenda_ui <- renderUI({
    dot <- function(col, label) tags$div(
      class = "d-flex align-items-center mb-1",
      tags$span(style=paste0("width:11px;height:11px;border-radius:50%;background:",col,";flex-shrink:0;margin-right:7px;")),
      tags$span(label, style="font-size:.82rem;")
    )
    bar <- function(col, label) tags$div(
      class = "d-flex align-items-center mb-1",
      tags$span(style=paste0("width:20px;height:3px;border-radius:2px;background:",col,";flex-shrink:0;margin-right:7px;")),
      tags$span(label, style="font-size:.82rem;")
    )
    tagList(
      tags$p(class="text-muted mb-1",style="font-size:.75rem;font-weight:600;","NODOS"),
      dot("#E8A0BF","Mujer"), dot("#89CFF0","Hombre"), dot("#CCCCCC","Sin datos"),
      tags$p(class="text-muted mb-1 mt-2",style="font-size:.75rem;font-weight:600;","ENLACES"),
      bar("#27ae60","Amistad"), bar("#e74c3c","Conflicto"),
      tags$p(class="text-muted mt-2 mb-0",style="font-size:.75rem;",
             HTML("Tama&ntilde;o &prop; &radic;popularidad"))
    )
  })

  # ── Row 1: summary value boxes ────────────────────────────────────────────────

  output$metric_row <- renderUI({
    req(datos_filtrados(), nodos(), aristas_todas())
    layout_columns(
      col_widths = c(4,4,4), class = "mb-2",
      value_box("Alumnos en el grupo", nrow(datos_filtrados()),
        showcase = tags$i(class="bi bi-people-fill",style="font-size:2rem;"),
        theme="primary", height="100px"),
      value_box("Amistades", sum(aristas_todas()$tipo=="amistad"),
        showcase = tags$i(class="bi bi-heart-fill",style="font-size:2rem;"),
        theme="success", height="100px"),
      value_box("Conflictos", sum(aristas_todas()$tipo=="conflicto"),
        showcase = tags$i(class="bi bi-lightning-charge-fill",style="font-size:2rem;"),
        theme="danger", height="100px")
    )
  })

  # ── Row 2: network metric value boxes (clickable) ────────────────────────────

  output$metric_row_2 <- renderUI({
    req(metricas_red(), estado_socio())
    m  <- metricas_red()
    n_pop <- sum(estado_socio()$Estado == "Popular")

    lnk <- function(inputId, label) {
      tags$a(
        href = "#", class = "vbox-link",
        onclick = sprintf(
          "Shiny.setInputValue('%s', Math.random()); return false;", inputId
        ),
        tags$i(class = "bi bi-arrow-right-circle me-1"), label
      )
    }

    layout_columns(
      col_widths = c(3,3,3,3), class = "mb-3",

      value_box(
        "Densidad de amistad", m$densidad_f,
        lnk("ir_metricas", "Ver métricas de red"),
        showcase = tags$i(class="bi bi-share-fill",style="font-size:1.8rem;"),
        theme    = value_box_theme(bg="#0dcaf0", fg="#000"),
        height   = "115px"
      ),
      value_box(
        "Reciprocidad", paste0(round(m$reciprocidad*100,1),"%"),
        lnk("ir_reciprocidad", "Ver métricas de red"),
        showcase = tags$i(class="bi bi-arrow-left-right",style="font-size:1.8rem;"),
        theme    = value_box_theme(bg="#9b59b6", fg="#fff"),
        height   = "115px"
      ),
      value_box(
        "Alumnos aislados", m$n_aislados,
        lnk("ir_aislados", "Ver centralidad"),
        showcase = tags$i(class="bi bi-person-x-fill",style="font-size:1.8rem;"),
        theme    = "warning",
        height   = "115px"
      ),
      value_box(
        "Alumnos populares", n_pop,
        lnk("ir_socio", "Ver sociometría"),
        showcase = tags$i(class="bi bi-star-fill",style="font-size:1.8rem;"),
        theme    = "success",
        height   = "115px"
      )
    )
  })

  # ── Network (Tab 1) ──────────────────────────────────────────────────────────

  output$red_or_welcome <- renderUI({
    if (is.null(input$archivo_dta)) {
      return(tags$div(
        class = "welcome-box",
        tags$i(class = "bi bi-diagram-3"),
        tags$p("Sube un archivo .dta para visualizar la red"),
        tags$p(style = "font-size:.85rem;", "Panel lateral → Datos → Abrir .dta")
      ))
    }
    withSpinner(visNetworkOutput("red", height="560px"), type=6, color="#4361ee", size=0.9)
  })

  output$red <- renderVisNetwork({
    req(nodos(), aristas(), igraph_redes())
    n  <- nodos(); e <- aristas(); ig <- igraph_redes()

    validate(
      need(nrow(datos_filtrados()) > 0, "No hay datos para este filtro."),
      need(nrow(n) > 0, "No hay nodos para este filtro.")
    )

    idx <- match(n$id, igraph::V(ig$g_f)$name)
    n$x <- ig$coords[idx, 1]
    n$y <- ig$coords[idx, 2]

    visNetwork(n, e, width="100%", height="560px") %>%
      visNodes(shape="dot", borderWidth=1.5, borderWidthSelected=3,
               font=list(size=13, color="#333333")) %>%
      visEdges(arrows=list(to=list(enabled=TRUE,scaleFactor=0.7)),
               smooth=list(enabled=TRUE,type="curvedCW",roundness=0.2),
               width=1.5, selectionWidth=3) %>%
      visOptions(highlightNearest=list(enabled=TRUE,degree=1,hover=TRUE),
                 nodesIdSelection=list(enabled=TRUE,main="Buscar alumno")) %>%
      visPhysics(enabled=FALSE)
  })

  # ── Group metrics table (Tab 2) ───────────────────────────────────────────────

  output$tabla_metricas_ui <- renderUI({
    req(metricas_red())
    m <- metricas_red()

    row_ui <- function(icon_cls, label, value, definition) {
      tags$tr(
        tags$td(style="width:32px;text-align:center;",
                tags$i(class=paste(icon_cls,"text-primary"))),
        tags$td(style="font-weight:600;font-size:.88rem;padding:8px 12px;", label),
        tags$td(style="font-size:1.05rem;font-weight:700;color:#343a40;", value),
        tags$td(style="font-size:.78rem;color:#6c757d;padding-left:12px;", definition)
      )
    }

    tags$table(
      class = "table table-hover table-sm mb-0",
      tags$tbody(
        row_ui("bi bi-share-fill",   "Densidad de amistad",    m$densidad_f,
               "|E| / (N×(N-1)) — proporción de enlaces posibles presentes"),
        row_ui("bi bi-diagram-3",    "Densidad de conflicto",  m$densidad_e,
               "Ídem para la red de conflicto"),
        row_ui("bi bi-arrow-left-right","Reciprocidad",        paste0(round(m$reciprocidad*100,1),"%"),
               "Fracción de nominaciones de amistad mutuas"),
        row_ui("bi bi-triangle",     "Transitividad",          m$transitividad,
               "Coeficiente de agrupamiento global (clustering)"),
        row_ui("bi bi-signpost-split","Long. media de camino", ifelse(is.na(m$apl),"—",m$apl),
               "Distancia geodésica media entre todos los pares alcanzables"),
        row_ui("bi bi-rulers",       "Diámetro",               ifelse(is.na(m$diametro),"—",m$diametro),
               "Camino más largo entre cualquier par de nodos"),
        row_ui("bi bi-collection",   "Componentes",            m$n_componentes,
               "Número de componentes débilmente conectados"),
        row_ui("bi bi-person-x-fill","Alumnos aislados",       m$n_aislados,
               "Alumnos sin ninguna nominación de amistad recibida")
      )
    )
  })

  # ── Centrality DT table (Tab 2) ───────────────────────────────────────────────

  output$tabla_centralidad <- DT::renderDataTable({
    req(centralidad_completa())
    df <- centralidad_completa() %>%
      select(
        `ID alumno`              = id,
        `Sexo`                   = sexo_display,
        `Popularidad ♥`          = indegree_f,
        `Nominaciones emitidas ♥` = outdegree_f,
        `Conflictos recibidos ⚡` = indegree_e,
        `Intermediación`         = betweenness,
        `Cercanía`               = closeness,
        `Vector propio`          = eigenvector
      )

    DT::datatable(
      df,
      rownames  = FALSE,
      selection = "single",
      options   = list(
        pageLength  = 10,
        order       = list(list(2, "desc")),
        language    = list(
          search      = "Buscar:",
          lengthMenu  = "Mostrar _MENU_ filas",
          info        = "Mostrando _START_ a _END_ de _TOTAL_ alumnos",
          paginate    = list(previous="Anterior", `next`="Siguiente")
        ),
        scrollX = TRUE
      )
    ) %>%
      DT::formatRound(c("Intermediación","Cercanía","Vector propio"), digits = 4) %>%
      DT::formatStyle(
        "Popularidad ♥",
        background = DT::styleColorBar(range(centralidad_completa()$indegree_f), "#d4edda"),
        backgroundSize = "100% 88%", backgroundRepeat = "no-repeat",
        backgroundPosition = "center"
      )
  })

  # ── Sociometric status chart (Tab 3) ─────────────────────────────────────────

  output$plot_estado <- renderPlot({
    req(estado_socio())
    df <- estado_socio() %>% count(Estado)

    ggplot(df, aes(x = reorder(Estado, n), y = n, fill = Estado)) +
      geom_col(width = 0.65) +
      geom_text(aes(label = n), hjust = -0.25, size = 4.2, fontface = "bold") +
      scale_fill_manual(values = COLORES_ESTADO) +
      coord_flip() +
      expand_limits(y = max(df$n) * 1.2) +
      labs(
        title    = "Estado sociométrico",
        subtitle = "Clasificación Coie & Dodge (1983)",
        x = NULL, y = "Número de alumnos"
      ) +
      theme_minimal(base_size = 12) +
      theme(
        legend.position  = "none",
        plot.title       = element_text(face = "bold", size = 13),
        plot.subtitle    = element_text(color = "grey55", size = 10),
        panel.grid.major.y = element_blank()
      )
  }, bg = "transparent")

  # ── Sociometric status DT table (Tab 3) ───────────────────────────────────────

  output$tabla_socio <- DT::renderDataTable({
    req(estado_socio())
    df <- estado_socio() %>%
      select(
        `ID alumno`              = id,
        `Sexo`                   = sexo_display,
        `Popularidad ♥`          = indegree_f,
        `Conflictos recibidos ⚡` = indegree_e,
        `Intermediación`         = betweenness,
        `Pref. Social (PS)`      = PS,
        `Impacto Social (IS)`    = IS,
        `Estado`                 = Estado
      )

    DT::datatable(
      df,
      rownames  = FALSE,
      selection = "single",
      options   = list(
        pageLength = 10,
        order      = list(list(7, "asc")),
        language   = list(
          search     = "Buscar:",
          lengthMenu = "Mostrar _MENU_ filas",
          info       = "Mostrando _START_ a _END_ de _TOTAL_ alumnos",
          paginate   = list(previous="Anterior", `next`="Siguiente")
        ),
        scrollX = TRUE
      )
    ) %>%
      DT::formatStyle(
        "Estado",
        backgroundColor = DT::styleEqual(names(BG_ESTADO), unname(BG_ESTADO)),
        fontWeight      = "600"
      )
  })
}

shinyApp(ui = ui, server = server)
