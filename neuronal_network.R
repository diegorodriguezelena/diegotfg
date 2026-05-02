
options(shiny.maxRequestSize = 100*1024^2)


library(shiny)

library(haven)

library(dplyr)

library(stringr)

library(tidyr)

library(visNetwork)

library(tibble)

# -------- FUNCIÓN PARA CREAR ARISTAS DE AMISTAD Y CONFLICTO --------

crear_aristas <- function(df, id_col = "Usuario_id") {
  
  # AMISTAD
  
  edges_friend <- df %>%
    
    select(all_of(id_col), friend) %>%
    
    rename(from = all_of(id_col), to_raw = friend) %>%
    
    filter(!is.na(to_raw), to_raw != "") %>%
    
    mutate(
      
      to_raw = as.character(to_raw),
      
      to_raw = str_replace_all(to_raw, "\\|", ","),
      
      to_raw = str_replace_all(to_raw, "\\s+", ""),
      
      to_raw = str_replace_all(to_raw, ",+", ",")
      
    ) %>%
    
    separate_rows(to_raw, sep = ",") %>%
    
    filter(to_raw != "") %>%
    
    transmute(
      
      from = as.character(from),
      
      to = as.character(to_raw),
      
      tipo = "amistad",
      
      color = "green"
      
    )
  
  # CONFLICTO
  
  edges_enemy <- df %>%
    
    select(all_of(id_col), enemy) %>%
    
    rename(from = all_of(id_col), to_raw = enemy) %>%
    
    filter(!is.na(to_raw), to_raw != "") %>%
    
    mutate(
      
      to_raw = as.character(to_raw),
      
      to_raw = str_replace_all(to_raw, "\\|", ","),
      
      to_raw = str_replace_all(to_raw, "\\s+", ""),
      
      to_raw = str_replace_all(to_raw, ",+", ",")
      
    ) %>%
    
    separate_rows(to_raw, sep = ",") %>%
    
    filter(to_raw != "") %>%
    
    transmute(
      
      from = as.character(from),
      
      to = as.character(to_raw),
      
      tipo = "conflicto",
      
      color = "red"
      
    )
  
  bind_rows(edges_friend, edges_enemy) %>%
    
    filter(from != to)
  
}

# -------- UI --------

ui <- fluidPage(
  
  titlePanel("Red social del aula"),
  
  sidebarLayout(
    
    sidebarPanel(
      
      width = 3,
      
      h4("Carga de datos"),
      
      fileInput(
        
        "archivo_dta",
        
        "Sube el archivo .dta",
        
        accept = c(".dta")
        
      ),
      
      hr(),
      
      h4("Filtros"),
      
      uiOutput("filtro_grupo_ui"),
      
      numericInput(
        
        "tam_nodo_base",
        
        "Tamaño base del nodo",
        
        value = 10,
        
        min = 3,
        
        max = 30
        
      ),
      
      checkboxInput(
        
        "mostrar_etiquetas",
        
        "Mostrar etiquetas",
        
        value = FALSE
        
      ),
      
      hr(),
      
      h4("Resumen"),
      
      uiOutput("info_general")
      
    ),
    
    mainPanel(
      
      width = 9,
      
      visNetworkOutput("red", height = "700px")
      
    )
    
  )
  
)

# -------- SERVER --------

server <- function(input, output, session) {
  
  datos <- reactive({
    
    req(input$archivo_dta)
    
    haven::read_dta(input$archivo_dta$datapath)
    
  })
  
  output$filtro_grupo_ui <- renderUI({
    
    req(datos())
    
    grupos <- datos()$Grupo
    
    grupos <- as.character(grupos)
    
    grupos <- trimws(grupos)
    
    grupos <- grupos[!is.na(grupos) & grupos != "" & grupos != "-"]
    
    grupos <- sort(unique(grupos))
    
    selectInput(
      
      "grupo_sel",
      
      "Filtrar por grupo",
      
      choices = c("Todos", grupos),
      
      selected = "Todos"
      
    )
    
  })
  
  datos_filtrados <- reactive({
    
    req(datos())
    
    df <- datos()
    
    if (!is.null(input$grupo_sel) && input$grupo_sel != "Todos") {
      
      df <- df %>% filter(as.character(Grupo) == input$grupo_sel)
      
    }
    
    df
    
  })
  
  aristas <- reactive({
    
    req(datos_filtrados())
    
    df_filtrado <- datos_filtrados()
    
    edges <- crear_aristas(df_filtrado, id_col = "Usuario_id")
    
    ids_validos <- as.character(df_filtrado$Usuario_id)
    
    edges %>%
      
      filter(from %in% ids_validos & to %in% ids_validos)
    
  })
  
  nodos <- reactive({
    
    req(datos_filtrados(), aristas())
    
    df <- datos_filtrados()
    
    edges <- aristas()
    
    ids_nodos <- union(edges$from, edges$to)
    
    tibble(id = as.character(ids_nodos)) %>%
      
      left_join(
        
        df %>%
          
          mutate(Usuario_id = as.character(Usuario_id)) %>%
          
          select(Usuario_id, Sexo, Grupo, happy, indegree_friend),
        
        by = c("id" = "Usuario_id")
        
      ) %>%
      
      mutate(
        
        label = if (isTRUE(input$mostrar_etiquetas)) id else "",
        
        value = ifelse(
          
          !is.na(indegree_friend),
          
          input$tam_nodo_base + pmin(indegree_friend, 10),
          
          input$tam_nodo_base
          
        ),
        
        title = paste0(
          
          "<b>Alumno:</b> ", id,
          
          "<br><b>Sexo:</b> ", ifelse(is.na(Sexo), "", as.character(Sexo)),
          
          "<br><b>Grupo:</b> ", ifelse(is.na(Grupo), "", as.character(Grupo)),
          
          "<br><b>Happy:</b> ", ifelse(is.na(happy), "", as.character(happy)),
          
          "<br><b>Popularidad:</b> ", ifelse(is.na(indegree_friend), "", as.character(indegree_friend))
          
        )
        
      )
    
  })
  
  output$red <- renderVisNetwork({
    
    req(nodos(), aristas())
    
    validate(
      
      need(nrow(datos_filtrados()) > 0, "No hay datos para este filtro."),
      
      need(nrow(nodos()) > 0, "No hay nodos para este filtro."),
      
      need(nrow(aristas()) > 0, "No hay conexiones para este filtro."),
      
      need(nrow(nodos()) <= 150, "Demasiados nodos. Filtra más por grupo para ver la red.")
      
    )
    
    visNetwork(nodos(), aristas(), width = "100%", height = "700px") %>%
      
      visNodes(shape = "dot") %>%
      
      visEdges(
        
        arrows = "to",
        
        smooth = FALSE,
        
        color = list(color = aristas()$color)
        
      ) %>%
      
      visOptions(highlightNearest = TRUE) %>%
      
      visPhysics(stabilization = FALSE) %>%
      
      visLayout(randomSeed = 123)
    
  })
  
  output$info_general <- renderUI({
    
    req(datos_filtrados(), aristas(), nodos())
    
    tagList(
      
      p(strong("Filas filtradas:"), nrow(datos_filtrados())),
      
      p(strong("Nodos en la red:"), nrow(nodos())),
      
      p(strong("Enlaces en la red:"), nrow(aristas())),
      
      p(strong("Amistades:"), sum(aristas()$tipo == "amistad")),
      
      p(strong("Conflictos:"), sum(aristas()$tipo == "conflicto"))
      
    )
    
  })
  
}

# -------- APP --------

shinyApp(ui = ui, server = server)
