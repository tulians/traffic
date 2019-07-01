#' Feature engineering and data wrangling.
#' Julián Ailán - jailan@itba.edu.ar
#' ITBA - 2018/2019

#' The dataset is composed of 12 files, consisting on observations from 2008 
#' to 2019. Not all of them have the same column names, nor the same column
#' order. This function standardizes their format, and merges them all in a
#' single .csv file.
#'
#' @param intermediate Name to the file that hosts data with standardized header
#' names.
#' @return Nothing is explicitly returned.
join_traffic_files <- function(
  intermediate = "merged.csv"
) {
  #' Generate the file paths automatically, given that each year a new file is
  #' created and may require formating.
  wd <- getwd()
  common_path <- file.path (
    wd,
    "datasets/sources/traffic-v2/flujo-vehicular-x.csv"
  )
  years <- 2008:2019
  file_paths <- unlist (
    lapply (
      years,
      function (year) {
        gsub("x", year, common_path)
      }
    )
  )
  #' Read files in bulk into `data.table`s.
  files <- lapply (
    file_paths,
    fread,
    colClasses = "character"
  )
  #' Column format to use.
  columns <- c("PERIODO", "FECHA", "DIA", "HORA", "HORA_FIN", "ESTACION",
               "TIPO_VEHICULO", "FORMA_PAGO", "CANTIDAD_PASOS", "HORAFIN",
               "TIPOVEHICULO", "FORMAPAGO", "CANTIDADPASOS", "HORA_INICIO")
  underscores <- c("PERIODO", "FECHA", "DIA", "HORA", "HORA_FIN", "ESTACION",
                   "TIPO_VEHICULO", "FORMA_PAGO", "CANTIDAD_PASOS")
  #' Make sure that all non-standard files use the same column name format.
  files <- lapply (
    files,
    function (f) {
      f <- f[, # Affects all rows.
             tolower(names(f)) %in% tolower(columns),
             with = FALSE]
      setnames(f,
               old = sort(names(f)),
               new = sort(underscores))
    }
  )
  #' Generate a unified intermediate file with standardized header names.
  intermediate_file <- Reduce (
    function(...) merge(..., all = TRUE),
    files
  )
  
  fwrite (
    intermediate_file,
    file = file.path (
      wd, 
      "datasets/sources", 
      intermediate
    )
  )
  rm(common_path, years, file_paths, files,
     columns, underscores, intermediate_file)
}

