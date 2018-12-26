# Feature engineering and data wrangling.
# Julián Ailán - jailan@itba.edu.ar
# ITBA - 2018/2019

standarize.criteria_ <- function() {
  #' The dataset is composed of 11 files, consisting on samples from 2008 to
  #' 2018. Not all of them have the same column names, nor the same column
  #' order. This function standardizes their format, and merges them all in a
  #' single .csv file.

  traffic.2012.file <- './datasets/flujo-vehicular-por-unidades-de-peaje-ausa/flujo-vehicular-2012.csv'
  traffic.2014.file <- './datasets/flujo-vehicular-por-unidades-de-peaje-ausa/flujo-vehicular-2014.csv'
  traffic.2016.file <- './datasets/flujo-vehicular-por-unidades-de-peaje-ausa/flujo-vehicular-2016.csv'
  traffic.2017.file <- './datasets/flujo-vehicular-por-unidades-de-peaje-ausa/flujo-vehicular-2017.csv'
  traffic.2018.file <- './datasets/flujo-vehicular-por-unidades-de-peaje-ausa/flujo-vehicular-2018.csv'
  traffic.2012 <- read.csv(traffic.2012.file, sep = ';', header = T, stringsAsFactors = T)
  traffic.2014 <- read.csv(traffic.2014.file, sep = ';', header = T, stringsAsFactors = T)
  traffic.2016 <- read.csv(traffic.2016.file, sep = ';', header = T, stringsAsFactors = T)
  traffic.2017 <- read.csv(traffic.2017.file, sep = ';', header = T, stringsAsFactors = T)
  traffic.2018 <- read.csv(traffic.2018.file, sep = ',', header = T, stringsAsFactors = T)
  traffic.2012 <- traffic.2012[c('PERIODO', 'FECHA', 'DIA', 'HORA', 'HORA_FIN', 'ESTACION', 'TIPOVEHICULO', 'FORMA_PAGO', 'CANTIDAD_PASOS')]
  traffic.2014 <- traffic.2014[c('PERIODO', 'FECHA', 'DIA', 'HORA', 'HORAFIN', 'ESTACION', 'TIPOVEHICULO', 'FORMAPAGO', 'CANTIDADPASOS')]
  traffic.2016 <- traffic.2016[c('PERIODO', 'FECHA', 'DIA', 'HORA', 'HORA_FIN', 'ESTACION', 'TIPO_VEHICULO', 'FORMA_PAGO', 'CANTIDAD_PASOS')]
  traffic.2017 <- traffic.2017[c('PERIODO', 'FECHA', 'DIA', 'HORA', 'HORA_FIN', 'ESTACION', 'TIPO_VEHICULO', 'FORMA_PAGO', 'CANTIDAD_PASOS')]
  traffic.2018 <- traffic.2018[c('periodo', 'fecha', 'dia', 'hora', 'hora_fin', 'estacion', 'tipo_vehiculo', 'forma_pago', 'cantidad_pasos')]
  write.table(traffic.2012, file = traffic.2012.file, row.names = F, sep = ';')
  write.table(traffic.2014, file = traffic.2014.file, row.names = F, sep = ';')
  write.table(traffic.2016, file = traffic.2016.file, row.names = F, sep = ';')
  write.table(traffic.2017, file = traffic.2017.file, row.names = F, sep = ';')
  write.table(traffic.2018, file = traffic.2018.file, row.names = F, sep = ';')
  rm(traffic.2012, traffic.2012.file, traffic.2014, traffic.2014.file, 
     traffic.2016, traffic.2016.file, traffic.2017, traffic.2017.file, 
     traffic.2018, traffic.2018.file)
  
  # Merged all .csv files into one using awk rather than R packages.
  system('awk "FNR==1 && NR!=1{next;}{print}" ./datasets/flujo-vehicular-por-unidades-de-peaje-ausa/*.csv > ./datasets/merged.csv')
  return(read.csv('./datasets/merged.csv', sep = ';', header = T, stringsAsFactors = T))
}

