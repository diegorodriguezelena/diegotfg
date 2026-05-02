# =============================================================================
# Análisis exploratorio — Red social del aula (TFG)
# =============================================================================
# Ejecutar desde el directorio raíz del proyecto:
#   source("analysis/exploratory.R")
# Los gráficos se guardan en outputs/figures/
# Las tablas se exportan a outputs/
# =============================================================================

# ── 0. Paquetes ───────────────────────────────────────────────────────────────
library(haven)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(igraph)

source("app/helpers.R")

# ── 1. Carga y preparación de datos ──────────────────────────────────────────
datos_raw <- haven::read_dta("data/raw/ES_TFG_DAN.dta")

get_label <- function(x) trimws(tryCatch(
  as.character(haven::as_factor(x)),
  error = function(e) as.character(x)
))

datos <- datos_raw %>%
  mutate(
    Usuario_id   = as.character(Usuario_id),
    Sexo_label   = get_label(Sexo),
    Grupo_label  = get_label(Grupo),
    happyn_num   = suppressWarnings(as.numeric(happyn)),
    atencion_num = suppressWarnings(as.numeric(atencion)),
    indegree_num = suppressWarnings(as.numeric(indegree_friend))
  )

grupos <- sort(unique(datos$Grupo_label))
grupos <- grupos[!is.na(grupos) & grupos != "" & grupos != "-"]

dir.create("outputs/figures", showWarnings = FALSE, recursive = TRUE)

# =============================================================================
# 2. VISIÓN GENERAL DE LA MUESTRA
# =============================================================================
cat("\n========== VISIÓN GENERAL DE LA MUESTRA ==========\n")
cat("Total de alumnos:", nrow(datos), "\n")

cat("\nAlumnos por grupo:\n")
print(sort(table(datos$Grupo_label), decreasing = TRUE))

cat("\nDistribución por sexo:\n")
print(table(datos$Sexo_label))

cat("\nSexo por grupo:\n")
print(table(datos$Grupo_label, datos$Sexo_label))

# =============================================================================
# 3. ESTADÍSTICAS DESCRIPTIVAS DE VARIABLES INDIVIDUALES
# =============================================================================
cat("\n========== ESTADÍSTICAS DESCRIPTIVAS ==========\n")

resumen_vars <- datos %>%
  summarise(
    across(c(happyn_num, atencion_num, indegree_num), list(
      media = ~round(mean(.x, na.rm = TRUE), 2),
      sd    = ~round(sd(.x,   na.rm = TRUE), 2),
      min   = ~min(.x, na.rm = TRUE),
      max   = ~max(.x, na.rm = TRUE),
      NAs   = ~sum(is.na(.x))
    ), .names = "{.col}__{.fn}")
  ) %>%
  tidyr::pivot_longer(everything(), names_sep = "__", names_to = c("variable", "stat")) %>%
  tidyr::pivot_wider(names_from = stat, values_from = value)

print(as.data.frame(resumen_vars))

cat("\nMedia de felicidad y atención por sexo:\n")
print(datos %>%
  group_by(Sexo_label) %>%
  summarise(
    n               = n(),
    media_felicidad = round(mean(happyn_num,   na.rm = TRUE), 2),
    sd_felicidad    = round(sd(happyn_num,     na.rm = TRUE), 2),
    media_atencion  = round(mean(atencion_num, na.rm = TRUE), 2)
  ))

cat("\nMedia de felicidad por grupo:\n")
print(datos %>%
  group_by(Grupo_label) %>%
  summarise(
    n               = n(),
    media_felicidad = round(mean(happyn_num, na.rm = TRUE), 2),
    sd_felicidad    = round(sd(happyn_num,   na.rm = TRUE), 2)
  ) %>% arrange(desc(media_felicidad)))

# =============================================================================
# 4. CONSTRUCCIÓN DE REDES POR GRUPO
# =============================================================================

