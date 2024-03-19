# simple works, with time test

    Code
      names(bomout)
    Output
       [1] "ts_id"              "station_name"       "station_latitude"  
       [4] "station_longitude"  "parametertype_name" "ts_name"           
       [7] "ts_unitname"        "ts_unitsymbol"      "station_no"        
      [10] "station_id"         "value"              "quality_code"      
      [13] "time"               "timezone"          

# returnfields, metareturn, more dates

    Code
      names(bomout)
    Output
      [1] "station_name"  "station_no"    "ts_id"         "ts_unitsymbol"
      [5] "value"         "time"          "timezone"     

# ts_path

    Code
      names(bomout_full)
    Output
       [1] "ts_id"              "station_name"       "station_latitude"  
       [4] "station_longitude"  "parametertype_name" "ts_name"           
       [7] "ts_unitname"        "ts_unitsymbol"      "station_no"        
      [10] "station_id"         "value"              "quality_code"      
      [13] "time"               "timezone"          

---

    Code
      names(bomout_wild)
    Output
       [1] "ts_id"              "station_name"       "station_latitude"  
       [4] "station_longitude"  "parametertype_name" "ts_name"           
       [7] "ts_unitname"        "ts_unitsymbol"      "station_no"        
      [10] "station_id"         "value"              "quality_code"      
      [13] "time"               "timezone"          

# extra_list

    Code
      names(bomout)
    Output
      [1] "station_name"  "station_no"    "ts_id"         "ts_unitsymbol"
      [5] "value"         "quality_code"  "time"          "timezone"     

# period

    Code
      names(bomout_e)
    Output
      [1] "station_name"  "station_no"    "ts_name"       "ts_id"        
      [5] "ts_unitsymbol" "value"         "quality_code"  "time"         
      [9] "timezone"     

---

    Code
      names(bomout_s)
    Output
      [1] "station_name"  "station_no"    "ts_id"         "ts_unitsymbol"
      [5] "value"         "quality_code"  "time"          "timezone"     

---

    Code
      names(bomout_p)
    Output
      [1] "station_name"  "station_no"    "ts_id"         "ts_unitsymbol"
      [5] "value"         "quality_code"  "time"          "timezone"     

