# Traffic flow analysis in AUSA toll booths.
# Julián Ailán - jailan@itba.edu.ar
# ITBA - 2018/2019
# Definition of methods used in the notebook.

library(png)
library(dplyr)
library(ggplot2)
library(forecast)

traffic.volume.heatmap <- function(start.year, end.year = start.year, normalize = T) {
  #' Heatmap with the volume of traffic at a certain moment of time.
  #' 
  #' @param start.year First year to take into account when building the heatmap (inclusive).
  #' @param end.year Last year to take into account when building the heatmap (inclusive).
  #' @param normalize Normalize values in each cell to [0, 1] range.
  #' @return A ggplot2 object containing the heatmap.
  #' @example 
  #' traffic.volume.heatmap(2008, 2009)

  features <- c('ESTACION', 'DIA', 'CANTIDAD_PASOS', 'PERIODO')
  t <- df[features]; rm(features)
  t <- rbind(t %>%
               filter(PERIODO >= start.year & PERIODO <= end.year) %>%
               group_by(ESTACION, DIA) %>%
               summarise(CANTIDAD_PASOS = sum(CANTIDAD_PASOS)))
  if(normalize) {
    t <- t %>%
      group_by(ESTACION) %>%
      mutate(CANTIDAD_PASOS = round(
        (CANTIDAD_PASOS - min(CANTIDAD_PASOS)) / (max(CANTIDAD_PASOS) - min(CANTIDAD_PASOS)), 3))
  }
  t <- t %>% arrange(ESTACION, DIA)
  p <- ggplot(t, aes(x = factor(DIA, level = c('DOMINGO', 'LUNES',  'MARTES', 
                                               'MIERCOLES',  'JUEVES', 'VIERNES', 
                                               'SABADO')),
                     y = ESTACION, 
                     fill = CANTIDAD_PASOS)) +
    geom_tile() +
    geom_text(aes(label = CANTIDAD_PASOS), size = 4) +
    scale_fill_gradient(low = 'white', high = 'orange') +
    scale_x_discrete(expand = c(0, 0)) + 
    scale_y_discrete(expand = c(0, 0)) +
    labs(x = '', y = '') +
    coord_equal() +
    theme_bw() 
}

hourly.breakdown <- function(df, conditions) {
  #' Traffic volume broken down by hour and vehicle type.
  #' 
  #' @param df Dataframe with toll booth name, vehicle type and volume, and time.
  #' @param conditions Set of filtering conditions to apply.
  #' @return A ggplot2 object containing the line chart.
  #' @example 
  #' hourly.breakdown(df)
  
  aggregate.by.hour_ <- function(df, amount.of.years) {
    return(df %>%
             group_by(TIPO_VEHICULO, HORA) %>%
             summarise(CANTIDAD_PASOS = sum(CANTIDAD_PASOS)) %>%
             mutate(CANTIDAD_PASOS = CANTIDAD_PASOS / (amount.of.years * 365.25 / 7))
    )
  }
  
  t <- aggregate.by.hour_(df[conditions,], length(unique(df$PERIODO)))
  p <- ggplot(data = t, aes(x = format(strptime(HORA,"%H:%M:%S"),'%H'), 
                            y = CANTIDAD_PASOS, group = TIPO_VEHICULO)) +
    labs(x = 'HORA') +
    geom_line(aes(linetype = TIPO_VEHICULO, color = TIPO_VEHICULO)) +
    theme_bw() 
}