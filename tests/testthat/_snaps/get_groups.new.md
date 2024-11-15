# states

    Code
      vds
    Output
      # A tibble: 26 x 5
         group_decode                 group value   value_decode              stations
         <chr>                        <chr> <chr>   <chr>                     <chr>   
       1 to be at the top of the list AB    FLOOD   All VIR Sites for Flood ~ 233217  
       2 All sites in archive         ALLA  10PLUS  sites with records longe~ 233217  
       3 All sites in archive         ALLA  30PLUS  sites with records longe~ 233217  
       4 All sites in archive         ALLA  ARCHIVE Archive files             233217  
       5 All sites in archive         ALLA  FLOWA   All sites with flow (Vir~ 233217  
       6 All sites in archive         ALLA  LEVEL   All sites with level (10~ 233217  
       7 All sites in archive         ALLA  VFLOW   Virtual sites with flow   233217  
       8 Groups for the CMA areas     CMA   CCMA    <NA>                      233217  
       9 Proposed WMIS 2 Groups by me PROP  SW      <NA>                      233217  
      10 Proposed WMIS 2 Groups by me PROP  WQ      <NA>                      233217  
      # i 16 more rows

---

    Code
      qds
    Output
      # A tibble: 17 x 5
         group_decode                             group    value stations value_decode
         <chr>                                    <chr>    <chr> <chr>    <chr>       
       1 DERM Managed GSes                        DERM_SI~ TOOW~ 422211A  <NA>        
       2 Sites in Hydstra receiving IP DATA       IP_DATA  STAT~ 422211A  Statewide I~
       3 Hydrographic office managers             MGR_OFF~ TOOW~ 422211A  <NA>        
       4 Hydrographic office managers             MGR_OFF~ TOOW~ 422211A  <NA>        
       5 Hydrographic office managers (No client) MGR_OFF~ TOOW~ 422211A  <NA>        
       6 Regional Managers                        MGR_REG~ SOUT~ 422211A  South west ~
       7 Regional Managers                        MGR_REG~ SOUT~ 422211A  South west ~
       8 IP Data by Office                        OFFICE_~ TOOW~ 422211A  <NA>        
       9 Open stations                            OPEN_ST~ BALO~ 422211A  Balonne-Con~
      10 Murray Darling Basin                     QMDBOPE~ MDB   422211A  <NA>        
      11 Site groups across entire state          STATEWI~ ACTI~ 422211A  Open sites,~
      12 Site groups across entire state          STATEWI~ TEL_~ 422211A  All sites w~
      13 Site groups across entire state          STATEWI~ WEBP~ 422211A  Site table ~
      14 SWAN Network 30052017                    SWAN_NE~ TOOW~ 422211A  <NA>        
      15 Water Monitoring Network                 WMNETWO~ SURF~ 422211A  Surface Wat~
      16 Water Monitoring Network                 WMNETWO~ SURF~ 422211A  Surface Wat~
      17 Water Monitoring Network                 WMNETWO~ SWTI~ 422211A  Surface Wat~

---

    Code
      nds
    Output
      # A tibble: 55 x 5
         group_decode                         group        value stations value_decode
         <chr>                                <chr>        <chr> <chr>    <chr>       
       1 KeyGroups used to build others       AA_KEYGROUP  ACTI~ 422004   <NA>        
       2 KeyGroups used to build others       AA_KEYGROUP  CATE~ 422004   DNR telemet~
       3 KeyGroups used to build others       AA_KEYGROUP  M_CA~ 422004   merge of CA~
       4 KeyGroups used to build others       AA_KEYGROUP  M_SP~ 422004   current dat~
       5 KeyGroups used to build others       AA_KEYGROUP  SITE~ 422004   <NA>        
       6 Station Lists - South East Area      AREA_SOUTHE~ CURR~ 422004   Current Sta~
       7 NETWORK CLASSIFICATION SITES         CLASS_AC     SFP   422004   NETWORK CLA~
       8 PRIMARY CLIENT SITES                 CLIENT1_AC   IPART 422004   PRIMARY CLI~
       9 site lists for automated client jobs CLIENT_JOBS  L_DA~ 422004   Sites With ~
      10 Valley groups for IPART Management   CLIENT_VALL~ 422_~ 422004   422 - CULGOA
      # i 45 more rows

# groups

    Code
      vdsg
    Output
      # A tibble: 15,287 x 5
         group_decode                 group value value_decode                stations
         <chr>                        <chr> <chr> <chr>                       <chr>   
       1 to be at the top of the list AB    CTABS Any sites that GAUGINGS re~ 225209  
       2 to be at the top of the list AB    CTABS Any sites that GAUGINGS re~ 226224  
       3 to be at the top of the list AB    CTABS Any sites that GAUGINGS re~ 233213  
       4 to be at the top of the list AB    CTABS Any sites that GAUGINGS re~ 233228  
       5 to be at the top of the list AB    CTABS Any sites that GAUGINGS re~ 233276  
       6 to be at the top of the list AB    CTABS Any sites that GAUGINGS re~ 235224  
       7 to be at the top of the list AB    CTABS Any sites that GAUGINGS re~ 236210  
       8 to be at the top of the list AB    CTABS Any sites that GAUGINGS re~ 238211  
       9 to be at the top of the list AB    CTABS Any sites that GAUGINGS re~ 405248  
      10 to be at the top of the list AB    CTABS Any sites that GAUGINGS re~ 406266  
      # i 15,277 more rows

---

    Code
      qdsg
    Output
      # A tibble: 5,806 x 5
         group_decode                  group        value      stations value_decode  
         <chr>                         <chr>        <chr>      <chr>    <chr>         
       1 Catchments for use in HYCATCH CATCH        GORR       111005A  <NA>          
       2 Catchments for use in HYCATCH CATCH        GORR       111007A  <NA>          
       3 Catchments for use in HYCATCH CATCH        GORR       112002A  <NA>          
       4 Catchments for use in HYCATCH CATCH        GORR       112003A  <NA>          
       5 Catchments for use in HYCATCH CATCH        GORR       112004A  <NA>          
       6 Catchments for use in HYCATCH CATCH        GORR       112101B  <NA>          
       7 Catchments for use in HYCATCH CATCH        GORR       112102A  <NA>          
       8 Reports for ministers office  DDGREPORTING STATEDAILY 001202A  State Daily R~
       9 Reports for ministers office  DDGREPORTING STATEDAILY 001203A  State Daily R~
      10 Reports for ministers office  DDGREPORTING STATEDAILY 002104A  State Daily R~
      # i 5,796 more rows

---

    Code
      ndsg
    Output
      # A tibble: 44,393 x 5
         group_decode                   group       value       stations value_decode
         <chr>                          <chr>       <chr>       <chr>    <chr>       
       1 KeyGroups used to build others AA_KEYGROUP ACTIVESITES 201001   <NA>        
       2 KeyGroups used to build others AA_KEYGROUP ACTIVESITES 201005   <NA>        
       3 KeyGroups used to build others AA_KEYGROUP ACTIVESITES 201012   <NA>        
       4 KeyGroups used to build others AA_KEYGROUP ACTIVESITES 201015   <NA>        
       5 KeyGroups used to build others AA_KEYGROUP ACTIVESITES 201900   <NA>        
       6 KeyGroups used to build others AA_KEYGROUP ACTIVESITES 202001   <NA>        
       7 KeyGroups used to build others AA_KEYGROUP ACTIVESITES 202002   <NA>        
       8 KeyGroups used to build others AA_KEYGROUP ACTIVESITES 203002   <NA>        
       9 KeyGroups used to build others AA_KEYGROUP ACTIVESITES 203004   <NA>        
      10 KeyGroups used to build others AA_KEYGROUP ACTIVESITES 203005   <NA>        
      # i 44,383 more rows