construir_red <- function(grupo, datos_all) {
  df_g  <- datos_all %>% filter(Grupo_label == grupo)
  ids   <- df_g$Usuario_id
  edges <- crear_aristas(df_g, id_col = "Usuario_id") %>%
    filter(from %in% ids, to %in% ids)

  make_ig <- function(e_sub) {
    if (nrow(e_sub) > 0) {
      igraph::graph_from_data_frame(e_sub %>% select(from, to),
                                    vertices = ids, directed = TRUE)
    } else {
      g <- igraph::make_empty_graph(n = length(ids), directed = TRUE)
      igraph::V(g)$name <- ids; g
    }
  }

  edges_f <- edges %>% filter(tipo == "amistad")
  edges_e <- edges %>% filter(tipo == "conflicto")

  list(
    grupo   = grupo,
    df      = df_g,
    edges   = edges,
    edges_f = edges_f,
    edges_e = edges_e,
    g_f     = make_ig(edges_f),
    g_e     = make_ig(edges_e),
    ids     = ids
  )
}

redes <- lapply(grupos, construir_red, datos_all = datos)
names(redes) <- grupos

# =============================================================================
# 5. MÉTRICAS DE RED A NIVEL DE GRUPO
# =============================================================================
cat("\n========== MÉTRICAS DE RED POR GRUPO ==========\n")

metricas_grupo <- lapply(redes, function(r) {
  g <- r$g_f

  apl      <- tryCatch(
    round(igraph::mean_distance(g, directed = TRUE, unconnected = TRUE), 3),
    error = function(e) NA_real_
  )
  diametro <- tryCatch(
    igraph::diameter(g, directed = TRUE),
    error = function(e) NA_integer_
  )

  data.frame(
    grupo              = r$grupo,
    n_alumnos          = length(r$ids),
    n_amistades        = nrow(r$edges_f),
    n_conflictos       = nrow(r$edges_e),
    densidad_amistad   = round(igraph::edge_density(r$g_f), 3),
    densidad_conflicto = round(igraph::edge_density(r$g_e), 3),
    reciprocidad       = round(igraph::reciprocity(r$g_f), 3),
    transitividad      = round(igraph::transitivity(r$g_f, type = "global"), 3),
    long_media_camino  = apl,
    diametro           = diametro,
    n_componentes      = igraph::components(r$g_f, mode = "weak")$no,
    n_aislados         = sum(igraph::degree(r$g_f, mode = "in") == 0),
    stringsAsFactors   = FALSE
  )
})

metricas_grupo_df <- do.call(rbind, metricas_grupo)
print(metricas_grupo_df)

# =============================================================================
# 6. MÉTRICAS DE CENTRALIDAD POR ALUMNO
# =============================================================================
cat("\n========== CENTRALIDAD POR ALUMNO ==========\n")

centralidad_lista <- lapply(redes, function(r) {
  g  <- r$g_f
  ge <- r$g_e

  tibble(
    Usuario_id  = igraph::V(g)$name,
    grupo       = r$grupo,
    indegree_f  = igraph::degree(g,  mode = "in"),
    outdegree_f = igraph::degree(g,  mode = "out"),
    indegree_e  = igraph::degree(ge, mode = "in"),
    outdegree_e = igraph::degree(ge, mode = "out"),
    betweenness = round(igraph::betweenness(g, directed = TRUE, normalized = TRUE), 4),
    closeness   = round(igraph::closeness(g, mode = "in", normalized = TRUE), 4),
    eigenvector = tryCatch(
      round(igraph::eigen_centrality(g, directed = TRUE)$vector, 4),
      error = function(e) rep(NA_real_, igraph::vcount(g))
    )
  ) %>%
    left_join(
      r$df %>% select(Usuario_id, Sexo_label, Grupo_label, happyn_num, atencion_num),
      by = "Usuario_id"
    )
})

centralidad_df <- bind_rows(centralidad_lista)

cat("\nTop 10 — Popularidad (in-degree amistad):\n")
print(centralidad_df %>%
  arrange(desc(indegree_f)) %>%
  select(Usuario_id, grupo, indegree_f, indegree_e, betweenness, happyn_num) %>%
  head(10))

cat("\nTop 10 — Intermediación (betweenness centralidad):\n")
print(centralidad_df %>%
  arrange(desc(betweenness)) %>%
  select(Usuario_id, grupo, betweenness, indegree_f, indegree_e) %>%
  head(10))

