library(dplyr)
library(stringr)
library(tidyr)

crear_aristas <- function(df, id_col = "Usuario_id") {
  parse_rel <- function(rel_col, tipo, color) {
    df %>%
      select(all_of(c(id_col, rel_col))) %>%
      rename(from = all_of(id_col), to_raw = all_of(rel_col)) %>%
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
        from  = as.character(from),
        to    = as.character(to_raw),
        tipo  = tipo,
        color = color
      )
  }

  bind_rows(
    parse_rel("friend", "amistad",   "#27ae60"),
    parse_rel("enemy",  "conflicto", "#e74c3c")
  ) %>%
    filter(from != to)
}
