---
title: "Predicción de Metros Cuadrados en Pisos de Madrid"
author: "Evaluación Airbnb"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
library(tidyverse)
library(dplyr)
library(ggplot2)
library(cluster)
library(factoextra)
library(multcomp)
library(stats)
library(reshape2)
```

### 1. Filtrar los datos de interés

```{r}
df <- read.csv("airbnb-listings.csv")

# Nos quedamos con las columnas más relevantes
df_madrid <- df %>%
  filter(City == "Madrid", Room.Type == "Entire home/apt", Neighbourhood != "") %>%
  select(City, Room.Type, Neighbourhood, Accommodates, Bathrooms, Bedrooms, Beds,
         Price, `Square Feet`, `Guests Included`, `Extra People`, `Review Scores Rating`,
         Latitude, Longitude)

# Eliminamos columnas no necesarias
df_madrid <- df_madrid %>% select(-City, -Room.Type)
```

### 2. Crear columna de metros cuadrados

```{r}
df_madrid$Square.Meters <- df_madrid$`Square Feet` * 0.092903
```

### 3. Porcentaje de NAs en metros cuadrados

```{r}
na_pct <- mean(is.na(df_madrid$Square.Meters)) * 100
na_pct
```

### 4. Porcentaje de ceros en metros cuadrados (sin contar NAs)

```{r}
zeros_pct <- mean(df_madrid$Square.Meters[!is.na(df_madrid$Square.Meters)] == 0) * 100
zeros_pct
```

### 5. Reemplazar 0 por NA

```{r}
df_madrid$Square.Meters[df_madrid$Square.Meters == 0] <- NA
```

### 6. Histograma de metros cuadrados

```{r}
hist(df_madrid$Square.Meters, breaks = 30, main = "Distribución de Metros Cuadrados", xlab = "m²")
```

### 7. Eliminar pisos con menos de 20 m²

```{r}
df_madrid$Square.Meters[df_madrid$Square.Meters < 20] <- NA
```

### 8. Eliminar barrios donde todos los metros cuadrados son NA

```{r}
barrio_validos <- df_madrid %>% 
  group_by(Neighbourhood) %>% 
  summarise(tiene_datos = sum(!is.na(Square.Meters))) %>% 
  filter(tiene_datos > 0) %>% 
  pull(Neighbourhood)

df_madrid <- df_madrid %>% filter(Neighbourhood %in% barrio_validos)
```

### 9. ¿Tienen todos los barrios los mismos metros cuadrados de media? ¿Con que test lo comprobarías?
# ANOVA para ver si los barrios difieren en metros cuadrados

```{r}
anova_result <- aov(Square.Meters ~ Neighbourhood, data = df_madrid)
summary(anova_result)
```

### 10. Prueba de Tukey y matriz de distancias

```{r}
tukey_result <- TukeyHSD(anova_result)
tukey_df <- as.data.frame(tukey_result$Neighbourhood)
tukey_df$comparacion <- rownames(tukey_df)
tukey_df <- separate(tukey_df, comparacion, into = c("barrio_1", "barrio_2"), sep = "-")

