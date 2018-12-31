# Feature engineering and data wrangling.
# Julián Ailán - jailan@itba.edu.ar
# ITBA - 2018/2019

standardize.columns.and.merge_ <- function() {
  #' The dataset is composed of 11 files, consisting on samples from 2008 to
  #' 2018. Not all of them have the same column names, nor the same column
  #' order. This function standardizes their format, and merges them all in a
  #' single .csv file.
  
  path <- './datasets/flujo-vehicular-por-unidades-de-peaje-ausa/'
  traffic.2012.file <- paste(path, 'flujo-vehicular-2012.csv', sep = '')
  traffic.2014.file <- paste(path, 'flujo-vehicular-2014.csv', sep = '')
  traffic.2016.file <- paste(path, 'flujo-vehicular-2016.csv', sep = '')
  traffic.2017.file <- paste(path, 'flujo-vehicular-2017.csv', sep = '')
  traffic.2018.file <- paste(path, 'flujo-vehicular-2018.csv', sep = '')
  traffic.2012 <-
    read.csv(
      traffic.2012.file,
      sep = ';',
      header = T,
      stringsAsFactors = T
    )
  traffic.2014 <-
    read.csv(
      traffic.2014.file,
      sep = ';',
      header = T,
      stringsAsFactors = T
    )
  traffic.2016 <-
    read.csv(
      traffic.2016.file,
      sep = ';',
      header = T,
      stringsAsFactors = T
    )
  traffic.2017 <-
    read.csv(
      traffic.2017.file,
      sep = ';',
      header = T,
      stringsAsFactors = T
    )
  traffic.2018 <-
    read.csv(
      traffic.2018.file,
      sep = ',',
      header = T,
      stringsAsFactors = T
    )
  traffic.2012 <-
    traffic.2012[c(
      'PERIODO',
      'FECHA',
      'DIA',
      'HORA',
      'HORA_FIN',
      'ESTACION',
      'TIPOVEHICULO',
      'FORMA_PAGO',
      'CANTIDAD_PASOS'
    )]
  traffic.2014 <-
    traffic.2014[c(
      'PERIODO',
      'FECHA',
      'DIA',
      'HORA',
      'HORAFIN',
      'ESTACION',
      'TIPOVEHICULO',
      'FORMAPAGO',
      'CANTIDADPASOS'
    )]
  traffic.2016 <-
    traffic.2016[c(
      'PERIODO',
      'FECHA',
      'DIA',
      'HORA',
      'HORA_FIN',
      'ESTACION',
      'TIPO_VEHICULO',
      'FORMA_PAGO',
      'CANTIDAD_PASOS'
    )]
  traffic.2017 <-
    traffic.2017[c(
      'PERIODO',
      'FECHA',
      'DIA',
      'HORA',
      'HORA_FIN',
      'ESTACION',
      'TIPO_VEHICULO',
      'FORMA_PAGO',
      'CANTIDAD_PASOS'
    )]
  traffic.2018 <-
    traffic.2018[c(
      'periodo',
      'fecha',
      'dia',
      'hora',
      'hora_fin',
      'estacion',
      'tipo_vehiculo',
      'forma_pago',
      'cantidad_pasos'
    )]
  write.table(traffic.2012,
              file = traffic.2012.file,
              row.names = F,
              sep = ';')
  write.table(traffic.2014,
              file = traffic.2014.file,
              row.names = F,
              sep = ';')
  write.table(traffic.2016,
              file = traffic.2016.file,
              row.names = F,
              sep = ';')
  write.table(traffic.2017,
              file = traffic.2017.file,
              row.names = F,
              sep = ';')
  write.table(traffic.2018,
              file = traffic.2018.file,
              row.names = F,
              sep = ';')
  rm(
    traffic.2012,
    traffic.2012.file,
    traffic.2014,
    traffic.2014.file,
    traffic.2016,
    traffic.2016.file,
    traffic.2017,
    traffic.2017.file,
    traffic.2018,
    traffic.2018.file
  )
  
  # Merged all .csv files into one using awk rather than R packages.
  system(
    'awk "FNR==1 && NR!=1{next;}{print}" ./datasets/flujo-vehicular-por-unidades-de-peaje-ausa/*.csv > ./datasets/merged.csv'
  )
  return(read.csv(
    './datasets/merged.csv',
    sep = ';',
    header = T,
    stringsAsFactors = T
  ))
}

