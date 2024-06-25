# returns expected

    c("site", "short_name", "long_name", "variable", "units", "var_name", 
    "period_start", "period_end", "subdesc", "datasource", "database_timezone"
    )

# handles missing

    c("site", "short_name", "long_name", "variable", "units", "var_name", 
    "period_start", "period_end", "subdesc", "datasource", "database_timezone"
    )

---

    c("site", "short_name", "long_name", "variable", "units", "var_name", 
    "period_start", "period_end", "subdesc", "datasource", "database_timezone"
    )

# lake level and other

    Code
      lakelist
    Output
      # A tibble: 19 x 11
         site   short_name       long_name variable units var_name period_start       
         <chr>  <chr>            <chr>     <chr>    <chr> <chr>    <dttm>             
       1 422028 BARWON @ BEEMERY BARWON R~ 100.00   Metr~ Stream ~ 1999-06-26 06:38:00
       2 422028 BARWON @ BEEMERY BARWON R~ 100.09   Metr~ Stream ~ 1999-12-08 20:00:00
       3 422028 BARWON @ BEEMERY BARWON R~ 141.01   Mega~ Dischar~ 1998-12-31 14:00:00
       4 422028 BARWON @ BEEMERY BARWON R~ 141.02   Mega~ Dischar~ 1998-12-31 14:00:00
       5 422028 BARWON @ BEEMERY BARWON R~ 151.00   Mega~ Dischar~ 1998-12-31 14:00:00
       6 422028 BARWON @ BEEMERY BARWON R~ 151.01   Mega~ Dischar~ 1998-12-31 14:00:00
       7 422028 BARWON @ BEEMERY BARWON R~ 151.02   Mega~ Dischar~ 1800-12-31 14:00:00
       8 422028 BARWON @ BEEMERY BARWON R~ 154.00   Mega~ WSP Dis~ 2013-12-31 14:00:00
       9 422028 BARWON @ BEEMERY BARWON R~ 300.00   Volts Logger ~ 2017-10-16 14:15:00
      10 412107 CARGELLIGO STOR~ LAKE CAR~ 100.00   Metr~ Stream ~ 1975-05-31 23:00:00
      11 412107 CARGELLIGO STOR~ LAKE CAR~ 130.00   Metr~ Reservo~ 1975-05-31 23:00:00
      12 412107 CARGELLIGO STOR~ LAKE CAR~ 136.00   Mega~ Reservo~ 1989-12-31 23:00:00
      13 412107 CARGELLIGO STOR~ LAKE CAR~ 137.00   Hect~ Reservo~ 2000-03-15 23:00:00
      14 412107 CARGELLIGO STOR~ LAKE CAR~ 141.01   Mega~ Dischar~ 1974-12-31 14:00:00
      15 412107 CARGELLIGO STOR~ LAKE CAR~ 141.02   Mega~ Dischar~ 1974-12-31 14:00:00
      16 412107 CARGELLIGO STOR~ LAKE CAR~ 151.00   Mega~ Dischar~ 1975-05-31 14:00:00
      17 412107 CARGELLIGO STOR~ LAKE CAR~ 151.01   Mega~ Dischar~ 1974-12-31 14:00:00
      18 412107 CARGELLIGO STOR~ LAKE CAR~ 151.02   Mega~ Dischar~ 1800-12-31 14:00:00
      19 412107 CARGELLIGO STOR~ LAKE CAR~ 448.00   %     % Effec~ 1989-12-31 23:00:00
      # i 4 more variables: period_end <dttm>, subdesc <chr>, datasource <chr>,
      #   database_timezone <chr>

