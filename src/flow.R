# Traffic flow analysis in AUSA toll booths.
# Julián Ailán - jailan@itba.edu.ar
# ITBA - 2018/2019

rm(list = ls()); gc();
library(dplyr)
library(forecast)
library(ggplot2)

setwd('~/Documents/traffic/')
source('utils.R')

#### Input data ####
df <- standarize.criteria()

#### Data wrangling ####
df <- transform.values(df, './datasets/traffic.csv')

#### Increase in traffic comparing consecutive years. ####

aggregate.by.hour_ <- function(df) {
  return(df %>%
           group_by(HORA) %>%
           summarise(cars.passing.by = sum(CANTIDAD_PASOS)))
}

YoY.diff <- function(period, conditions = TRUE) {
  #' Difference in number of cars between an year X and year X - 1.
  #' 
  #' @param period The list of years to be considered to compute differences.
  #' @param conditions List of dataframe attributes and associated values to use
  #' as filtering conditions.
  #' @return List of differences between two consecutive years, aggregated by
  #' hour of day.
  #' @example 
  #' YoY.diff(c(2008, 2009, 2010), df$attr == TRUE)
  
  differences <- vector('list', length(period) - 1); i <- 1
  for(prd in period) {
    if(prd == tail(years, n = 1)) { break }
    traffic.A <- df[which(df$PERIODO == prd & conditions), ]
    traffic.B <- df[which(df$PERIODO == (prd + 1) & conditions), ]
    traffic.A.by.hour <- aggregate.by.hour_(traffic.A)
    traffic.B.by.hour <- aggregate.by.hour_(traffic.B)
    differences[[i]] <- (traffic.B.by.hour$cars.passing.by - 
                         traffic.A.by.hour$cars.passing.by)
    i <- i + 1
  }
  rm(traffic.A, traffic.B, prd, period, i)
  return(differences)
}

years <- unique(df$PERIODO)
conditions <- (df$ESTACION == 'ALBERDI')
differences <- YoY.diff(years, conditions)
boxplot(differences, las = 0,
        names = c('2009-2008', '2010-2009', '2011-2010', '2012-2011',
                  '2013-2012', '2014-2013', '2015-2014', '2016-2015',
                  '2017-2016', '2018-2017'),
        xlab = 'YoY difference', 
        ylab = 'Number of cars')
rm(differences, conditions, aggregate.by.hour_, YoY.diff)

#### Can a given day traffic be predicted by the previous days traffic? ####
t <- rbind(
  df[which(df$PERIODO >= 2015 & df$PERIODO <= 2018), ] %>%
    group_by(FECHA) %>%
    summarise(CANTIDAD_PASOS = sum(CANTIDAD_PASOS)))
# Correct how rows are ordered by date.
t <- t %>%
  mutate(FECHA = as.Date(FECHA, format = '%m/%d/%Y')) %>%
  arrange(FECHA)
# Transform it into time-series and forecast.
t.ts <- msts(t$CANTIDAD_PASOS, seasonal.periods = c(7, 365.25))
fit <- stlf(t.ts)
fc <- forecast(fit)
plot(fc)
t.ts.components <- decompose(t.ts)
plot(t.ts.components)

#### Heatmap with the volume of traffic at a certain moment of time. ####
traffic.volume.heatmap <- function(start.year, end.year = start.year, normalize = T) {
  #' Heatmap showing the volume of cars per toll booth.
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
plot(traffic.volume.heatmap(2015, 2016))

##### Traffic volume broken down by hour and vehicle type. ####
hourly.breakdown <- function(df, conditions) {
  #' Heatmap showing the volume of cars per toll booth.
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