cat("\nAlumnos más rechazados (in-degree conflicto ≥ 3):\n")
print(centralidad_df %>%
  filter(indegree_e >= 3) %>%
  arrange(desc(indegree_e)) %>%
  select(Usuario_id, grupo, indegree_f, indegree_e, happyn_num) %>%
  head(10))

# =============================================================================
# 7. ESTADO SOCIOMÉTRICO (Coie & Dodge, 1983)
# =============================================================================
# Social Preference  (SP) = z(indegree_f) - z(indegree_e)
# Social Impact      (SI) = z(indegree_f) + z(indegree_e)
#
# Popular      : SP > 1  y z(indegree_e) < -1
# Rechazado    : SP < -1 y z(indegree_e) > 1
# Controvertido: SI > 1  y z_f > 0 y z_e > 0
# Ignorado     : SI < -1
# Promedio     : resto

cat("\n========== ESTADO SOCIOMÉTRICO ==========\n")

z_safe <- function(x) {
  s <- sd(x, na.rm = TRUE)
  if (is.na(s) || s == 0) return(rep(0, length(x)))
  (x - mean(x, na.rm = TRUE)) / s
}

centralidad_df <- centralidad_df %>%
  group_by(grupo) %>%
  mutate(
    z_f    = z_safe(indegree_f),
    z_e    = z_safe(indegree_e),
    SP     = round(z_f - z_e, 3),
    SI     = round(z_f + z_e, 3),
    estado = case_when(
      SP >  1 & z_e < -1             ~ "Popular",
      SP < -1 & z_e >  1             ~ "Rechazado",
      SI >  1 & z_f > 0 & z_e > 0   ~ "Controvertido",
      SI < -1                        ~ "Ignorado",
      TRUE                           ~ "Promedio"
    )
  ) %>%
  ungroup()

cat("Distribución global de estados sociométricos:\n")
print(table(centralidad_df$estado))

cat("\nEstados por grupo:\n")
print(table(centralidad_df$grupo, centralidad_df$estado))

cat("\nMedia de felicidad por estado sociométrico:\n")
print(centralidad_df %>%
  group_by(estado) %>%
  summarise(
    n               = n(),
    media_felicidad = round(mean(happyn_num, na.rm = TRUE), 2),
    sd_felicidad    = round(sd(happyn_num,   na.rm = TRUE), 2)
  ) %>% arrange(desc(media_felicidad)))

# =============================================================================
# 8. HOMOFILIA DE GÉNERO
# =============================================================================
cat("\n========== HOMOFILIA DE GÉNERO ==========\n")

homofilia_lista <- lapply(redes, function(r) {
  if (nrow(r$edges_f) == 0) return(NULL)
  sexo_map <- setNames(r$df$Sexo_label, r$df$Usuario_id)

  r$edges_f %>%
    mutate(
      sexo_from  = sexo_map[from],
      sexo_to    = sexo_map[to],
      mismo_sexo = (sexo_from == sexo_to) & !is.na(sexo_from) & !is.na(sexo_to)
    ) %>%
    summarise(
      grupo           = r$grupo,
      n_amistades     = n(),
      pct_mismo_sexo  = round(mean(mismo_sexo, na.rm = TRUE) * 100, 1),
      pct_MM          = round(mean(sexo_from == "mujer"  & sexo_to == "mujer",  na.rm = TRUE) * 100, 1),
      pct_HH          = round(mean(sexo_from == "hombre" & sexo_to == "hombre", na.rm = TRUE) * 100, 1),
      pct_mixto       = round(mean(sexo_from != sexo_to,  na.rm = TRUE) * 100, 1)
    )
})

homofilia_df <- bind_rows(homofilia_lista)
cat("% amistades del mismo sexo por grupo (MM = mujer-mujer, HH = hombre-hombre):\n")
print(homofilia_df)

# =============================================================================
# 9. FELICIDAD Y POSICIÓN EN LA RED
# =============================================================================
cat("\n========== FELICIDAD Y POSICIÓN EN LA RED ==========\n")

test_corr <- function(x, y, etiqueta) {
  r <- cor.test(x, y, use = "complete.obs")
  cat(sprintf("%-45s r = %+.3f  p = %.4f  n = %d\n",
              etiqueta, r$estimate, r$p.value,
              sum(!is.na(x) & !is.na(y))))
}

