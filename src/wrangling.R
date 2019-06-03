# Feature engineering and data wrangling.
# Julián Ailán - jailan@itba.edu.ar
# ITBA - 2018/2019

#' The dataset is composed of 12 files, consisting on observations from 2008 
#' to 2019. Not all of them have the same column names, nor the same column
#' order. This function standardizes their format, and merges them all in a
#' single .csv file.
#'
#' @param intermediate.file.path Path to the file that hosts data with
#' standardized header names.
#' @return Nothing is explicitly returned.
join.traffic.files <- function(
  intermediate.file.path = './datasets/sources/merged.csv'
) {
  require(data.table)
  #' Generate the file paths automatically, given that each year a new file is
  #' created and may require formating.
  common.path <- './datasets/sources/traffic-v2/flujo-vehicular-x.csv'
  years <- 2008:2019
  file.paths <- unlist (
    lapply (
      years, 
      function (year) { gsub('x', year, common.path) }
    )
  )
  #' Read files in bulk into `data.table`s.
  files <- lapply (
    file.paths, 
    fread,
    colClasses = 'character'
  )
  #' Column format to use.
  columns <- c('PERIODO', 'FECHA', 'DIA', 'HORA', 'HORA_FIN', 'ESTACION', 
               'TIPO_VEHICULO', 'FORMA_PAGO', 'CANTIDAD_PASOS', 'HORAFIN',
               'TIPOVEHICULO', 'FORMAPAGO', 'CANTIDADPASOS', 'HORA_INICIO')
  underscores <- c('PERIODO', 'FECHA', 'DIA', 'HORA', 'HORA_FIN', 'ESTACION', 
                   'TIPO_VEHICULO', 'FORMA_PAGO', 'CANTIDAD_PASOS')
  #' Make sure that all non-standard files use the same column name format.
  files <- lapply (
    files,
    function (f) {
      f <- f[, # Affects all rows.
             tolower(names(f)) %in% tolower(columns), 
             with = FALSE]
      setnames(f, 
               old = names(f), 
               new = underscores)
    }
  )
  #' Generate a unified intermediate file with standardized header names.
  intermediate.file <- Reduce (
    function(...) merge(..., all = TRUE),
    files
  )
  fwrite(
    intermediate.file, 
    file = intermediate.file.path
  )
  rm(common.path, years, file.paths, files, 
     columns, underscores, intermediate.file)
}

