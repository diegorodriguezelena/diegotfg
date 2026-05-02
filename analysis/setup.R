# Install required packages (run once)
pkgs <- c("shiny", "bslib", "shinycssloaders", "DT",
          "haven", "dplyr", "stringr", "tidyr", "ggplot2",
          "visNetwork", "tibble", "igraph")
install.packages(setdiff(pkgs, rownames(installed.packages())))

library(haven)

datos <- read_dta("../data/raw/ES_TFG_DAN.dta")

str(datos)
summary(datos)
names(datos)
