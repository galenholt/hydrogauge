
<!-- README.md is generated from README.Rmd. Please edit that file -->

# hydrogauge

<!-- badges: start -->

[![R-CMD-check](https://github.com/galenholt/hydrogauge/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/galenholt/hydrogauge/actions/workflows/R-CMD-check.yaml)

<!-- badges: end -->

## Purpose

This package is designed to query the [Victorian water
data](https://data.water.vic.gov.au/static.htm) API to pull gauge
information (and now [NSW](https://realtimedata.waternsw.com.au/) and
[QLD](https://water-monitoring.information.qld.gov.au/) but these aren’t
as well tested or documented). It does not have complete coverage of the
available API calls, but is under active development to add
functionality. Initial focus has been on identifying what is available
to pull and pulling timeseries.

## Installation

You can install the development version of hydrogauge from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("galenholt/hydrogauge")
```

## Example

``` r
library(hydrogauge)
library(ggplot2)
```

This package is designed to query the [Victorian water
data](https://data.water.vic.gov.au/static.htm) API to pull gauge
information. It does not have complete coverage of the available API
calls, but is under active development to add functionality. Initial
focus has been on identifying what is available to pull and pulling
timeseries.

At present, we largely assume the user will have a list of gauges they
want, as the current ability to programatically obtain gauge numbers
according to criteria is limited (but see `get_sites_by_datasource`,
which allows asking for all sites that have a given datasource).

To get the timeseries, the user *should*, but does not need to (see
`get_ts_traces2`), know the available variables. However, finding what
they are can be done through the functions here.

This vignette will proceed with a set of sites chosen to span a range of
characteristics (which we know from test queries).

- The Upper Steavenson (405328) only has flow

- Barwon (233217) has many variables, but their start dates differ

- Taggerty (405331) is no longer in operation- ran 2010-2013

- Marysville golf course (405837) is only rainfall

The functions all require gauges to be their numeric codes as
characters. The API needs a comma-separated string (`"number1, number2"`
) , but the functions here will accept a vector
`c("number1", "number2"`) and decompose it internally. This is typically
easier and reflects more common R workflows such as having a column of
site numbers in a dataframe.

``` r
barwon <- '233217'
steavenson <- '405328'
taggerty <- '405331'
golf <- '405837'
```

## Definitions and available options

I have tried to keep the function argument names the same as in the API,
and the API restricts the options to the function arguments. The API
functions are documented by
[Kisters](https://kisters.com.au/doco/hydllp.htm) (the creators), and
there is a bit more information about options from
[Queensland](https://water-monitoring.information.qld.gov.au/wini/Documents/RDMW_API_doco.pdf),
though there are discrepancies between states.

After quite a lot of digging and testing, an incomplete set of
definitions of common arguments and their potential values follows:

- `site_list` is the gauge number as a character (and the functions here
  accept a vector of these gauge numbers). Can be any gauge number in
  the database. Obtaining them programatically is limited currently,
  except in `get_sites_by_datasource`.

- `datasource` The type of data. Currently aware of `"A"`, `"TELEM"`,
  and `"TELEMCOPY"`, but have done this in a roundabout way and there
  may be others and sites I have not examined. `A` is likely to mean
  ‘archive’, `TELEM` seems to mean ‘telemetry’, and I’m not sure why
  there’s a copy.

  - Some quick testing with `get_sites_by_datasource` shows that there
    are many more sites with `A` than `TELEM`, but that `TELEM` is not a
    subset- there are sites with `TELEM` and not `A`. Initial testing of
    `get_db_info` also finds sites that do not appear with any of these,
    and seem to have no data.

- `var_list` is the type of variable, e.g. rainfall, flow, temp. Should
  be a character of the numeric code, with or without trailing “.00”,
  and can be a vector, e.g. c(“100”, “210.00”).

  - I do not currently have a comprehensive list of possible variables
    and their meaning, but `get_variables_by_site` will provide one for
    a set of sites.

  - The [Queensland
    documentation](https://water-monitoring.information.qld.gov.au/wini/Documents/RDMW_API_doco.pdf)
    gives some more information, but the numbers are not always the
    same.

  - Some variables (typically discharge) are calculated, and *do not
    appear in queries of available variables* such as
    `get_variables_by_site`. Those I’m aware of are “141”- discharge in
    ML, and “140”, discharge in cumecs ($m^3/sec$).

- `start_time` and `end_time` are the start and end times of the period
  requested. The API is strict that these should be 14-digit strings
  “YYYYMMDDHHIIEE”, but the functions here will take them in date
  formats (posix), character, or numeric, and they do not need to be
  14-digits.

  - If not dates, they *should* be at least YYYYMMDD (either character
    or numeric), and the rest will be padded with zeros.

- `interval` is the time interval of the return values for timeseries.
  Options seem to be (base on API error messages)

  - `"year"`, `"month"`, `"day"`, `"hour"`, `"minute"`, `"second"`. I
    don’t think capitalisation matters.

  - Also have not thoroughly tested if only some are available for some
    variables at some sites

- `multiplier` I \*think\* this allows intervals like 5 days, by passing
  `interval = 'day'` and `multiplier = 5`. Not tested other than 1 at
  present.

- `data_type` is the statistic to apply within each interval to get the
  values.

  - Options (from API error messages): `"mean"`, `"max"`, `"min"`,
    `"start"`, `"end"`, `"first"`, `"last"`, `"tot"`, `"maxmin"`,
    `"point"`, `"cum"`. Not all are currently tested.

  - *Warning:* any given API call can only takes one value, which is
    applied to all variables. *This is unlikely to be appropriate if
    asking for many variables.*

  - Two options (both requiring *a priori* knowledge of available
    variables):

    1.  run `get_ts_traces` multiple times, with different subsets of
        `var_type`, each with an appropriate `data_types`.

    2.  Use `get_ts_traces2`, which allows matched vectors of `var_type`
        and `data_type`, effectively automating option 1.

## Finding datasources

To see what datasources are available for a site, use
`get_datasources_by_site`. I’ve largely just been using “A” to test, but
it’s worth looking to see what datasources are available for a target
site(s), and then doing the next step (finding variables) for each, to
see whether the available variables (or timeperiods) differ. I’d like to
automate that, but haven’t yet.

``` r
ds <- get_datasources_by_site(portal = 'Vic', 
                              site_list = c(barwon, steavenson, 
                                            taggerty, golf))
```

``` r
ds
```

<div class="kable-table">

| site   | datasource |
|:-------|:-----------|
| 233217 | A          |
| 233217 | TELEM      |
| 233217 | TELEMCOPY  |
| 405328 | A          |
| 405328 | TELEM      |
| 405328 | TELEMCOPY  |
| 405331 | A          |
| 405331 | TELEM      |
| 405837 | A          |
| 405837 | TELEM      |
| 405837 | TELEMCOPY  |

</div>

And we can plot that to get a visualisation. I’m planning to have this
sort of plot for lots of the functions, but for now this is it.

``` r
plot_datasources_by_site(ds)
#> Joining, by = c("site", "datasource")
```

<img src="man/figures/README-unnamed-chunk-5-1.png" width="100%" />

## Finding available variables

Assuming for the moment the user knows the gauge numbers of interest, we
then need to know what variables are available to extract timeseries of.
We use `get_variable_list` to get this information, including both their
names and numbers, as well as other details such as the time period of
record and units.

To demonstrate with the sites above that have a range of variable types
and starts,

``` r
var_info <- get_variable_list(portal = 'Vic', 
                              site_list = c(barwon, taggerty, 
                                            steavenson, golf), 
                              datasource = "A")
```

That returns a tibble with information about each gauge and variable. A
few things to note- it gives the names of the gauges, the names and
values of the variables, and a start and end date for each. For example,
the Barwon’s start date for stage (100) is 1961, while the others (pH,
ppm, etc) didn’t start until 2010.

*Note that this does **not** return derived discharge variables (140 and
141)*. If variable 100 (stage height) exists, the other two always seem
to, though I’m not positive.

``` r
var_info
```

<div class="kable-table">

| site   | short_name           | long_name                                       | variable | units                                                  | var_name                | period_start   | period_end     | subdesc               | datasource | timezone |
|:-------|:---------------------|:------------------------------------------------|:---------|:-------------------------------------------------------|:------------------------|:---------------|:---------------|:----------------------|:-----------|:---------|
| 233217 | BARWON @ GEELONG     | BARWON RIVER @ GEELONG                          | 100.00   | metres                                                 | Stream Water Level (m)  | 19610306171500 | 20230202063000 | Available for release | A          | 10.0     |
| 233217 | BARWON @ GEELONG     | BARWON RIVER @ GEELONG                          | 210.00   | pH                                                     | Acidity/Alkalinity (pH) | 20100706123100 | 20230202063000 | Available for release | A          | 10.0     |
| 233217 | BARWON @ GEELONG     | BARWON RIVER @ GEELONG                          | 215.00   | ppm                                                    | Dissolved Oxygen (ppm)  | 20100706123100 | 20230202063000 | Available for release | A          | 10.0     |
| 233217 | BARWON @ GEELONG     | BARWON RIVER @ GEELONG                          | 450.00   | Degrees celsius                                        | Water Temperature (°C)  | 20100706123100 | 20230202063000 | Available for release | A          | 10.0     |
| 233217 | BARWON @ GEELONG     | BARWON RIVER @ GEELONG                          | 810.00   | NTU                                                    | Turbidity (NTU)         | 20100706123100 | 20230202063000 | Available for release | A          | 10.0     |
| 233217 | BARWON @ GEELONG     | BARWON RIVER @ GEELONG                          | 820.00   | <a href="mailto:µS/cm@25" class="email">µS/cm@25</a>°C | Conductivity (µS/cm)    | 20100706123100 | 20230202063000 | Available for release | A          | 10.0     |
| 405331 | TAGGERTY R LADY TALT | TAGGERTY RV @ LADY TALBOT DRIVE NEAR MARYSVILLE | 100.00   | metres                                                 | Stream Water Level (m)  | 20100729122000 | 20130211110700 | Available for release | A          | 10.0     |
| 405331 | TAGGERTY R LADY TALT | TAGGERTY RV @ LADY TALBOT DRIVE NEAR MARYSVILLE | 450.00   | Degrees celsius                                        | Water Temperature (°C)  | 20100729122000 | 20130211110700 | Available for release | A          | 10.0     |
| 405331 | TAGGERTY R LADY TALT | TAGGERTY RV @ LADY TALBOT DRIVE NEAR MARYSVILLE | 810.00   | NTU                                                    | Turbidity (NTU)         | 20100729122000 | 20130211110700 | Available for release | A          | 10.0     |
| 405331 | TAGGERTY R LADY TALT | TAGGERTY RV @ LADY TALBOT DRIVE NEAR MARYSVILLE | 820.00   | <a href="mailto:µS/cm@25" class="email">µS/cm@25</a>°C | Conductivity (µS/cm)    | 20100729122000 | 20130211110700 | Available for release | A          | 10.0     |
| 405328 | STEAVENSON R @ FALLS | STEAVENSON RIVER @ FALLS ROAD MARYSVILLE        | 100.00   | metres                                                 | Stream Water Level (m)  | 20091119170800 | 20230203084840 | Available for release | A          | 10.0     |
| 405837 | R.G. MARYSVILLE      | RAINGAUGE @ MARYSVILLE GOLF CLUB                | 10.00    | mm                                                     | Rainfall (mm)           | 20010621142700 | 20230203090000 | Available for release | A          | 10.0     |

</div>

## Obtaining timeseries

This is the main use of the package, with the other bits getting us to
the point of knowing what to ask for. Specifically, `get_variable_list`
gives us a reference to know what the variables are to ask for and the
relevant timeperiods.

There are a few ways to request the timeseries, and some pitfalls to
avoid.

If we just want a set of variables that all need the same statistic
applied (e.g. daily mean flows), we can pass that in as a vector. For
example, to get daily mean stage height, discharge, and temperature, we
can do that in one call, even for multiple gauges. Asking here for only
5 days to keep the demo reasonable.

``` r
ts_days <- get_ts_traces(portal = 'Vic', 
                         site_list = c(barwon, steavenson, taggerty, golf),
                         datasource = "A", 
                         var_list = c("100", "141", "450"),
                         start_time = 20200101,
                         end_time = 20201231,
                         interval = "day",
                         data_type = "mean",
                         multiplier = 1,
                         returnformat = 'df')
#> Warning: executing %dopar% sequentially: no parallel backend registered
```

That returns a tall dataframe, which the user can then split up or plot
how they want. There are other options that return lists of dataframes
if the user does not want all sites and variables combined-

- `returnformat = "varlist"` a list with one tibble per variable

- `returnformat = "sitelist"` a list with one tibble per site

- `returnformat = "sxvlist"` a list with one tibble per site x variable
  combo (including empty lists for missing combos)

``` r
# rows.print doesn't really work with devtools::build_readme(), so use head
head(ts_days, 30)
```

<div class="kable-table">

| error_num | compressed | timezone | site_short_name  | longitude | site_name              |  latitude | org_name                             | value | time       | quality_codes_id | site   | variable_short_name | precision | subdesc               | variable | units  | variable_name          | quality_codes                                                                 | data_type |
|----------:|:-----------|:---------|:-----------------|----------:|:-----------------------|----------:|:-------------------------------------|------:|:-----------|-----------------:|:-------|:--------------------|:----------|:----------------------|:---------|:-------|:-----------------------|:------------------------------------------------------------------------------|:----------|
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.838 | 2020-01-01 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.834 | 2020-01-02 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.827 | 2020-01-03 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.821 | 2020-01-04 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.816 | 2020-01-05 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.814 | 2020-01-06 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.811 | 2020-01-07 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.802 | 2020-01-08 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.791 | 2020-01-09 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.805 | 2020-01-10 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.831 | 2020-01-11 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.824 | 2020-01-12 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.820 | 2020-01-13 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.812 | 2020-01-14 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.817 | 2020-01-15 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.829 | 2020-01-16 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.811 | 2020-01-17 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.807 | 2020-01-18 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.809 | 2020-01-19 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.810 | 2020-01-20 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.805 | 2020-01-21 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.803 | 2020-01-22 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.956 | 2020-01-23 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.904 | 2020-01-24 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.865 | 2020-01-25 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.851 | 2020-01-26 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.872 | 2020-01-27 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.926 | 2020-01-28 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.916 | 2020-01-29 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.897 | 2020-01-30 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |

</div>

Note that if a variable isn’t available for a gauge it just isn’t
returned, and same with timeperiods. So, the Barwon returns all
variables, the golf course gauge does not return anything because it
does not collect these variables, the Steavenson returns level and
discharge but not temp, and the Taggerty doesn’t appear at all despite
having these variables because we’ve asked for data after it was
decommissioned.

### Multiple variables, multiple statistics

Now, if we want another set of variables that should have a different
statistic (e.g. rainfall makes sense as the daily sum, not the mean),
there are two options- a separate call of `get_ts_traces` or
`get_ts_traces2`.

First, the separate `get_ts_traces`. Note that again this will ignore
gauges without the info (Barwon)

``` r
ts_rain <- get_ts_traces(portal = 'Vic', 
                         site_list = c(barwon, golf), 
                         datasource = "A", 
                         var_list = c("10"),
                         start_time = 20200101,
                         end_time = 20201231,
                         interval = "day",
                         data_type = "tot",
                         multiplier = 1,
                         returnformat = 'df')
```

``` r
head(ts_rain, 30)
```

<div class="kable-table">

| error_num | compressed | timezone | site_short_name | longitude | site_name                        |  latitude | org_name                             | value | time       | quality_codes_id | site   | variable_short_name | precision | subdesc               | variable | units | variable_name | quality_codes                                                                 | data_type |
|----------:|:-----------|:---------|:----------------|----------:|:---------------------------------|----------:|:-------------------------------------|------:|:-----------|-----------------:|:-------|:--------------------|:----------|:----------------------|:---------|:------|:--------------|:------------------------------------------------------------------------------|:----------|
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.0 | 2020-01-01 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.0 | 2020-01-02 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.0 | 2020-01-03 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.0 | 2020-01-04 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   5.8 | 2020-01-05 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   4.0 | 2020-01-06 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.0 | 2020-01-07 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.0 | 2020-01-08 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.0 | 2020-01-09 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |  10.4 | 2020-01-10 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.4 | 2020-01-11 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.0 | 2020-01-12 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.0 | 2020-01-13 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.0 | 2020-01-14 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |  20.4 | 2020-01-15 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.2 | 2020-01-16 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.0 | 2020-01-17 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.0 | 2020-01-18 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |  18.2 | 2020-01-19 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |  17.6 | 2020-01-20 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.2 | 2020-01-21 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.6 | 2020-01-22 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |  22.0 | 2020-01-23 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.0 | 2020-01-24 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.0 | 2020-01-25 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.0 | 2020-01-26 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.0 | 2020-01-27 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.0 | 2020-01-28 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.0 | 2020-01-29 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |
|         0 | 0          | 10.0     | R.G. MARYSVILLE |  145.7478 | RAINGAUGE @ MARYSVILLE GOLF CLUB | -37.49575 | Dept. Sustainability and Environment |   0.0 | 2020-01-30 |                2 | 405837 | Rainfall (mm)       | 0.100000  | Available for release | 10.00    | mm    | Rainfall (mm) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | tot       |

</div>

If the user wants to combine, they can `dplyr::bind_rows` to combine
post-hoc.

The other option is to use `get_ts_traces2`, which allows paired
`var_list` and `data_type`, and essentially automates that gluing
process, but is a bit slower per call (though probably faster than
manually running two calls?).

``` r
ts_days2 <- get_ts_traces2(portal = 'Vic', 
                           site_list = c(barwon, steavenson, 
                                         taggerty, golf), 
                         datasource = "A", 
                         var_list = c("100", "141", "450", "10"),
                         start_time = 20200101,
                         end_time = 20201231,
                         interval = "day",
                         data_type = c("mean", "mean", "mean", "tot"),
                         multiplier = 1,
                         returnformat = 'df')
```

``` r
head(ts_days2, 30)
```

<div class="kable-table">

| error_num | compressed | timezone | site_short_name  | longitude | site_name              |  latitude | org_name                             | value | time       | quality_codes_id | site   | variable_short_name | precision | subdesc               | variable | units  | variable_name          | quality_codes                                                                 | data_type |
|----------:|:-----------|:---------|:-----------------|----------:|:-----------------------|----------:|:-------------------------------------|------:|:-----------|-----------------:|:-------|:--------------------|:----------|:----------------------|:---------|:-------|:-----------------------|:------------------------------------------------------------------------------|:----------|
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.838 | 2020-01-01 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.834 | 2020-01-02 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.827 | 2020-01-03 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.821 | 2020-01-04 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.816 | 2020-01-05 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.814 | 2020-01-06 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.811 | 2020-01-07 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.802 | 2020-01-08 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.791 | 2020-01-09 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.805 | 2020-01-10 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.831 | 2020-01-11 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.824 | 2020-01-12 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.820 | 2020-01-13 |               15 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Minor editing. +/-11mm - 20mm drift correction                                | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.812 | 2020-01-14 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.817 | 2020-01-15 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.829 | 2020-01-16 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.811 | 2020-01-17 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.807 | 2020-01-18 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.809 | 2020-01-19 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.810 | 2020-01-20 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.805 | 2020-01-21 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.803 | 2020-01-22 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.956 | 2020-01-23 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.904 | 2020-01-24 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.865 | 2020-01-25 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.851 | 2020-01-26 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.872 | 2020-01-27 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.926 | 2020-01-28 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.916 | 2020-01-29 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |
|         0 | 0          | 10.0     | BARWON @ GEELONG |  144.3469 | BARWON RIVER @ GEELONG | -38.16361 | Dept. Sustainability and Environment | 0.897 | 2020-01-30 |                2 | 233217 | Water Level (m)     | 0.001000  | Available for release | 100.00   | metres | Stream Water Level (m) | Good quality data - minimal editing required. +/- 0mm - 10mm Drift correction | mean      |

</div>

## A quick plot

I need to make some standard plots, but in the meantime, we can get a
year of data that covers when the Taggerty was running so it’s
interesting and plot it

``` r
ts_daysY <- get_ts_traces2(portal = 'Vic', 
                           site_list = c(barwon, steavenson, 
                                         taggerty, golf), 
                         datasource = "A", 
                         var_list = c("100", "141", "450", "10"),
                         start_time = 20100101,
                         end_time = 20110101,
                         interval = "day",
                         data_type = c("mean", "mean", "mean", "tot"),
                         multiplier = 1,
                         returnformat = 'df')
```

``` r
ggplot(ts_daysY, aes(x = time, y = value, color = site_short_name)) + 
  facet_wrap(~variable_short_name, scales = 'free') + 
  geom_point() + geom_line()
```

<img src="man/figures/README-unnamed-chunk-15-1.png" width="100%" />

## Notes

The `get_ts_traces2` function also can take “all” for `var_list`,
`start_date` and `end_date`. It’s safe to use for `start_date` and
`end_date`, but probably not for `var_list` for the reasons above- the
vars should *not* all have the same statistic applied.

I have not done much testing of speed for big requests (long periods of
record for lots of sites and variables). There does not seem to be much
time difference to ask for a year vs 5 days above. I do not know if
there are limits, or if those sorts of requests work better broken up
and output glued together or done in one go. It’s certainly possible to
overflow your memory if you ask for everything for all sites.

## Development plans

This package is under active development, and has been put on github as
soon as the main functionality (`get_ts_traces`) was working. The
current high-priority next steps are:

- Diagnostic plots (heatmaps of data availability in a few dimensions-
  see e.g. `plot_datasources_by_site` for a simple implementation)

  - And some plots in here

- Simple timeseries plots for data inspection, though those will in
  general be made by the user

  - And throw some plots in here

- Selecting and finding sites based on criteria

  - *Especially* geographic

- Smarter/faster handling of `data_type` matching to `var_list`

- Other states- NSW and QLD use a similar system, though it looks like
  there are small differences at least in `datasource` values and some
  variable codes. Still, shouldn’t take much to extend, I don’t think.

# Other states

I haven’t done as much investigation of the datasources and similar
variables, but the code should work for NSW and Queensland now by simply
passing state name. South Australia seems to use BOM, but I haven’t
looked into it much, nor any of the non-basin-states. They likely will
work if they use Kisters Hydstra.

## datasources

Using `get_datasources_by_site` to see what datasources are available:

``` r
nsw_ds <- get_datasources_by_site(portal = 'NSW', 
                                  site_list = c("422028", "410007"))
```

``` r
nsw_ds
```

<div class="kable-table">

| site   | datasource |
|:-------|:-----------|
| 422028 | A          |
| 422028 | PROV       |
| 410007 | A          |
| 410007 | PROV       |

</div>

``` r
qld_ds <- get_datasources_by_site(portal = 'QLD', 
                                  site_list = c("423203A", "424201A"))
```

``` r
qld_ds
```

<div class="kable-table">

| site    | datasource |
|:--------|:-----------|
| 423203A | FDR        |
| 423203A | A          |
| 423203A | TE         |
| 423203A | RAW        |
| 424201A | FDR        |
| 424201A | A          |
| 424201A | TE         |
| 424201A | RAW        |

</div>

## Traces and plots

### NSW

Now we can `get_ts_traces` for `A`, just to keep things consistent

``` r
nsw_ts_days <- get_ts_traces(portal = 'NSW', 
                         site_list = c("422028", "410007"),
                         datasource = "A", 
                         var_list = c("100", "141", "450"),
                         start_time = 20200101,
                         end_time = 20201231,
                         interval = "day",
                         data_type = "mean",
                         multiplier = 1,
                         returnformat = 'df')
```

``` r
ggplot(nsw_ts_days, aes(x = time, y = value, color = site_short_name)) + 
  facet_wrap(~variable_short_name, scales = 'free') + 
  geom_line()
```

<img src="man/figures/README-unnamed-chunk-21-1.png" width="100%" />

### QLD

I didn’t pick very interesting examples here.

``` r
qld_ts_days <- get_ts_traces(portal = 'QLD', 
                         site_list = c("423203A", "424201A"),
                         datasource = "A", 
                         var_list = c("100", "141", "450"),
                         start_time = 20200101,
                         end_time = 20201231,
                         interval = "day",
                         data_type = "mean",
                         multiplier = 1,
                         returnformat = 'df')
```

``` r
ggplot(qld_ts_days, aes(x = time, y = value, color = site_short_name)) + 
  facet_wrap(~variable_short_name, scales = 'free') + 
  geom_line()
```

<img src="man/figures/README-unnamed-chunk-23-1.png" width="100%" />