test_corr(centralidad_df$indegree_f,  centralidad_df$happyn_num, "In-degree amistad ~ felicidad:")
test_corr(centralidad_df$indegree_e,  centralidad_df$happyn_num, "In-degree conflicto ~ felicidad:")
test_corr(centralidad_df$betweenness, centralidad_df$happyn_num, "Betweenness ~ felicidad:")
test_corr(centralidad_df$indegree_f,  centralidad_df$atencion_num, "In-degree amistad ~ atención:")

# ANOVA: felicidad por estado sociométrico
aov_res <- aov(happyn_num ~ estado, data = centralidad_df)
cat("\nANOVA — felicidad por estado sociométrico:\n")
print(summary(aov_res))

# =============================================================================
# 10. GRÁFICOS
# =============================================================================
tema_base <- theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 13),
        plot.subtitle = element_text(color = "grey50", size = 10))

colores_sexo   <- c("mujer" = "#E8A0BF", "hombre" = "#89CFF0")
colores_estado <- c(
  "Popular"       = "#27ae60", "Rechazado"     = "#e74c3c",
  "Controvertido" = "#f39c12", "Ignorado"      = "#95a5a6",
  "Promedio"      = "#4361ee"
)

# ── Fig 1: composición de sexo por grupo ─────────────────────────────────────
p1 <- datos %>%
  filter(!is.na(Sexo_label), Grupo_label %in% grupos) %>%
  ggplot(aes(x = Grupo_label, fill = Sexo_label)) +
  geom_bar(position = "fill") +
  scale_fill_manual(values = colores_sexo,
                    labels = c("mujer" = "Mujer", "hombre" = "Hombre"),
                    name   = "Sexo") +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(title    = "Composición de sexo por grupo",
       subtitle = "Proporción de chicas y chicos en cada clase",
       x = "Grupo", y = NULL) +
  tema_base +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

ggsave("outputs/figures/01_sexo_por_grupo.png", p1, width = 8, height = 5, dpi = 150)

# ── Fig 2: distribución del in-degree de amistad ─────────────────────────────
p2 <- centralidad_df %>%
  ggplot(aes(x = indegree_f)) +
  geom_histogram(binwidth = 1, fill = "#27ae60", color = "white") +
  labs(title    = "Distribución de popularidad (in-degree amistad)",
       subtitle = "Número de nominaciones de amistad recibidas",
       x = "Nominaciones recibidas", y = "Número de alumnos") +
  tema_base

ggsave("outputs/figures/02_indegree_amistad.png", p2, width = 7, height = 4, dpi = 150)

# ── Fig 3: in-degree conflicto ────────────────────────────────────────────────
p3 <- centralidad_df %>%
  ggplot(aes(x = indegree_e)) +
  geom_histogram(binwidth = 1, fill = "#e74c3c", color = "white") +
  labs(title    = "Distribución de conflictos recibidos (in-degree enemigo)",
       subtitle = "Número de nominaciones de conflicto recibidas",
       x = "Nominaciones de conflicto recibidas", y = "Número de alumnos") +
  tema_base

ggsave("outputs/figures/03_indegree_conflicto.png", p3, width = 7, height = 4, dpi = 150)

# ── Fig 4: popularidad vs. felicidad ─────────────────────────────────────────
p4 <- centralidad_df %>%
  filter(!is.na(happyn_num)) %>%
  ggplot(aes(x = indegree_f, y = happyn_num, color = Sexo_label)) +
  geom_jitter(alpha = 0.55, size = 2, width = 0.2, height = 0.1) +
  geom_smooth(method = "lm", se = TRUE, color = "#333333", linewidth = 0.8) +
  scale_color_manual(values = colores_sexo,
                     labels = c("mujer" = "Mujer", "hombre" = "Hombre"),
                     name   = "Sexo") +
  labs(title    = "Popularidad y bienestar subjetivo",
       subtitle = "Correlación entre in-degree de amistad y felicidad",
       x = "In-degree amistad", y = "Felicidad (happyn)") +
  tema_base

