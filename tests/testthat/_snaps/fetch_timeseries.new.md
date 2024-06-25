# doubled gauges warn

    Code
      multiout <- fetch_timeseries(portal = c("vic", "bom", "nsw"), gauge_portal = list(
        vic = c("404224", "405328", "405331"), bom = c("410730", "A4260505", "404224",
          "412078"), nsw = "412078"), start_time = "20200101", end_time = "20200105",
      variable = "discharge", units = "ML/d", datatype = c("A", "QaQc", "A"),
      timeunit = "day", statistic = "mean", robustness = "speed", check_output = TRUE)
    Message
      NULL return- likely everything errored and was 'removed' with .errorhandling
    Condition
      Warning:
      Multiple sources returned the same gauges:
      * 404224: bom, vic
      * 412078: bom, nsw
      Warning:
      Requested gauge(s) not returned:
      * 405331

# missings don't mess things up

    Code
      missout1 <- fetch_timeseries(portal = c("vic", "bom"), gauge_portal = list(vic = c(
        "233217", "40532"), bom = c("410730", "40532")), start_time = "20200101",
      end_time = "20200105", variable = "discharge", units = "ML/d", datatype = c("A",
        "QaQc"), timeunit = "day", statistic = "mean", robustness = "speed",
      check_output = TRUE)
    Condition
      Warning:
      Gauge(s) 40532 do not exist in portal bom
      Warning:
      Gauge(s) 40532 do not exist in portal vic
      Warning:
      Requested gauge(s) not returned:
      * 40532

---

    Code
      missout2 <- fetch_timeseries(portal = c("vic", "bom"), gauge_portal = list(vic = c(
        "23317", "40532"), bom = c("41030", "40532")), start_time = "20200101",
      end_time = "20200105", variable = "discharge", units = "ML/d", datatype = c("A",
        "QaQc"), timeunit = "day", statistic = "mean", robustness = "speed",
      check_output = TRUE)
    Condition
      Warning:
      Gauge(s) 41030 do not exist in portal bom
      Warning:
      Gauge(s) 40532 do not exist in portal bom
      Warning:
      Gauge(s) 23317 do not exist in portal vic
      Warning:
      Gauge(s) 40532 do not exist in portal vic
      Warning:
      Requested gauge(s) not returned:
      * 23317, 40532, 41030

