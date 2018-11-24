# Traffic flow analysis in AUSA toll booths.
# Julián Ailán - jailan@itba.edu.ar
# ITBA - 2018/2019

rm(list = ls()); gc();
library(dplyr)
library(forecast)

setwd('~/Documents/traffic/')
source('utils.R')

#### Input data ####
df <- standarize.criteria()

#### Data wrangling ####
df <- transform.values(df, './datasets/traffic.csv')

#### Increase in traffic comparing consecutive years ####

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
#### Can a given year traffic be predicted by the previous year traffic? ####
t <- rbind(
  df[which(df$PERIODO == 2016), ] %>%
    group_by(FECHA) %>%
    summarise(CANTIDAD_PASOS = sum(CANTIDAD_PASOS)),
  df[which(df$PERIODO == 2017), ] %>%
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