ggsave("outputs/figures/04_popularidad_felicidad.png", p4, width = 7, height = 5, dpi = 150)

# ── Fig 5: densidad de amistad por grupo ─────────────────────────────────────
p5 <- metricas_grupo_df %>%
  ggplot(aes(x = reorder(grupo, densidad_amistad), y = densidad_amistad)) +
  geom_col(fill = "#4361ee", alpha = 0.85) +
  geom_text(aes(label = densidad_amistad), hjust = -0.15, size = 3.2, color = "grey30") +
  coord_flip() +
  labs(title    = "Densidad de la red de amistad por grupo",
       subtitle = "|E| / (N × (N-1))",
       x = NULL, y = "Densidad") +
  tema_base +
  expand_limits(y = max(metricas_grupo_df$densidad_amistad, na.rm = TRUE) * 1.18)

ggsave("outputs/figures/05_densidad_grupos.png", p5, width = 7, height = 5, dpi = 150)

# ── Fig 6: estado sociométrico ────────────────────────────────────────────────
p6 <- centralidad_df %>%
  count(estado) %>%
  ggplot(aes(x = reorder(estado, n), y = n, fill = estado)) +
  geom_col() +
  geom_text(aes(label = n), hjust = -0.2, size = 3.5) +
  scale_fill_manual(values = colores_estado) +
  coord_flip() +
  labs(title    = "Distribución del estado sociométrico",
       subtitle = "Clasificación Coie & Dodge (1983)",
       x = NULL, y = "Número de alumnos") +
  tema_base +
  theme(legend.position = "none") +
  expand_limits(y = max(count(centralidad_df, estado)$n) * 1.15)

ggsave("outputs/figures/06_estado_sociometrico.png", p6, width = 7, height = 5, dpi = 150)

# ── Fig 7: felicidad por estado sociométrico ──────────────────────────────────
p7 <- centralidad_df %>%
  filter(!is.na(happyn_num)) %>%
  ggplot(aes(x = reorder(estado, happyn_num, FUN = median), y = happyn_num, fill = estado)) +
  geom_boxplot(outlier.shape = 21, outlier.size = 1.8, alpha = 0.8) +
  scale_fill_manual(values = colores_estado) +
  labs(title    = "Felicidad según estado sociométrico",
       subtitle = "Mediana e IQR por categoría",
       x = "Estado sociométrico", y = "Felicidad (happyn)") +
  tema_base +
  theme(legend.position = "none")

ggsave("outputs/figures/07_felicidad_estado.png", p7, width = 8, height = 5, dpi = 150)

# ── Fig 8: homofilia de género ────────────────────────────────────────────────
p8 <- homofilia_df %>%
  ggplot(aes(x = reorder(grupo, pct_mismo_sexo), y = pct_mismo_sexo)) +
  geom_col(fill = "#9b59b6", alpha = 0.8) +
  geom_hline(yintercept = 50, linetype = "dashed", color = "grey50") +
  geom_text(aes(label = paste0(pct_mismo_sexo, "%")), hjust = -0.15, size = 3.2) +
  coord_flip() +
  labs(title    = "Homofilia de género en amistades",
       subtitle = "% de amistades entre alumnos del mismo sexo (línea = 50 %)",
       x = NULL, y = "% mismo sexo") +
  tema_base +
  expand_limits(y = 105)

ggsave("outputs/figures/08_homofilia_genero.png", p8, width = 7, height = 5, dpi = 150)

# =============================================================================
# 11. EXPORTAR TABLAS
# =============================================================================
write.csv(metricas_grupo_df, "outputs/metricas_grupo.csv",    row.names = FALSE)
write.csv(
  centralidad_df %>% select(-z_f, -z_e),
  "outputs/centralidad_alumnos.csv", row.names = FALSE
)
write.csv(homofilia_df, "outputs/homofilia_genero.csv", row.names = FALSE)

cat("\n✓ 8 figuras guardadas en outputs/figures/\n")
cat("✓ Tablas exportadas en outputs/\n")
cat("  - metricas_grupo.csv\n")
cat("  - centralidad_alumnos.csv\n")
cat("  - homofilia_genero.csv\n")
