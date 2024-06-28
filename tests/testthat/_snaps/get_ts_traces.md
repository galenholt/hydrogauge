# ts example all states

    Code
      simpletracev
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

---

    Code
      simpletraceq
    Output
      # A tibble: 10 x 20
         error_num compressed site_short_name    longitude site_name latitude org_name
             <int> <chr>      <chr>                  <dbl> <chr>        <dbl> <chr>   
       1         0 0          Briarie_Ck Wooler~      148. Briarie ~    -28.9 DNR - H~
       2         0 0          Briarie_Ck Wooler~      148. Briarie ~    -28.9 DNR - H~
       3         0 0          Briarie_Ck Wooler~      148. Briarie ~    -28.9 DNR - H~
       4         0 0          Briarie_Ck Wooler~      148. Briarie ~    -28.9 DNR - H~
       5         0 0          Briarie_Ck Wooler~      148. Briarie ~    -28.9 DNR - H~
       6         0 0          Briarie_Ck Wooler~      148. Briarie ~    -28.9 DNR - H~
       7         0 0          Briarie_Ck Wooler~      148. Briarie ~    -28.9 DNR - H~
       8         0 0          Briarie_Ck Wooler~      148. Briarie ~    -28.9 DNR - H~
       9         0 0          Briarie_Ck Wooler~      148. Briarie ~    -28.9 DNR - H~
      10         0 0          Briarie_Ck Wooler~      148. Briarie ~    -28.9 DNR - H~
      # i 13 more variables: value <dbl>, time <dbl>, quality_codes_id <int>,
      #   site <chr>, variable_short_name <chr>, precision <chr>, subdesc <chr>,
      #   variable <chr>, units <chr>, variable_name <chr>, database_timezone <chr>,
      #   quality_codes <chr>, data_type <chr>

---

    Code
      simpletracen
    Output
      # A tibble: 10 x 20
         error_num compressed site_short_name    longitude site_name latitude org_name
             <int> <chr>      <chr>                  <dbl> <chr>        <dbl> <chr>   
       1         0 0          BARWON @ MOGIL MO~      149. BARWON R~    -29.4 WaterNSW
       2         0 0          BARWON @ MOGIL MO~      149. BARWON R~    -29.4 WaterNSW
       3         0 0          BARWON @ MOGIL MO~      149. BARWON R~    -29.4 WaterNSW
       4         0 0          BARWON @ MOGIL MO~      149. BARWON R~    -29.4 WaterNSW
       5         0 0          BARWON @ MOGIL MO~      149. BARWON R~    -29.4 WaterNSW
       6         0 0          BARWON @ MOGIL MO~      149. BARWON R~    -29.4 WaterNSW
       7         0 0          BARWON @ MOGIL MO~      149. BARWON R~    -29.4 WaterNSW
       8         0 0          BARWON @ MOGIL MO~      149. BARWON R~    -29.4 WaterNSW
       9         0 0          BARWON @ MOGIL MO~      149. BARWON R~    -29.4 WaterNSW
      10         0 0          BARWON @ MOGIL MO~      149. BARWON R~    -29.4 WaterNSW
      # i 13 more variables: value <dbl>, time <dbl>, quality_codes_id <int>,
      #   site <chr>, variable_short_name <chr>, precision <chr>, subdesc <chr>,
      #   variable <chr>, units <chr>, variable_name <chr>, database_timezone <chr>,
      #   quality_codes <chr>, data_type <chr>

# ts example, just 140

    Code
      simpletrace
    Output
      # A tibble: 5 x 20
        error_num compressed site_short_name  longitude site_name    latitude org_name
            <int> <chr>      <chr>                <dbl> <chr>           <dbl> <chr>   
      1         0 0          BARWON @ GEELONG      144. BARWON RIVE~    -38.2 Dept. S~
      2         0 0          BARWON @ GEELONG      144. BARWON RIVE~    -38.2 Dept. S~
      3         0 0          BARWON @ GEELONG      144. BARWON RIVE~    -38.2 Dept. S~
      4         0 0          BARWON @ GEELONG      144. BARWON RIVE~    -38.2 Dept. S~
      5         0 0          BARWON @ GEELONG      144. BARWON RIVE~    -38.2 Dept. S~
      # i 13 more variables: value <dbl>, time <dbl>, quality_codes_id <int>,
      #   site <chr>, variable_short_name <chr>, precision <chr>, subdesc <chr>,
      #   variable <chr>, units <chr>, variable_name <chr>, database_timezone <chr>,
      #   quality_codes <chr>, data_type <chr>

# ts example, just 100 (so, no derived)

    Code
      simpletrace
    Output
      # A tibble: 5 x 20
        error_num compressed site_short_name  longitude site_name    latitude org_name
            <int> <chr>      <chr>                <dbl> <chr>           <dbl> <chr>   
      1         0 0          BARWON @ GEELONG      144. BARWON RIVE~    -38.2 Dept. S~
      2         0 0          BARWON @ GEELONG      144. BARWON RIVE~    -38.2 Dept. S~
      3         0 0          BARWON @ GEELONG      144. BARWON RIVE~    -38.2 Dept. S~
      4         0 0          BARWON @ GEELONG      144. BARWON RIVE~    -38.2 Dept. S~
      5         0 0          BARWON @ GEELONG      144. BARWON RIVE~    -38.2 Dept. S~
      # i 13 more variables: value <dbl>, time <dbl>, quality_codes_id <int>,
      #   site <chr>, variable_short_name <chr>, precision <chr>, subdesc <chr>,
      #   variable <chr>, units <chr>, variable_name <chr>, database_timezone <chr>,
      #   quality_codes <chr>, data_type <chr>