#' Among categorical attributes, not all of them have the same value for the
#' same concept, fox example you could find the same toll name writen in 
#' all caps and then all lowers. This function standardizes that, and creates
#' a new dataset.
#' 
#' @param output.file Path and name of the file which will result of values 
#' transformation.
#' @return The standardized dataframe.
standardize.traffic <- function(
  input.file = './datasets/sources/merged.csv',
  output.file = './datasets/traffic.csv') {
  require(dplyr, data.table)
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
  
  # Data wrangling for the traffic dataset.
  setwd('~/Documents/traffic/')
  join.traffic.files()
  df <- fread(input.file)
  df <- df %>% as_tibble() %>% mutate(
    toll.booth.name = case_when(
      ESTACION %in% c('ALB', 'Alberdi') ~ 'Alberti',
      ESTACION %in% c('AVE', 'Avellaneda') ~ 'Avellaneda',
      ESTACION %in% c(
        'DEC',
        'DEL',
        'DELLEPIANE CENTRO',
        'DELLEPIANE LINIERS',
        'Dellepiane Centro',
        'Dellepiane Liniers',
        'DELLEPIANE LINIERSLEPIANE CENTRO'
      ) ~ 'Dellepiane',
      ESTACION %in% c(
        'ILL', 
        'Illia', 
        'RET', 
        'Retiro'
      ) ~ 'Retiro',
      ESTACION %in% c('SAL', 'Salguero') ~ 'Salguero',
      ESTACION %in% c('SAR', 'Sarmiento') ~ 'Sarmiento',
      TRUE ~ as.character(ESTACION)
    ),
    day.name = case_when(
      DIA == 'Lunes' ~ 'Monday',
      DIA == 'Martes' ~ 'Tuesday',
      DIA == 'Miercoles' ~ 'Wednesday',
      DIA == 'Jueves' ~ 'Thursday',
      DIA == 'Viernes' ~ 'Friday',
      DIA == 'Sabado' ~ 'Saturday',
      DIA == 'Domingo' ~ 'Sunday',
      TRUE ~ as.character(DIA)
    ),
    vehicle.type = case_when(
      TIPO_VEHICULO == 'Motos' ~ 'Motorbike',
      TIPO_VEHICULO %like% 'Liviano%' ~ 'Car',
      TIPO_VEHICULO %like% 'Pesado%' ~ 'Truck',
      TIPO_VEHICULO %in% c(
        'N/D', 
        'ND'
      ) ~ 'Non-determined',
      TIPO_VEHICULO %like% 'Cobro doble para%' ~ 'Non-frequent',
      TRUE ~ as.character(TIPO_VEHICULO)
    ), 
    lat = case_when(
      toll.booth.name == 'Alberti' ~ -34.6448027,
      toll.booth.name == 'Avellaneda' ~ -34.6482732,
      toll.booth.name == 'Dellepiane' ~ -34.6504678,
      toll.booth.name == 'Retiro' ~ -34.5752543,
      toll.booth.name == 'Sarmiento' ~ -34.5674364,
      toll.booth.name == 'Salguero' ~ -34.5717106
    ),
    long = case_when(
      toll.booth.name == 'Alberti' ~ -58.4920542,
      toll.booth.name == 'Avellaneda' ~ -58.4781064,
      toll.booth.name == 'Dellepiane' ~ -58.4656122,
      toll.booth.name == 'Retiro' ~ -58.3921129,
      toll.booth.name == 'Sarmiento' ~ -58.4079902,
      toll.booth.name == 'Salguero' ~ -58.4003948
    ),
    booths = case_when(
      toll.booth.name == 'Alberti' ~ 5,
      toll.booth.name == 'Avellaneda' ~ 33,
      toll.booth.name == 'Dellepiane' ~ 16,
      toll.booth.name == 'Retiro' ~ 29,
      toll.booth.name == 'Sarmiento' ~ 8,
      toll.booth.name == 'Salguero' ~ 8
    ),
    date_ = case_when(
      PERIODO < 2014 ~ as.Date(
        strptime(as.character(FECHA), '%m/%d/%Y'), format = '%Y-%m-%d'),
      PERIODO >= 2014 & PERIODO < 2016 ~ as.Date(
        strptime(as.character(FECHA), '%d/%m/%Y'), format = '%Y-%m-%d'),
      PERIODO >= 2016 ~ as.Date(
        strptime(as.character(FECHA), '%Y-%m-%d'), format = '%Y-%m-%d')
    ),
    year_ = lubridate::year(date_),
    month_ = lubridate::month(date_),
    day_ = lubridate::day(date_),
    vehicle.type = as.factor(vehicle.type),
    payment.method = as.factor(FORMA_PAGO),
    toll.booth.name = as.factor(toll.booth.name),
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
  df[df$PERIODO == 2018,] <- df[df$PERIODO == 2018,] %>% arrange(month_, day_)
  df[df$PERIODO == 2018, c('month_', 'day_')] <-
    swap_if_(
      df[df$PERIODO == 2018, c('month_', 'day_')]$day_ %in% c(1, 2, 3) & 
        df[df$PERIODO == 2018, c('month_', 'day_')]$month_ %in% c(10, 11, 12),
      df[df$PERIODO == 2018, c('month_', 'day_')]$month_,
      df[df$PERIODO == 2018, c('month_', 'day_')]$day_)
  
  df <- df %>% mutate(
    quarter_ = case_when(
      month_ %in% c(1, 2, 3) ~ 1,
      month_ %in% c(4, 5, 6) ~ 2,
      month_ %in% c(7, 8, 9) ~ 3,
      month_ %in% c(10, 11, 12) ~ 4
    )
  )
  
  drops <- c('FECHA', 'PERIODO', 'CANTIDAD_PASOS',
             'FORMA_PAGO', 'TIPO_VEHICULO', 'ESTACION',
             'HORA', 'HORA_FIN', 'DIA')
  df <- df[, !(names(df) %in% drops)]
  
  fwrite(
    df, 
    file = output.file
  )
  file.remove(input.file)
  rm(df, to_std_time_format, swap_if_, drops)
}

#' Wrangling of dates, from YYYY-MM-DD to individual Y and M variables,
#' in order to match the traffic's dataset `year_` and `month_` variables for 
#' posterior merging.
#' 
#' @param input.file Path of the initial unmodified oil pricies file.
#' @param output.file Path of the file which will result of values 
#' transformation.
#' @return No data is explicitly returned.
standardize.oil <- function(
  input.file = './datasets/sources/oil.csv',
  output.file = './datasets/oil_prices.csv') {
  
  setwd('~/Documents/traffic/')
  df <- fread(input.file)
  df <- df %>% as_tibble() %>% mutate(
    year_ = lubridate::year(df$date),
    month_ = lubridate::month(df$date)
  )
  drops <- c('date')
  df <- df[, !(names(df) %in% drops)]
  
  d <- data.frame(
    year_ = integer(), month_ = integer(), 
    oil.type = character(), price = double())
  d <- d %>% 
    rbind(d, data.frame(
      year_ = df$year_, month_ = df$month_, 
      oil.type = 'super', price = df$super)) %>%
    rbind(d, data.frame(
      year_ = df$year_, month_ = df$month_, 
      oil.type = 'premium', price = df$premium)) %>%
    rbind(d, data.frame(
      year_ = df$year_, month_ = df$month_, 
      oil.type = 'gasoil', price = df$gasoil)) %>%
    rbind(d, data.frame(
      year_ = df$year_, month_ = df$month_, 
      oil.type = 'euro', price = df$euro))
  
  fwrite(d, file = output.file)
  rm(d, df, drops)
}

#' Merge traffic and oil data sets into a single, unified data set.
#' 
#' @param traffic.file.path Path of the formated traffic data set.
#' @param oil.file.path Path of the formated oil data set.
#' @param unified.file.path Path of the unified data set.
#' @return No data is explicitly returned.
build.unified.dataset <- function(
  traffic.file.path = './datasets/traffic.csv',
  oil.file.path = './datasets/oil_prices.csv',
  unified.file.path = './datasets/unified.csv'
) {
  traffic <- fread(traffic.file.path)
  oil <- fread(oil.file.path)
  #' Merge both `data.table`s ...
  unified <- merge(
    traffic, 
    oil, 
    by = c('year_', 'month_')
  )
  #' ... and finally write to file.
  fwrite(
    unified,
    file = unified.file.path
  )
  rm(traffic, oil, unified)
}
