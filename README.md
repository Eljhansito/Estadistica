# Estadistica
Practica Estadística
## 📋 Descripción

Este proyecto forma parte de una evaluación académica donde se trabaja con un dataset de anuncios de Airbnb.  
El objetivo es **predecir los metros cuadrados (m²)** de apartamentos en Madrid en base a características del anuncio, aplicando técnicas de análisis de datos y modelos de regresión lineal en R.

---

## 🧠 Objetivos del proyecto

- Limpiar y preparar los datos del dataset original.
- Filtrar los apartamentos de interés (Madrid, "Entire home/apt").
- Crear una nueva variable en m².
- Analizar la distribución de los metros cuadrados.
- Detectar y tratar valores nulos y atípicos.
- Usar pruebas estadísticas (ANOVA y Tukey) para comparar barrios.
- Agrupar barrios por similitud con dendrogramas (clustering).
- Entrenar un modelo para predecir metros cuadrados.
- Evaluar la calidad del modelo con métricas (MAE, RMSE, R²).
- Aplicar el modelo para rellenar valores faltantes en el dataset.
- Predecir m² en un caso hipotético.

---

## 🛠️ Herramientas utilizadas

- Lenguaje: **R**
- Librerías: `tidyverse`, `ggplot2`, `cluster`, `factoextra`, `multcomp`, `reshape2`, `stats`
- Formato de entrega: `.Rmd` (R Markdown)

---

## 📈 Resultados del modelo

- **MAE (Error Absoluto Medio):** 24.3 m²  
- **RMSE (Raíz del Error Cuadrático Medio):** 51.71 m²  
- **R² (Coeficiente de Determinación):** 0.598  

---

## 🔍 Observaciones

- El modelo logró rellenar correctamente gran parte de los valores perdidos.
- Algunos casos no pudieron ser completados por falta de datos en columnas clave.
- Se documenta cada paso con explicaciones y justificaciones dentro del archivo `.Rmd`.

---

## 📁 Archivos del repositorio

- `airbnb_madrid_modelo.Rmd`: Código completo, comentado y ejecutable.
- `airbnb-listings.csv`: Dataset original usado.
- (Opcional) `airbnb_madrid_modelo.html`: Versión renderizada para visualización directa.

---

## 🧑‍🏫 Evaluación

Este trabajo demuestra el uso de herramientas de análisis de datos en R aplicadas a un caso real, desde la limpieza de datos hasta la construcción y evaluación de modelos predictivos.
