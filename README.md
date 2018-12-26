-   [Objective](#objective)
-   [Structure of the data to use](#structure-of-the-data-to-use)
-   [Exploratory analysis](#exploratory-analysis)
-   [Hourly flow of traffic going in and out of the city](#hourly-flow-of-traffic-going-in-and-out-of-the-city)
-   [Predicting tomorrow's traffic volume on each toll booth](#predicting-tomorrows-traffic-volume-on-each-toll-booth)

### Objective

This project consists on analyzing the evolution of traffic on AUSA toll booths in Buenos Aires highways. The data being used in this project can be found on the [Buenos Aires Data](https://data.buenosaires.gob.ar/dataset/flujo-vehicular-por-unidades-de-peaje-ausa) site. In particular, it aims to predict the amount of vehicles going in and out of the city for a given date in the future. So, if given a day *d*<sub>*i*</sub>, the model will be able to predict the traffic volume on day *d*<sub>*i* + 1</sub>.

### Structure of the data to use

The information provided consists of 11 files, one for each year from 2008 to 2018. There is no strict convention on the columns naming, neither on whether categorical values are stored with uppercase letters or a mixture of uppercase and lowercase. To standardize everything to the same criteria, several transformations were performed. Those transformations are defined in `src/utils.R` and consist of:

-   `standarize.criteria`: not all of the files have the same column names, nor the same column order. This function standardizes their format, and merges them all in a single .csv file.
-   `transform.values`: among categorical attributes, not all of them have the same value for the same concept, for example you could find the same toll name writen in all caps and then all lowers. This function standardizes that, and creates a new dataset.

The .csv files provide in each entry an estimate of the amount of vehicles that went through a certain toll both in an interval of time of one hour. The following is the detail of each column:

-   `PERIODO`: indicates the **year**.
-   `FECHA`: indicates the **full date** in *dd/mm/yyyy* format for 2008-2015 and *yyyy-mm-dd* for 2016-2018.
-   `DIA`: indicates the **day of the week**.
-   `HORA`: indicates the **start time of the interval**.
-   `HORA_FIN`: indicates the **end time of the interval**.
-   `ESTACION`: indicates the **name of the toll booth**.
-   `TIPO_VEHICULO`: indicates whether the vehicle was a **truck or a car**.
-   `FORMA_PAGO`: indicates if the **payment method**.
-   `CANTIDAD_PASOS`: indicates the **number of vehicles** that went through the toll booth at that interval of time, and payed with a given payment method.

In addition to the previously mentioned columns, two new columns were added to include the geographic position of each toll booth via coordinates, `LAT` and `LONG`. The values of each coordinate were not provided by the dataset, and had to be manually searched using Google Maps.

For example:

``` r
# Include the definitions of the methods used throughout the notebook.
source('./src/flow.R')
df <- read.csv('~/Documents/traffic/datasets/traffic.csv')
head(df)
```

    ##   PERIODO      FECHA    DIA     HORA HORA_FIN   ESTACION TIPO_VEHICULO
    ## 1    2008 2008-01-01 MARTES 00:00:00 01:00:00    ALBERDI       LIVIANO
    ## 2    2008 2008-01-01 MARTES 00:00:00 01:00:00 AVELLANEDA       LIVIANO
    ## 3    2008 2008-01-01 MARTES 00:00:00 01:00:00        DEL       LIVIANO
    ## 4    2008 2008-01-01 MARTES 00:00:00 01:00:00      ILLIA       LIVIANO
    ## 5    2008 2008-01-01 MARTES 01:00:00 02:00:00    ALBERDI       LIVIANO
    ## 6    2008 2008-01-01 MARTES 01:00:00 02:00:00 AVELLANEDA       LIVIANO
    ##   FORMA_PAGO CANTIDAD_PASOS       LAT      LONG
    ## 1   EFECTIVO              7 -34.64480 -58.49205
    ## 2   EFECTIVO             71 -34.64827 -58.47811
    ## 3   EFECTIVO             34 -34.64800 -58.46457
    ## 4   EFECTIVO             27   0.00000   0.00000
    ## 5   EFECTIVO             37 -34.64480 -58.49205
    ## 6   EFECTIVO            345 -34.64827 -58.47811

### Exploratory analysis

As a way of starting to know this dataset, we can see that there is a difference on the amount of entries in each file of our dataset.

``` r
volume.per.year <- df %>%
    group_by(PERIODO) %>% 
    summarise(CANTIDAD_PASOS = sum(CANTIDAD_PASOS))
trend <- lm(volume.per.year$CANTIDAD_PASOS ~ volume.per.year$PERIODO)
plot(volume.per.year$CANTIDAD_PASOS ~ volume.per.year$PERIODO, 
     xlab = 'Time (years)', ylab = 'Number of vehicles')
abline(trend, col = 'red')
```

![](README_files/figure-markdown_github/trend-1.png)

For the graph above it's clear there's an order of magnitud of difference between the amount of vehicles in the period 2008-2013 versus the period 2014-2018. This doesn't mean the number of vehicles skyrocketed in a matter of two years, but rather that new toll booth locations were added to the dataset along those years, which ended up adding 10x more information. To make this evident, compare the amount of toll booths on this heatmap from 2013

``` r
plot(traffic.volume.heatmap(2013))
```

![](README_files/figure-markdown_github/heatmap2013-1.png)

with those on this other one from 2015:

``` r
plot(traffic.volume.heatmap(2015))
```

![](README_files/figure-markdown_github/heatmap2015-1.png)

Each cell in the previous two heatmaps holds the normalized values (to the range \[0, 1\]) of the traffic volume for each toll booth for each day, being DOMINGO (Sunday) the day where the lowest amount of vehicles is registered, and VIERNES (Friday) the one in which there's higher volume of traffic, in most cases.

This traffic flow holds a pattern for each toll booth. Performing an hourly breakdown of traffic for the Alberdi tool booth, shown in the following graph, two traffic peaks can be identified: one around 8am and another one around 6pm. This matches with the times people is commuting to an from work. Another interesting pattern is that traffic keeps relatively still between the time of the two peaks.

``` r
t <- custom.agg(df[(df$ESTACION == 'ALBERDI'),],
                length(unique(df$PERIODO)),
                'TIPO_VEHICULO', 'HORA')
p <- ggplot(data = t, aes(x = format(strptime(t$HORA,"%H:%M:%S"),'%H'), 
                          y = CANTIDAD_PASOS, group = TIPO_VEHICULO)) +
    labs(title = 'Vehicles per hour in Alberdi toll booth', 
         x = 'HORA',
         y = 'Number of vehicles') +
    geom_line(aes(linetype = TIPO_VEHICULO, color = TIPO_VEHICULO)) +
    theme_bw()
plot(p)
```

![](README_files/figure-markdown_github/breakdownalberdi-1.png)

The previous graph differenciates between the two different kinds of vehicles: motorbikes/cars and trucks. While both kinds show a similar behavior, the volume of motorbikes/cars is greater than the one of trucks. Although this behavior can be seen in other toll booths like Avellaneda or Sarmiento, there are cases like Retiro, where the amount of trucks is almost the same as the one of cars.

``` r
t <- custom.agg(df[(df$ESTACION == 'RETIRO'),],
                length(unique(df$PERIODO)),
                'TIPO_VEHICULO', 'HORA')
p <- ggplot(data = t, aes(x = format(strptime(t$HORA,"%H:%M:%S"),'%H'), 
                          y = CANTIDAD_PASOS, group = TIPO_VEHICULO)) +
    labs(title = 'Vehicles per hour in Retiro toll booth', 
         x = 'HORA',
         y = 'Number of vehicles') +
    geom_line(aes(linetype = TIPO_VEHICULO, color = TIPO_VEHICULO)) +
    theme_bw()
plot(p)
```

![](README_files/figure-markdown_github/breakdownretiro-1.png)

Even though the volume of vehicles going through the Retiro toll booth is approximatelly three times smaller than the one of Alberdi, the ratio Liviano-Pesado (light-heavy) is greater. The reason for this is that Retiro is a a commercial route, located in the road to the Port of Buenos Aires, reason why the volume of heavy vehicles is greater than in other toll booths.

Another interesting aspect to analyze of this dataset is the distribution of drivers commiting infractions (id est, not paying when they cross the toll booth), and whether this is something that only happens for light vehicles or in heavy vehicles too. Below are two charts with the distribution of infractions for both Alberdi and Retiro.

``` r
t <- custom.agg(df[(df$ESTACION == 'ALBERDI' & df$FORMA_PAGO == 'INFRACCION'),],
                length(unique(df$PERIODO)),
                'TIPO_VEHICULO', 'HORA')
p <- ggplot(data = t, aes(x = format(strptime(t$HORA,"%H:%M:%S"),'%H'), 
                          y = CANTIDAD_PASOS, group = TIPO_VEHICULO)) +
    labs(title = 'Infractions per hour in Alberdi toll booth', 
         x = 'HORA',
         y = 'Number of vehicles') +
    geom_line(aes(linetype = TIPO_VEHICULO, color = TIPO_VEHICULO)) +
    theme_bw()
plot(p)
```

![](README_files/figure-markdown_github/infractionsalberdi-1.png)

``` r
t <- custom.agg(df[(df$ESTACION == 'RETIRO' & df$FORMA_PAGO == 'INFRACCION'),],
                length(unique(df$PERIODO)),
                'TIPO_VEHICULO', 'HORA')
p <- ggplot(data = t, aes(x = format(strptime(t$HORA,"%H:%M:%S"),'%H'), 
                          y = CANTIDAD_PASOS, group = TIPO_VEHICULO)) +
    labs(title = 'Infractions per hour in Retiro toll booth', 
         x = 'HORA',
         y = 'Number of vehicles') +
    geom_line(aes(linetype = TIPO_VEHICULO, color = TIPO_VEHICULO)) +
    theme_bw()
plot(p)
```

![](README_files/figure-markdown_github/infractionsretiro-1.png)

In both cases, the distribution of infractions seems to follow the same distribution of traffic throughout the day: the moments where there are more infractions correlate with those in which traffic volume is the highest.

### Hourly flow of traffic going in and out of the city

TODO(tulians): This section will include a map showing the zones where toll booths are, and how the volume of traffic changes throughout the day.

### Predicting tomorrow's traffic volume on each toll booth

TODO(tulians): Use the forecast library to predict the next 2 days traffic volume.
