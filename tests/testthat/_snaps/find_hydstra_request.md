# issues with mdba

    Code
      dplyr::select(reqoutn, -period_end)
    Output
      # A tibble: 1 x 14
        site   short_name     variable var_name datasource period_start        varfrom
        <chr>  <chr>          <chr>    <chr>    <chr>      <dttm>              <chr>  
      1 422004 BARWON @ MOGI~ 100.00   Stream ~ A          1980-06-10 14:00:00 100.00 
      # i 7 more variables: varto <chr>, parametertype_name <chr>,
      #   ts_unitsymbol <chr>, data_type <chr>, portal <chr>, interval <chr>,
      #   multiplier <dbl>

---

    Code
      dplyr::select(reqoutv, -period_end)
    Output
      # A tibble: 1 x 14
        site   short_name     variable var_name datasource period_start        varfrom
        <chr>  <chr>          <chr>    <chr>    <chr>      <dttm>              <chr>  
      1 407249 BIRCH @ NEWLYN 100.00   Dischar~ A          2006-06-23 11:15:00 100.00 
      # i 7 more variables: varto <chr>, parametertype_name <chr>,
      #   ts_unitsymbol <chr>, data_type <chr>, portal <chr>, interval <chr>,
      #   multiplier <dbl>

---

    Code
      dplyr::select(reqoutn, -period_end)
    Output
      # A tibble: 1 x 14
        site   short_name     variable var_name datasource period_start        varfrom
        <chr>  <chr>          <chr>    <chr>    <chr>      <dttm>              <chr>  
      1 422004 BARWON @ MOGI~ 100.00   Stream ~ A          1980-06-10 14:00:00 100.00 
      # i 7 more variables: varto <chr>, parametertype_name <chr>,
      #   ts_unitsymbol <chr>, data_type <chr>, portal <chr>, interval <chr>,
      #   multiplier <dbl>

# double vars

    Code
      reqoutnF
    Output
      # A tibble: 2 x 15
        site   short_name        variable var_name      datasource period_start       
        <chr>  <chr>             <chr>    <chr>         <chr>      <dttm>             
      1 421001 MACQUARIE @ DUBBO 141.00   Discharge Ra~ A          1886-12-01 09:00:00
      2 421001 MACQUARIE @ DUBBO 100.00   Discharge (M~ A          1966-05-27 16:00:00
      # i 9 more variables: period_end <dttm>, varfrom <chr>, varto <chr>,
      #   parametertype_name <chr>, ts_unitsymbol <chr>, data_type <chr>,
      #   portal <chr>, interval <chr>, multiplier <dbl>

---

    Code
      reqoutnT
    Output
      # A tibble: 1 x 15
        site   short_name        variable var_name      datasource period_start       
        <chr>  <chr>             <chr>    <chr>         <chr>      <dttm>             
      1 421001 MACQUARIE @ DUBBO 100.00   Discharge (M~ A          1966-05-27 16:00:00
      # i 9 more variables: period_end <dttm>, varfrom <chr>, varto <chr>,
      #   parametertype_name <chr>, ts_unitsymbol <chr>, data_type <chr>,
      #   portal <chr>, interval <chr>, multiplier <dbl>

---

    Code
      reqoutnO
    Output
      # A tibble: 1 x 15
        site   short_name    variable var_name          datasource period_start       
        <chr>  <chr>         <chr>    <chr>             <chr>      <dttm>             
      1 425022 LAKE MENINDEE 130.00   Reservoir Water ~ A          1968-07-01 09:00:00
      # i 9 more variables: period_end <dttm>, varfrom <chr>, varto <chr>,
      #   parametertype_name <chr>, ts_unitsymbol <chr>, data_type <chr>,
      #   portal <chr>, interval <chr>, multiplier <dbl>

