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
  
  # Normalizes the format of the time columns.
  to_std_time_format <- function(d) {
    one.digit <- grep('^\\d$', d)
    two.digits <- grep('^\\d{2}$', d)
    five.digits <- grep('^\\d:00:00$', d)
    extra.text <- grep('0 days \\d{2}:00:00', d)
    midnight <- grep('24:00:00', d)
    
    if(length(one.digit)) {
      d[one.digit] <- paste('0', d[one.digit], ':00:00', sep = '')
    }
    if(length(two.digits)) {
      d[two.digits] <- paste(d[two.digits], ':00:00', sep = '')
    }
    if(length(five.digits)) {
      d[five.digits] <- paste('0', d[five.digits], sep = '')
    }
    if(length(extra.text)) {
      d[extra.text] <- str_sub(d[extra.text], -8)
    }
    if(length(midnight)) {
      d[midnight] <- paste('00:00:00')
    }
    
    return(d)
  }
  
  setwd('~/Documents/traffic/')
  df <- standardize.columns.and.merge_()
  df <- df %>% as_tibble() %>% mutate(
    toll.booth = case_when(
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
    day.name = case_when(
      DIA == 'Lunes' ~ 'LUNES',
      DIA == 'Martes' ~ 'MARTES',
      DIA == 'Miercoles' ~ 'MIERCOLES',
      DIA == 'Jueves' ~ 'JUEVES',
      DIA == 'Viernes' ~ 'VIERNES',
      DIA == 'Sabado' ~ 'SABADO',
      DIA == 'Domingo' ~ 'DOMINGO',
      TRUE ~ as.character(DIA)
    ),
    vehicle.type = case_when(
      TIPO_VEHICULO == 'Liviano' ~ 'LIVIANO',
      TIPO_VEHICULO == 'Pesado' ~ 'PESADO',
      TRUE ~ as.character(TIPO_VEHICULO)
    ), 
    lat = case_when(
      toll.booth == 'ALBERDI' ~ -34.6448027,
      toll.booth == 'AVELLANEDA' ~ -34.6482732,
      toll.booth == 'DELLEPIANE' ~ -34.6504678,
      toll.booth == 'ILLIA' ~ -34.5752543,
      toll.booth == 'RETIRO' ~ -34.5752543,
      toll.booth == 'SARMIENTO' ~ -34.5674364,
      toll.booth == 'SALGUERO' ~ -34.5717106
    ),
    long = case_when(
      toll.booth == 'ALBERDI' ~ -58.4920542,
      toll.booth == 'AVELLANEDA' ~ -58.4781064,
      toll.booth == 'DELLEPIANE' ~ -58.4656122,
      toll.booth == 'ILLIA' ~ -58.3921129,
      toll.booth == 'RETIRO' ~ -58.3921129,
      toll.booth == 'SARMIENTO' ~ -58.4079902,
      toll.booth == 'SALGUERO' ~ -58.4003948
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
    vehicle.type = as.factor(vehicle.type),
    payment.method = as.factor(FORMA_PAGO),
    toll.booth = as.factor(toll.booth),
    day.name = as.factor(day.name),
    amount = CANTIDAD_PASOS
  )
  
  df <- df %>% as_tibble() %>% mutate_at(
    c('HORA', 'HORA_FIN'), to_std_time_format)
  df <- df %>% mutate(
    start.hour = as.factor(HORA),
    end.hour = as.factor(HORA_FIN)
  )
  
  df[df$PERIODO < 2014,] <- arrange(df[df$PERIODO < 2014,], FECHA)
  df[df$PERIODO == 2018,] <- df[df$PERIODO == 2018,] %>% arrange(M, D)
  df[df$PERIODO == 2018, c('M', 'D')] <-
    swap_if_(df[df$PERIODO == 2018, c('M', 'D')]$D %in% c(1, 2, 3) & 
               df[df$PERIODO == 2018, c('M', 'D')]$M %in% c(10, 11, 12),
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

  drops <- c('FECHA', 'PERIODO', 'CANTIDAD_PASOS',
             'FORMA_PAGO', 'TIPO_VEHICULO', 'ESTACION',
             'HORA', 'HORA_FIN', 'DIA')
  df <- df[, !(names(df) %in% drops)]
  
  write.csv(df, file = output.file, row.names = F)
}
