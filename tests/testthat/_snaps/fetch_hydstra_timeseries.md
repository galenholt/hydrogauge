# ts simple

    Code
      simpletrace
    Output
      # A tibble: 10 x 20
         error_num compressed site_short_name  longitude site_name   latitude org_name
             <int> <chr>      <chr>                <dbl> <chr>          <dbl> <chr>   
       1         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       2         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       3         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       4         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       5         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       6         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       7         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       8         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       9         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
      10         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
      # i 13 more variables: value <dbl>, time <dttm>, quality_codes_id <int>,
      #   site <chr>, variable_short_name <chr>, precision <chr>, subdesc <chr>,
      #   variable <chr>, units <chr>, variable_name <chr>, database_timezone <chr>,
      #   quality_codes <chr>, statistic <chr>

# statistic vectors

    Code
      table(simpletrace_stats$variable, simpletrace_stats$statistic)
    Output
              
               max mean tot
        10.00    0    0   5
        141.00   0    5   0
        450.00   5    0   0

# date formats

    Code
      simpletrace_num
    Output
      # A tibble: 10 x 20
         error_num compressed site_short_name  longitude site_name   latitude org_name
             <int> <chr>      <chr>                <dbl> <chr>          <dbl> <chr>   
       1         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       2         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       3         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       4         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       5         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       6         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       7         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       8         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       9         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
      10         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
      # i 13 more variables: value <dbl>, time <dttm>, quality_codes_id <int>,
      #   site <chr>, variable_short_name <chr>, precision <chr>, subdesc <chr>,
      #   variable <chr>, units <chr>, variable_name <chr>, database_timezone <chr>,
      #   quality_codes <chr>, statistic <chr>

---

    Code
      simpletrace_date
    Output
      # A tibble: 10 x 20
         error_num compressed site_short_name  longitude site_name   latitude org_name
             <int> <chr>      <chr>                <dbl> <chr>          <dbl> <chr>   
       1         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       2         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       3         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       4         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       5         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       6         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       7         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       8         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       9         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
      10         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
      # i 13 more variables: value <dbl>, time <dttm>, quality_codes_id <int>,
      #   site <chr>, variable_short_name <chr>, precision <chr>, subdesc <chr>,
      #   variable <chr>, units <chr>, variable_name <chr>, database_timezone <chr>,
      #   quality_codes <chr>, statistic <chr>

# timezones behave

    Code
      simpletrace_UTC
    Output
      # A tibble: 10 x 20
         error_num compressed site_short_name  longitude site_name   latitude org_name
             <int> <chr>      <chr>                <dbl> <chr>          <dbl> <chr>   
       1         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       2         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       3         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       4         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       5         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       6         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       7         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       8         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
       9         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
      10         0 0          BARWON @ GEELONG      144. BARWON RIV~    -38.2 Dept. S~
      # i 13 more variables: value <dbl>, time <dttm>, quality_codes_id <int>,
      #   site <chr>, variable_short_name <chr>, precision <chr>, subdesc <chr>,
      #   variable <chr>, units <chr>, variable_name <chr>, database_timezone <chr>,
      #   quality_codes <chr>, statistic <chr>

# lake level

    Code
      simpletrace_lakes
    Output
      # A tibble: 20 x 20
         error_num compressed site_short_name    longitude site_name latitude org_name
             <int> <chr>      <chr>                  <dbl> <chr>        <dbl> <chr>   
       1         0 0          CARGELLIGO STORAGE      146. LAKE CAR~    -33.3 WaterNSW
       2         0 0          CARGELLIGO STORAGE      146. LAKE CAR~    -33.3 WaterNSW
       3         0 0          CARGELLIGO STORAGE      146. LAKE CAR~    -33.3 WaterNSW
       4         0 0          CARGELLIGO STORAGE      146. LAKE CAR~    -33.3 WaterNSW
       5         0 0          CARGELLIGO STORAGE      146. LAKE CAR~    -33.3 WaterNSW
       6         0 0          L WETHERELL+TANDU~      143. DARLING ~    -32.3 WaterNSW
       7         0 0          L WETHERELL+TANDU~      143. DARLING ~    -32.3 WaterNSW
       8         0 0          L WETHERELL+TANDU~      143. DARLING ~    -32.3 WaterNSW
       9         0 0          L WETHERELL+TANDU~      143. DARLING ~    -32.3 WaterNSW
      10         0 0          L WETHERELL+TANDU~      143. DARLING ~    -32.3 WaterNSW
      11         0 0          LAKE MENINDEE           142. DARLING ~    -32.4 WaterNSW
      12         0 0          LAKE MENINDEE           142. DARLING ~    -32.4 WaterNSW
      13         0 0          LAKE MENINDEE           142. DARLING ~    -32.4 WaterNSW
      14         0 0          LAKE MENINDEE           142. DARLING ~    -32.4 WaterNSW
      15         0 0          LAKE MENINDEE           142. DARLING ~    -32.4 WaterNSW
      16         0 0          LAKE CAWNDILLA          142. LAKE CAW~    -32.5 WaterNSW
      17         0 0          LAKE CAWNDILLA          142. LAKE CAW~    -32.5 WaterNSW
      18         0 0          LAKE CAWNDILLA          142. LAKE CAW~    -32.5 WaterNSW
      19         0 0          LAKE CAWNDILLA          142. LAKE CAW~    -32.5 WaterNSW
      20         0 0          LAKE CAWNDILLA          142. LAKE CAW~    -32.5 WaterNSW
      # i 13 more variables: value <dbl>, time <dttm>, quality_codes_id <int>,
      #   site <chr>, variable_short_name <chr>, precision <chr>, subdesc <chr>,
      #   variable <chr>, units <chr>, variable_name <chr>, database_timezone <chr>,
      #   quality_codes <chr>, statistic <chr>

