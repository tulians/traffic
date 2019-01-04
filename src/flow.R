# Traffic flow analysis in AUSA toll booths.
# Julián Ailán - jailan@itba.edu.ar
# ITBA - 2018/2019
# Definition of methods used in the notebook.

library(zoo)
library(xts)
library(png)
library(plyr)
library(dplyr)
library(ggalt)
library(Hmisc)
library(shiny)
library(seqinr)
library(scales)
library(stringr)
library(ggplot2)
library(leaflet)
library(forecast)
library(lazyeval)
library(gganimate)
library(tidyverse)
library(lubridate)

traffic.volume.heatmap <- function(start.year, 
                                   end.year = start.year, 
                                   normalize = T) {
  #' Heatmap with the volume of traffic at a certain moment of time.
  #' 
  #' @param start.year First year to take into account when building the 
  #' heatmap (inclusive).
  #' @param end.year Last year to take into account when building the heatmap 
  #' (inclusive).
  #' @param normalize Normalize values in each cell to [0, 1] range.
  #' @return A ggplot2 object containing the heatmap.
  #' @example 
  #' traffic.volume.heatmap(2008, 2009)

  features <- c('toll.booth', 'day.name', 'amount', 'Y')
  t <- df[features]; rm(features)
  t <- rbind(t %>%
               filter(Y >= start.year & Y <= end.year) %>%
               group_by(toll.booth, day.name) %>%
               summarise(amount = sum(amount)))
  if(normalize) {
    t <- t %>%
      group_by(toll.booth) %>%
      mutate(amount = round(
        (amount - min(amount)) / 
          (max(amount) - min(amount)), 3))
  }
  t <- t %>% arrange(toll.booth, day.name)
  p <- ggplot(t, aes(x = factor(day.name, level = c('
                                                    DOMINGO', 'LUNES', 'MARTES', 
                                                    'MIERCOLES', 'JUEVES', 
                                                    'VIERNES', 'SABADO')),
                     y = toll.booth, 
                     fill = amount)) +
    geom_tile() +
    geom_text(aes(label = amount), size = 4) +
    scale_fill_gradient(low = 'white', high = 'orange') +
    scale_x_discrete(expand = c(0, 0)) + 
    scale_y_discrete(expand = c(0, 0)) +
    labs(x = '', y = '') +
    coord_equal() +
    theme_bw() 
}

custom.agg <- function(df, amount.of.years, ...) {
  #' Returns an estimated daily average of vehicles for a custom breakdown.
  #' 
  #'  @param df Dataframe with traffic information.
  #'  @param amount.of.years Number of years to take into account for the daily
  #'  average estimation.
  #'  @param ... Columns to use in grouping.
  #'  @return A tibble with the estimated amount of vehicles for a given group
  #'  of columns.
  #'  @example custom.agg(
  #'       df[(df$toll.booth == 'RETIRO'),], 11, 'FORMA_PAGO', 'HORA'
  #'  )
  return(df %>%
           group_by_(...) %>%
           summarise(amount = sum(amount)) %>%
           mutate(amount = amount / 
                    (amount.of.years * 365.25 / 7))
  )
}