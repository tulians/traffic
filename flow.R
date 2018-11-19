# Traffic flow analysis in AUSA toll booths.
# Julián Ailán - jailan@itba.edu.ar
# ITBA - 2018/2019

rm(list = ls()); gc();
library(dplyr)

setwd('~/Documents/traffic/')
source('utils.R')

#### Input data ####
df <- standarize.criteria()

#### Data wrangling ####
df <- transform.values(df, './datasets/traffic.csv')

#### Perform EDA on the traffic dataset ####
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
  
  differences <- vector('list', length(years) - 1); i <- 1
  for(yr in years) {
    if(yr == 2018) { break }
    traffic.A <- df[which(df$PERIODO == yr & conditions), ]
    traffic.B <- df[which(df$PERIODO == (yr + 1) & conditions), ]
    traffic.A.by.hour <- traffic.A %>%
      group_by(HORA) %>%
      summarise(amount.of.cars = sum(CANTIDAD_PASOS))
    traffic.B.by.hour <- traffic.B %>%
      group_by(HORA) %>%
      summarise(amount.of.cars = sum(CANTIDAD_PASOS))
    differences[[i]] <- (traffic.B.by.hour$amount.of.cars - 
                         traffic.A.by.hour$amount.of.cars)
    i <- i + 1
  }
  return(differences)
}

years <- unique(df$PERIODO)
conditions <- (df$ESTACION == 'ALBERDI' 
               & df$FORMA_PAGO == 'INFRACCION' 
               & df$TIPO_VEHICULO == 'PESADO')
differences <- YoY.diff(years, conditions)
boxplot(differences, las = 0,
        names = c('2009-2008', '2010-2009', '2011-2010', '2012-2011',
                  '2013-2012', '2014-2013', '2015-2014', '2016-2015',
                  '2017-2016', '2018-2017'),
        xlab = 'YoY difference', 
        ylab = 'Number of cars')