transform.values <- function(output.file = './datasets/traffic.csv') {
  #' Among categorical attributes, not all of them have the same value for the
  #' same concept, fox example you could find the same toll name writen in 
  #' all caps and then all lowers. This function standardizes that, and creates
  #' a new dataset.
  #' 
  #' @param output.file Path and name of the file which will result of values 
  #' transformation.
  #' 
  #' @return The standardized dataframe.

  setwd('~/Documents/traffic/')
  df <- standarize.criteria_()
  df <- df %>% as_tibble() %>% mutate(
    ESTACION = case_when(
      ESTACION == 'ALB' ~ 'ALBERDI',
      ESTACION == 'Alberdi' ~ 'ALBERDI',
      ESTACION == 'AVE' ~ 'AVELLANEDA',
      ESTACION == 'Avellaneda' ~ 'AVELLANEDA',
      ESTACION == 'Dellepiane Centro' ~ 'DELLEPIANE CENTRO',
      ESTACION == 'Dellepiane Liniers' ~ 'DELLEPIANE LINIERS',
      ESTACION == 'ILL' ~ 'ILLIA',
      ESTACION == 'Illia' ~ 'ILLIA',
      ESTACION == 'RET' ~ 'RETIRO',
      ESTACION == 'Retiro' ~ 'RETIRO',
      ESTACION == 'SAL' ~ 'SALGUERO',
      ESTACION == 'Salguero' ~ 'SALGUERO',
      ESTACION == 'SAR' ~ 'SARMIENTO',
      ESTACION == 'Sarmiento' ~ 'SARMIENTO',
      TRUE ~ as.character(ESTACION)
    ),
    HORA = case_when(
      HORA == '0' ~ '00:00:00',
      HORA == '1' ~ '01:00:00',
      HORA == '2' ~ '02:00:00',
      HORA == '3' ~ '03:00:00',
      HORA == '4' ~ '04:00:00',
      HORA == '5' ~ '05:00:00',
      HORA == '6' ~ '06:00:00',
      HORA == '7' ~ '07:00:00',
      HORA == '8' ~ '08:00:00',
      HORA == '9' ~ '09:00:00',
      HORA == '10' ~ '10:00:00',
      HORA == '11' ~ '11:00:00',
      HORA == '12' ~ '12:00:00',
      HORA == '13' ~ '13:00:00',
      HORA == '14' ~ '14:00:00',
      HORA == '15' ~ '15:00:00',
      HORA == '16' ~ '16:00:00',
      HORA == '17' ~ '17:00:00',
      HORA == '18' ~ '18:00:00',
      HORA == '19' ~ '19:00:00',
      HORA == '20' ~ '20:00:00',
      HORA == '21' ~ '21:00:00',
      HORA == '22' ~ '22:00:00',
      HORA == '23' ~ '23:00:00',
      HORA == '0:00:00' ~ '00:00:00',
      HORA == '1:00:00' ~ '01:00:00',
      HORA == '2:00:00' ~ '02:00:00',
      HORA == '3:00:00' ~ '03:00:00',
      HORA == '4:00:00' ~ '04:00:00',
      HORA == '5:00:00' ~ '05:00:00',
      HORA == '6:00:00' ~ '06:00:00',
      HORA == '7:00:00' ~ '07:00:00',
      HORA == '8:00:00' ~ '08:00:00',
      HORA == '9:00:00' ~ '09:00:00',
      HORA == '0 days 00:00:00' ~ '00:00:00',
      HORA == '0 days 01:00:00' ~ '01:00:00',
      HORA == '0 days 02:00:00' ~ '02:00:00',
      HORA == '0 days 03:00:00' ~ '03:00:00',
      HORA == '0 days 04:00:00' ~ '04:00:00',
      HORA == '0 days 05:00:00' ~ '05:00:00',
      HORA == '0 days 06:00:00' ~ '06:00:00',
      HORA == '0 days 07:00:00' ~ '07:00:00',
      HORA == '0 days 08:00:00' ~ '08:00:00',
      HORA == '0 days 09:00:00' ~ '09:00:00',
      HORA == '0 days 10:00:00' ~ '10:00:00',
      HORA == '0 days 11:00:00' ~ '11:00:00',
      HORA == '0 days 12:00:00' ~ '12:00:00',
      HORA == '0 days 13:00:00' ~ '13:00:00',
      HORA == '0 days 14:00:00' ~ '14:00:00',
      HORA == '0 days 15:00:00' ~ '15:00:00',
      HORA == '0 days 16:00:00' ~ '16:00:00',
      HORA == '0 days 17:00:00' ~ '17:00:00',
      HORA == '0 days 18:00:00' ~ '18:00:00',
      HORA == '0 days 19:00:00' ~ '19:00:00',
      HORA == '0 days 20:00:00' ~ '20:00:00',
      HORA == '0 days 21:00:00' ~ '21:00:00',
      HORA == '0 days 22:00:00' ~ '22:00:00',
      HORA == '0 days 23:00:00' ~ '23:00:00',
      TRUE ~ as.character(HORA)
    ),
    HORA_FIN = case_when(
      HORA_FIN == '0' ~ '00:00:00',
      HORA_FIN == '1' ~ '01:00:00',
      HORA_FIN == '2' ~ '02:00:00',
      HORA_FIN == '3' ~ '03:00:00',
      HORA_FIN == '4' ~ '04:00:00',
      HORA_FIN == '5' ~ '05:00:00',
      HORA_FIN == '6' ~ '06:00:00',
      HORA_FIN == '7' ~ '07:00:00',
      HORA_FIN == '8' ~ '08:00:00',
      HORA_FIN == '9' ~ '09:00:00',
      HORA_FIN == '10' ~ '10:00:00',
      HORA_FIN == '11' ~ '11:00:00',
      HORA_FIN == '12' ~ '12:00:00',
      HORA_FIN == '13' ~ '13:00:00',
      HORA_FIN == '14' ~ '14:00:00',
      HORA_FIN == '15' ~ '15:00:00',
      HORA_FIN == '16' ~ '16:00:00',
      HORA_FIN == '17' ~ '17:00:00',
      HORA_FIN == '18' ~ '18:00:00',
      HORA_FIN == '19' ~ '19:00:00',
      HORA_FIN == '20' ~ '20:00:00',
      HORA_FIN == '21' ~ '21:00:00',
      HORA_FIN == '22' ~ '22:00:00',
      HORA_FIN == '23' ~ '23:00:00',
      HORA_FIN == '0:00:00' ~ '00:00:00',
      HORA_FIN == '1:00:00' ~ '01:00:00',
      HORA_FIN == '2:00:00' ~ '02:00:00',
      HORA_FIN == '3:00:00' ~ '03:00:00',
      HORA_FIN == '4:00:00' ~ '04:00:00',
      HORA_FIN == '5:00:00' ~ '05:00:00',
      HORA_FIN == '6:00:00' ~ '06:00:00',
      HORA_FIN == '7:00:00' ~ '07:00:00',
      HORA_FIN == '8:00:00' ~ '08:00:00',
      HORA_FIN == '9:00:00' ~ '09:00:00',
      HORA_FIN == '24:00:00' ~ '00:00:00',
      HORA_FIN == '0 days 00:00:00' ~ '00:00:00',
      HORA_FIN == '0 days 01:00:00' ~ '01:00:00',
      HORA_FIN == '0 days 02:00:00' ~ '02:00:00',
      HORA_FIN == '0 days 03:00:00' ~ '03:00:00',
      HORA_FIN == '0 days 04:00:00' ~ '04:00:00',
      HORA_FIN == '0 days 05:00:00' ~ '05:00:00',
      HORA_FIN == '0 days 06:00:00' ~ '06:00:00',
      HORA_FIN == '0 days 07:00:00' ~ '07:00:00',
      HORA_FIN == '0 days 08:00:00' ~ '08:00:00',
      HORA_FIN == '0 days 09:00:00' ~ '09:00:00',
      HORA_FIN == '0 days 10:00:00' ~ '10:00:00',
      HORA_FIN == '0 days 11:00:00' ~ '11:00:00',
      HORA_FIN == '0 days 12:00:00' ~ '12:00:00',
      HORA_FIN == '0 days 13:00:00' ~ '13:00:00',
      HORA_FIN == '0 days 14:00:00' ~ '14:00:00',
      HORA_FIN == '0 days 15:00:00' ~ '15:00:00',
      HORA_FIN == '0 days 16:00:00' ~ '16:00:00',
      HORA_FIN == '0 days 17:00:00' ~ '17:00:00',
      HORA_FIN == '0 days 18:00:00' ~ '18:00:00',
      HORA_FIN == '0 days 19:00:00' ~ '19:00:00',
      HORA_FIN == '0 days 20:00:00' ~ '20:00:00',
      HORA_FIN == '0 days 21:00:00' ~ '21:00:00',
      HORA_FIN == '0 days 22:00:00' ~ '22:00:00',
      HORA_FIN == '0 days 23:00:00' ~ '23:00:00',
      TRUE ~ as.character(HORA_FIN)
    ),
    DIA = case_when(
      DIA == 'Lunes' ~ 'LUNES',
      DIA == 'Martes' ~ 'MARTES',
      DIA == 'Miercoles' ~ 'MIERCOLES',
      DIA == 'Jueves' ~ 'JUEVES',
      DIA == 'Viernes' ~ 'VIERNES',
      DIA == 'Sabado' ~ 'SABADO',
      DIA == 'Domingo' ~ 'DOMINGO',
      TRUE ~ as.character(DIA)
    ),
    TIPO_VEHICULO = case_when(
      TIPO_VEHICULO == 'Liviano' ~ 'LIVIANO',
      TIPO_VEHICULO == 'Pesado' ~ 'PESADO',
      TRUE ~ as.character(TIPO_VEHICULO)
    ),
    LAT = case_when(
      ESTACION == 'ALBERDI' ~ -34.64480276487647,
      ESTACION == 'AVELLANEDA' ~ -34.648273239205025,
      ESTACION == 'DEL' ~ -34.648001,
      ESTACION == 'ILLIA' ~ 0,
      ESTACION == 'RETIRO' ~ -34.5752543,
      ESTACION == 'SARMIENTO' ~ 0,
      ESTACION == 'DEC' ~ 0,
      ESTACION == 'SALGUERO' ~ 0,
      ESTACION == 'DELLEPIANE CENTRO' ~ -34.648001,
      ESTACION == 'DELLEPIANE LINIERS' ~ -34.648001
    ),
    LONG = case_when(
      ESTACION == 'ALBERDI' ~ -58.49205422072362,
      ESTACION == 'AVELLANEDA' ~ -58.478106424442785,
      ESTACION == 'DEL' ~ -58.4645727,
      ESTACION == 'ILLIA' ~ 0,
      ESTACION == 'RETIRO' ~ -58.3921129,
      ESTACION == 'SARMIENTO' ~ 0,
      ESTACION == 'DEC' ~ 0,
      ESTACION == 'SALGUERO' ~ 0,
      ESTACION == 'DELLEPIANE CENTRO' ~ -58.4645727,
      ESTACION == 'DELLEPIANE LINIERS' ~ -58.4645727
    ),
    # (2008, 2009, 2010, 2011, 2012, 2013) mm/dd/yyyy
    # (2014, 2015) dd/mm/yyyy
    # (2016, 2017, 2018) yyyy-mm-dd
    FECHA = case_when(
      PERIODO < 2014 ~ as.Date(
        strptime(as.character(FECHA), "%m/%d/%Y"), format = "%Y-%m-%d"),
      PERIODO >= 2014 & PERIODO < 2016 ~ as.Date(
        strptime(as.character(FECHA), "%d/%m/%Y"), format = "%Y-%m-%d"),
      PERIODO >= 2016 ~ as.Date(FECHA, format = "%Y-%m-%d")
    ),
    ESTACION = as.factor(ESTACION),
    HORA = as.factor(HORA),
    HORA_FIN = as.factor(HORA_FIN),
    DIA = as.factor(DIA),
    TIPO_VEHICULO = as.factor(TIPO_VEHICULO)
  )
  write.csv(df, file = output.file, row.names = F)
}