# Creamos matriz de distancias basada en p-valor
matriz_p <- dcast(tukey_df, barrio_1 ~ barrio_2, value.var = "p adj")
matriz_p <- column_to_rownames(matriz_p, "barrio_1")
matriz_p[is.na(matriz_p)] <- 1
matriz_dist <- 1 - as.matrix(matriz_p)
```

### Comentario Adicional:
> Según la prueba de Tukey, hay diferencias significativas entre varios barrios. Por ejemplo:
> - Sol vs Goya (p < 0.01)
> - Embajadores vs Jerónimos (p < 0.05)
> - Castellana vs Almenara (p < 0.05)

### 11. Dendrograma de barrios

```{r}
clustering <- hclust(as.dist(matriz_dist))
plot(clustering, main = "Dendrograma de Barrios")
```

### 12. Número de clusters recomendados: 5 (punto de corte visual)

```{r}
grupos <- cutree(clustering, k = 5)
cluster_df <- data.frame(Barrio = names(grupos), Cluster = grupos)
```

### 13. Añadir columna de cluster al dataframe

```{r}
df_madrid <- df_madrid %>% left_join(cluster_df, by = c("Neighbourhood" = "Barrio"))
names(df_madrid)[names(df_madrid) == "Cluster"] <- "neighb_id"
```

### 14. Dividir en conjunto de entrenamiento y prueba (80/20)

```{r}
set.seed(123)
sample_index <- sample(1:nrow(df_madrid), 0.8 * nrow(df_madrid))
df_train <- df_madrid[sample_index, ]
df_test <- df_madrid[-sample_index, ]
```

### Comentario Adicional:
> Usamos una división 80/20 porque es una práctica común que permite al modelo entrenarse con suficientes datos y aún así ser evaluado de forma robusta.

### 15. Entrenamiento del modelo

```{r}
df_model <- df_train %>% select(Square.Meters, Accommodates, Bathrooms, Bedrooms, Beds, Price,
                                `Guests Included`, `Extra People`, `Review Scores Rating`,
                                Latitude, Longitude, neighb_id)
names(df_model) <- make.names(names(df_model))
modelo_lm <- lm(Square.Meters ~ ., data = df_model)
summary(modelo_lm)
```

### 16. Evaluación del modelo en test

```{r}
df_test_model <- df_test %>% select(Square.Meters, Accommodates, Bathrooms, Bedrooms, Beds, Price,
                                    `Guests Included`, `Extra People`, `Review Scores Rating`,
                                    Latitude, Longitude, neighb_id) %>% na.omit()
names(df_test_model) <- make.names(names(df_test_model))
predicciones <- predict(modelo_lm, newdata = df_test_model)
reales <- df_test_model$Square.Meters
MAE <- mean(abs(predicciones - reales))
RMSE <- sqrt(mean((predicciones - reales)^2))
R2 <- 1 - sum((reales - predicciones)^2) / sum((reales - mean(reales))^2)

cat("MAE:", round(MAE,2), "m²\n")
cat("RMSE:", round(RMSE,2), "m²\n")
cat("R²:", round(R2,3), "\n")
```

> Resultado:
> - MAE: 24.3 m²
> - RMSE: 51.71 m²
> - R²: 0.598

### 17. Predicción de caso específico (piso en Sol)

```{r}
nuevo_piso <- data.frame(
  Accommodates = 6,
  Bathrooms = 1,
  Bedrooms = 3,
  Beds = 3,
  Price = 80,
  Guests.Included = 6,
  Extra.People = 0,
  Review.Scores.Rating = 80,
  Latitude = mean(df_madrid$Latitude, na.rm = TRUE),
  Longitude = mean(df_madrid$Longitude, na.rm = TRUE),
  neighb_id = cluster_df$Cluster[cluster_df$Barrio == "Sol"]
)
prediccion_piso <- predict(modelo_lm, newdata = nuevo_piso)

# Variación con una habitación más
nuevo_piso$Bedrooms <- 4
prediccion_4hab <- predict(modelo_lm, newdata = nuevo_piso)
diferencia <- prediccion_4hab - prediccion_piso
```

> El apartamento tendría aproximadamente **66.1 m²**. Cada habitación adicional suma unos **17.82 m²**.

### 18. Rellenar los metros cuadrados perdidos con el modelo

```{r}
df_na <- df_madrid %>%
  filter(is.na(Square.Meters)) %>%
  select(Accommodates, Bathrooms, Bedrooms, Beds, Price,
         `Guests Included`, `Extra People`, `Review Scores Rating`,
         Latitude, Longitude, neighb_id) %>%
  na.omit()
names(df_na) <- make.names(names(df_na))
predicciones_na <- predict(modelo_lm, newdata = df_na)

posiciones_na <- which(is.na(df_madrid$Square.Meters))
posiciones_na <- posiciones_na[1:length(predicciones_na)]
df_madrid$Square.Meters[posiciones_na] <- predicciones_na
```

> Tras este proceso quedaron 705 registros sin poder rellenar por falta de otros datos.

---


