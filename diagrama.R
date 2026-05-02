# 1. CARGAR LIBRERÍA 
library(haven)

# 2. CARGAR Y PREPARAR DATOS

datos <- ES_TFG_DAN

# 3. CONVERTIR VARIABLES A NÚMEROS 

atencion_num  <- as.numeric(datos$atencion)
felicidad_num <- as.numeric(datos$happyn)
edad_num      <- as.numeric(datos$Año)

# 4. TABLAS DE FRECUENCIA 

table(datos$Sexo)


table(datos$Grupo)

# 5. ESTADÍSTICAS BÁSICAS (Medias)

mean(atencion_num, na.rm = TRUE)
mean(felicidad_num, na.rm = TRUE)

# 6. GRÁFICOS 


hist(atencion_num, 
     main = "Distribución del Nivel de Atención", 
     xlab = "Puntuación de Atención", 
     ylab = "Número de Alumnos",
     col = "steelblue", 
     border = "white")

# Gráfico de barras de Sexo
plot(as.factor(datos$Sexo), 
     main = "Distribución por Sexo", 
     col = c("pink", "lightblue"),
     ylab = "Frecuencia")