standardize.values <- function(output.file = './datasets/traffic.csv') {
  #' Among categorical attributes, not all of them have the same value for the
  #' same concept, fox example you could find the same toll name writen in 
  #' all caps and then all lowers. This function standardizes that, and creates
  #' a new dataset.
  #' 
  #' @param output.file Path and name of the file which will result of values 
  #' transformation.
  #' @return The standardized dataframe.

  # Adapted from `swap_if` in 
  # https://github.com/tidyverse/dplyr/issues/2149#issuecomment-258916706
  # The solution presented there has a bug in the generation of out_y, as the
  # condition should not be negated.
  swap_if_ <- function(cond, x, y) {
    # TODO(tulians): avoid using the dataframe.
    out_x <- ifelse(cond, y, x)
    out_y <- ifelse(cond, x, y)
    setNames(tibble(out_x, out_y), names(c('M', 'D')))
  }
  
  setwd('~/Documents/traffic/')
  df <- standardize.columns.and.merge_()
  df <- df %>% as_tibble() %>% mutate(
    ESTACION = case_when(
      ESTACION %in% c('ALB', 'Alberdi') ~ 'ALBERDI',
      ESTACION %in% c('AVE', 'Avellaneda') ~ 'AVELLANEDA',
      ESTACION %in% c(
        'DEC',
        'DEL',
        'DELLEPIANE CENTRO',
        'DELLEPIANE LINIERS',
        'Dellepiane Centro',
        'Dellepiane Liniers'
      ) ~ 'DELLEPIANE',
      ESTACION %in% c('ILL', 'Illia') ~ 'ILLIA',
      ESTACION %in% c('RET', 'Retiro') ~ 'RETIRO',
      ESTACION %in% c('SAL', 'Salguero') ~ 'SALGUERO',
      ESTACION %in% c('SAR', 'Sarmiento') ~ 'SARMIENTO',
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
      ESTACION == 'ALBERDI' ~ -34.6448027,
      ESTACION == 'AVELLANEDA' ~ -34.6482732,
      ESTACION == 'DELLEPIANE' ~ -34.6504678,
      ESTACION == 'ILLIA' ~ 0,
      ESTACION == 'RETIRO' ~ -34.5752543,
      ESTACION == 'SARMIENTO' ~ -34.5674364,
      ESTACION == 'SALGUERO' ~ -34.5717106
    ),
    LONG = case_when(
      ESTACION == 'ALBERDI' ~ -58.4920542,
      ESTACION == 'AVELLANEDA' ~ -58.4781064,
      ESTACION == 'DELLEPIANE' ~ -58.4656122,
      ESTACION == 'ILLIA' ~ 0,
      ESTACION == 'RETIRO' ~ -58.3921129,
      ESTACION == 'SARMIENTO' ~ -58.4079902,
      ESTACION == 'SALGUERO' ~ -58.4003948
    ),
    FECHA = case_when(
      PERIODO < 2014 ~ as.Date(
        strptime(as.character(FECHA), '%m/%d/%Y'), format = '%Y-%m-%d'),
      PERIODO >= 2014 & PERIODO < 2016 ~ as.Date(
        strptime(as.character(FECHA), '%d/%m/%Y'), format = '%Y-%m-%d'),
      PERIODO >= 2016 ~ as.Date(
        strptime(as.character(FECHA), '%Y-%m-%d'), format = '%Y-%m-%d')
    ),
    Y = lubridate::year(FECHA),
    M = lubridate::month(FECHA),
    D = lubridate::day(FECHA),
    TIPO_VEHICULO = as.factor(TIPO_VEHICULO),
    ESTACION = as.factor(ESTACION),
    HORA_FIN = as.factor(HORA_FIN),
    HORA = as.factor(HORA),
    DIA = as.factor(DIA)
  )
  
  df[df$PERIODO < 2014,] <- arrange(df[df$PERIODO < 2014,], FECHA)
  df[df$PERIODO == 2018, c('M', 'D')] <-
    swap_if_(df[df$PERIODO == 2018, c('M', 'D')]$D %in% c(1, 2, 3),
             df[df$PERIODO == 2018, c('M', 'D')]$M,
             df[df$PERIODO == 2018, c('M', 'D')]$D)
  
  df <- df %>% mutate(
    Q = case_when(
      M %in% c(1, 2, 3) ~ 1,
      M %in% c(4, 5, 6) ~ 2,
      M %in% c(7, 8, 9) ~ 3,
      M %in% c(10, 11, 12) ~ 4
    )
  )

  drops <- c('FECHA', 'PERIODO')
  df <- df[, !(names(df) %in% drops)]
  
  write.csv(df, file = output.file, row.names = F)
}