#' Among categorical attributes, not all of them have the same value for the
#' same concept, fox example you could find the same toll name writen in 
#' all caps and then all lowers. This function standardizes that, and creates
#' a new dataset.
#' 
#' @param output_file Path and name of the file which will result of values 
#' transformation.
#' @return The standardized dataframe.
standardize_traffic <- function(
  merged = "merged.csv",
  traffic = "traffic.csv") {
  #' Adapted from `swap_if` in
  #' https://github.com/tidyverse/dplyr/issues/2149#issuecomment-258916706
  #' The solution presented there has a bug in the generation of out_y, as the
  #' condition should not be negated.
  swap_if_ <- function(cond, x, y) 
  {
    # TODO(tulians): avoid using the dataframe.
    out_x <- ifelse(cond, y, x)
    out_y <- ifelse(cond, x, y)
    setNames(tibble(out_x, out_y), names(c("M", "D")))
  }
  #' Normalizes the format of the time columns.
  to_std_time_format <- function(d) 
  {
    one.digit <- grep("^\\d$", d)
    two.digits <- grep("^\\d{2}$", d)
    five.digits <- grep("^\\d:00:00$", d)
    extra.text <- grep("0 days \\d{2}:00:00", d)
    midnight <- grep("24:00:00", d)
    if (length(one.digit)) {
      d[one.digit] <- paste("0", d[one.digit], ":00:00", sep = "")
    }
    if (length(two.digits)) {
      d[two.digits] <- paste(d[two.digits], ":00:00", sep = "")
    }
    if (length(five.digits)) {
      d[five.digits] <- paste("0", d[five.digits], sep = "")
    }
    if (length(extra.text)) {
      d[extra.text] <- str_sub(d[extra.text], -8)
    }
    if (length(midnight)) {
      d[midnight] <- paste("00:00:00")
    }
    return(d)
  }
  #' Helper function to extend %like% to a list of elements.
  "%like any%" <- function(vector, pattern)
  {
    like(vector, paste(pattern, collapse = "|"))
  }
  
  #' Data wrangling for the traffic dataset.
  join_traffic_files()
  wd <- getwd()
  input_file <- file.path (
    wd,
    "datasets/sources",
    merged
  )
  df <- fread(input_file)
  df <- df %>% as_tibble() %>% mutate (
    toll_booth_name = case_when (
      tolower(ESTACION) %like% "alb" ~ "Alberti",
      tolower(ESTACION) %like% "ave" ~ "Avellaneda",
      tolower(ESTACION) %like any% c (
        "dec",
        "del"
      ) ~ "Dellepiane",
      tolower(ESTACION) %like any% c (
        "ill",
        "ret"
      ) ~ "Retiro",
      tolower(ESTACION) %like% "sal" ~ "Salguero",
      tolower(ESTACION) %like% "sar" ~ "Sarmiento",
      TRUE ~ as.character(ESTACION)
    ),
    day_name = case_when (
      tolower(DIA) == "lunes" ~ "Monday",
      tolower(DIA) == "martes" ~ "Tuesday",
      tolower(DIA) %like% "rcoles" ~ "Wednesday",
      tolower(DIA) == "jueves" ~ "Thursday",
      tolower(DIA) == "viernes" ~ "Friday",
      tolower(DIA) %like% "bado" ~ "Saturday",
      tolower(DIA) == "domingo" ~ "Sunday",
      TRUE ~ as.character(DIA)
    ),
    vehicle_type = case_when (
      tolower(TIPO_VEHICULO) == "motos" ~ "Motorbike",
      tolower(TIPO_VEHICULO) %like% "liviano" ~ "Car",
      tolower(TIPO_VEHICULO) %like% "pesado" ~ "Truck",
      tolower(TIPO_VEHICULO) %in% c (
        "N/D",
        "ND"
      ) ~ "Non-determined",
      tolower(TIPO_VEHICULO) %like% "cobro doble para" ~ "Non-frequent",
      TRUE ~ as.character(TIPO_VEHICULO)
    ),
    lat = case_when (
      toll_booth_name == "Alberti" ~ -34.6448027,
      toll_booth_name == "Avellaneda" ~ -34.6482732,
      toll_booth_name == "Dellepiane" ~ -34.6504678,
      toll_booth_name == "Retiro" ~ -34.5752543,
      toll_booth_name == "Sarmiento" ~ -34.5674364,
      toll_booth_name == "Salguero" ~ -34.5717106
    ),
    long = case_when (
      toll_booth_name == "Alberti" ~ -58.4920542,
      toll_booth_name == "Avellaneda" ~ -58.4781064,
      toll_booth_name == "Dellepiane" ~ -58.4656122,
      toll_booth_name == "Retiro" ~ -58.3921129,
      toll_booth_name == "Sarmiento" ~ -58.4079902,
      toll_booth_name == "Salguero" ~ -58.4003948
    ),
    manual_booths = case_when (
      toll_booth_name == "Alberti" ~ 5,
      toll_booth_name == "Avellaneda" ~ 26,
      toll_booth_name == "Dellepiane" ~ 8,
      toll_booth_name == "Retiro" ~ 24,
      toll_booth_name == "Sarmiento" ~ 0,
      toll_booth_name == "Salguero" ~ 0
    ),
    automatic_booths = case_when (
      toll_booth_name == "Alberti" ~ 5,
      toll_booth_name == "Avellaneda" ~ 32,
      toll_booth_name == "Dellepiane" ~ 6,
      toll_booth_name == "Retiro" ~ 32,
      toll_booth_name == "Sarmiento" ~ 8,
      toll_booth_name == "Salguero" ~ 8
    ),
    payment_method = case_when (
      tolower(FORMA_PAGO) == "efectivo" ~ "Cash",
      FORMA_PAGO %in% c(
        "MONEDERO",
        "TARJETA",
        "TARJETA DISCAPACIDAD",
        "Tarjeta Magnética"
      ) ~ "Card",
      FORMA_PAGO %in% c("AUPASS", "Tag") ~ "Automatic",
      FORMA_PAGO %in% c("VIA LIBERADA", "NO COBRADO") ~ "No barriers",
      tolower(FORMA_PAGO) == "exento" ~ "Exempt",
      FORMA_PAGO %in% c("INFRACCION", "Violación") ~ "Infraction",
      FORMA_PAGO %in% c("OTROS", "Reconocimiento de Deuda") ~ "Others"
    ),
    date_ = case_when (
      PERIODO < 2014 ~ as.Date(
        strptime(as.character(FECHA), "%m/%d/%Y"), format = "%Y-%m-%d"),
      PERIODO >= 2014 & PERIODO < 2016 ~ as.Date(
        strptime(as.character(FECHA), "%d/%m/%Y"), format = "%Y-%m-%d"),
      PERIODO >= 2016 ~ as.Date(
        strptime(as.character(FECHA), "%Y-%m-%d"), format = "%Y-%m-%d")
    ),
    year_ = lubridate::year(date_),
    month_ = lubridate::month(date_),
    day_ = lubridate::day(date_),
    vehicle_type = as.factor(vehicle_type),
    payment_method = as.factor(payment_method),
    toll_booth_name = as.factor(toll_booth_name),
    day_name = as.factor(day_name),
    amount = CANTIDAD_PASOS
  )
  #' Make sure that date formats is homogeneous across all rows.
  df <- df %>% as_tibble() %>% mutate_at(
    c("HORA", "HORA_FIN"), to_std_time_format)
  df <- df %>% mutate (
    start_hour = as.factor(HORA),
    end.hour = as.factor(HORA_FIN)
  )
  df[df$PERIODO < 2014, ] <- arrange(df[df$PERIODO < 2014, ], FECHA)
  df[df$PERIODO == 2018, ] <- df[df$PERIODO == 2018, ] %>% arrange(month_, day_)
  df[df$PERIODO == 2018, c("month_", "day_")] <-
    swap_if_(
      df[df$PERIODO == 2018, c("month_", "day_")]$day_ %in% c(1, 2, 3) &
        df[df$PERIODO == 2018, c("month_", "day_")]$month_ %in% c(10, 11, 12),
      df[df$PERIODO == 2018, c("month_", "day_")]$month_,
      df[df$PERIODO == 2018, c("month_", "day_")]$day_)
  df <- df %>% mutate (
    quarter_ = case_when (
      month_ %in% c(1, 2, 3) ~ 1,
      month_ %in% c(4, 5, 6) ~ 2,
      month_ %in% c(7, 8, 9) ~ 3,
      month_ %in% c(10, 11, 12) ~ 4
    )
  )
  #' Remove unnecessary columns.
  drops <- c("FECHA", "PERIODO", "CANTIDAD_PASOS",
             "FORMA_PAGO", "TIPO_VEHICULO", "ESTACION",
             "HORA", "HORA_FIN", "DIA")
  df <- df[, !(names(df) %in% drops)]
  #' Write the final file.
  output_file <- file.path (
    wd,
    "datasets",
    traffic
  )
  fwrite (
    df,
    file = output_file
  )
  file.remove(input_file)
  rm(df, to_std_time_format, swap_if_, drops)
}

