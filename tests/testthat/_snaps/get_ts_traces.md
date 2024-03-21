# ts example

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
      # i 13 more variables: value <dbl>, time <dbl>, quality_codes_id <int>,
      #   site <chr>, variable_short_name <chr>, precision <chr>, subdesc <chr>,
      #   variable <chr>, units <chr>, variable_name <chr>, database_timezone <chr>,
      #   quality_codes <chr>, data_type <chr>

# errorhandling for a single site, ts2

    Code
      pass412107[[1]]
    Output
      # A tibble: 1 x 16
        error_num error_msg    compressed timezone site_short_name longitude site_name
            <int> <chr>        <chr>      <chr>    <chr>               <dbl> <chr>    
      1       124 Assumed fai~ 0          10.0     CARGELLIGO STO~      146. LAKE CAR~
      # i 9 more variables: latitude <dbl>, org_name <chr>, site <chr>,
      #   variable_short_name <chr>, precision <chr>, subdesc <chr>, variable <chr>,
      #   units <chr>, variable_name <chr>