#' Wrangling of dates, from YYYY-MM-DD to individual Y and M variables,
#' in order to match the traffic's dataset `year_` and `month_` variables for 
#' posterior merging.
#' 
#' @param oil Name of the initial unmodified oil pricies file.
#' @param oil_prices Name of the file which will result of values 
#' transformation.
#' @return No data is explicitly returned.
standardize_oil <- function(
  oil = "oil.csv",
  oil_prices = "oil_prices.csv") {
  #' Read the oil data set ...
  wd <- getwd()
  input_file <- file.path (
    wd, 
    "datasets/sources",
    oil
  )
  df <- fread(input_file)
  df <- df %>% as_tibble() %>% mutate (
    year_ = lubridate::year(df$date),
    month_ = lubridate::month(df$date)
  )
  drops <- c("date")
  df <- df[, !(names(df) %in% drops)]
  #' ... and move from a horizontal to vertical format.
  d <- data.frame (
    year_ = integer(), month_ = integer(),
    oil_type = character(), price = double())
  d <- d %>%
    rbind(d, data.frame (
      year_ = df$year_, month_ = df$month_,
      oil_type = "super", price = df$super)) %>%
    rbind(d, data.frame (
      year_ = df$year_, month_ = df$month_,
      oil_type = "premium", price = df$premium)) %>%
    rbind(d, data.frame (
      year_ = df$year_, month_ = df$month_,
      oil_type = "gasoil", price = df$gasoil)) %>%
    rbind(d, data.frame (
      year_ = df$year_, month_ = df$month_,
      oil_type = "euro", price = df$euro))
  #' Write the final file.
  output_file <- file.path (
    wd, 
    "datasets", 
    oil_prices
  )
  fwrite (
    d, 
    file = output_file
  )
  rm(d, df, drops)
}

#' Merge traffic and oil data sets into a single, unified data set.
#' 
#' @param traffic Name of the formated traffic data set.
#' @param oil Name of the formated oil data set.
#' @param unified Name of the unified data set.
#' @return No data is explicitly returned.
build_unified_dataset <- function(
  traffic = "traffic.csv",
  oil = "oil_prices.csv",
  unified = "unified.csv"
) {
  require(dplyr, data.table)
  #' Prepare the two data sources for merging.
  standardize_traffic()
  standardize_oil()
  
  wd <- getwd()
  traffic_file_path <- file.path (
    wd, 
    "datasets", 
    traffic
  )
  oil_file_path <- file.path (
    wd, 
    "datasets", 
    oil
  )
  unified_file_path <- file.path (
    wd, 
    "datasets", 
    unified
  )
  
  traffic <- fread(traffic_file_path)
  oil <- fread(oil_file_path)
  #' Merge both `data.table`s ...
  unified <- merge (
    traffic,
    oil,
    by = c("year_", "month_"),
    allow.cartesian = TRUE
  )
  #' ... and finally write to file.
  fwrite (
    unified,
    file = unified_file_path
  )
  rm(traffic, oil, unified)
  file.remove(traffic_file_path, oil_file_path)
}