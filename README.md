
<!-- README.md is generated from README.Rmd. Please edit that file -->

# hydrogauge

<!-- badges: start -->

[![R-CMD-check](https://github.com/galenholt/hydrogauge/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/galenholt/hydrogauge/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/galenholt/hydrogauge/graph/badge.svg)](https://app.codecov.io/gh/galenholt/hydrogauge)
[![Codecov test
coverage](https://codecov.io/gh/galenholt/hydrogauge/graph/badge.svg)](https://app.codecov.io/gh/galenholt/hydrogauge)
<!-- badges: end -->

## Purpose

hydrogauge is designed to query
[Kisters](https://resources.kisters.com.au/public/kisters-web-publishing/)
Hydstra (hydllp) and Kisters WISKI/KiWIS water gauge APIs. It does not
have complete API coverage, but tries to expose more than many other
gauge-pulling packages. Please leave functionality requests in github
issues.

## Installation

You can install the development version of hydrogauge from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("galenholt/hydrogauge")
```

## Background

This package was originally conceived to enable a workflow of querying
to discover data availability (variables, time spans, locations),
followed by pulling data based on those findings. This differs from
other, more tailored, approaches to e.g. pulling flow gauges for a
specific location, trading off querying ability with ease of use.

hydrogauge attempts to smooth out this tradeoff by providing a set of
core functions that give the user access to most of the API
functionality using syntax as close to API documentation as possible, as
well as a set of wrapper functions that attempt to make the most common
use-cases easier and avoid the need to dig into API documentation.

This package was originally designed to query various Australian state
water gauge networks and the Australian Bureau of Meteorology (BoM)
APIs. Some Australian states use
[Kisters](https://resources.kisters.com.au/public/kisters-web-publishing/)
Hydstra (hydllp) while the BoM uses Kisters WISKI/KiWIS. Thus, this
package is best-tested agains Australian data sources, but is likely to
work for many other services use these APIs with a simple change to the
URL (argument `portal`).

### API and wrapper functions

The core functions try to stay as close as possible to simple
translations of arguments from R to Kisters formats, and of output JSON
back to R. This approach lets us get closer to exposing the full
functionality and makes for clearer mapping to the [Kisters
documentation](https://kisters.com.au/doco/hydllp.htm). The goal here is
to expose as much functionality as possible and avoid making too many
decisions for the user.

hydrogauge provides convenience functions (primarly `fetch_timeseries`,
`fetch_kiwis_timeseries`, and `fetch_hydstra_timeseries`) that automate
some of the workflow (such as querying period of record and pulling that
range). With the recent inclusion of BoM gauges in WISKi/KiWIS format,
it is likely that harmonized wrapper functions will be developed to
allow calling both types of databases with the same arguments and
returning equivalent outputs.

Caveat: while the functionality provided maps as closely as possible to
the underlying API calls, that functionality is not complete. This
package does not have complete coverage of the available API calls or
their arguments, but is under active development to add missing
capabilities. Initial focus has been on identifying what is available to
pull and pulling timeseries, along with including new data portals.

### Supported sources

Users can input any url for a KiWIS or HYDSTRA (hydllp) portal, but
there are also some that can be called by name (not case sensitive):

- ‘vic’: the [Victorian water
  data](https://data.water.vic.gov.au/static.htm) (API url
  <https://data.water.vic.gov.au/WMIS/cgi/webservice.exe?>)

- ‘nsw’ : [New South Wales water
  data](https://realtimedata.waternsw.com.au/) (API url
  <https://realtimedata.waternsw.com.au/cgi/webservice.exe?>)

- ‘qld’: [Queensland water
  data](https://water-monitoring.information.qld.gov.au/) (API url
  <https://water-monitoring.information.qld.gov.au/cgi/webservice.exe?>)

- ‘bom’: [Australian Bureau of
  Meteorology](http://www.bom.gov.au/waterdata) (API url
  <http://www.bom.gov.au/waterdata/services>)

Other Australian states are in progress and haven’t been looked into
very thoroughly; for the moment, use BoM as a fallback if you don’t know
their API urls.

- [WA](https://wir.water.wa.gov.au/Pages/Water-Information-Reporting.aspx)
  seems to use HYDSTRA, but the API url hasn’t been found yet.

- Unclear what [SA](https://water.data.sa.gov.au/) is using as a
  backend, but other packages (e.g. python
  [mdba-gauge-getter](https://github.com/MDBAuth/MDBA_Gauge_Getter)) use
  BOM for SA.

- [Tasmania](https://portal.wrt.tas.gov.au/Data) and
  [NT](https://ntg.aquaticinformatics.net/Data) have maps that look a
  lot like BoM

If you’re outside Australia, just use your URL. Create an issue (or pull
request) to add other named portals.

The [Kisters
website](https://resources.kisters.com.au/public/kisters-web-publishing/)
provides a list of sites that are likely to work with these functions,
but it may take work to find the correct API url, and those not in the
list above are untested.

## Useful API documentation

For the base functions that directly access the two APIs, argument names
are as close as possible to those used by Kisters. Thus, the API
documentation can be very useful in understanding these calls (and
identifying not-yet-developed functionality in hydrogauge).

### HYDSTRA

I have tried to keep the function argument names the same as in the API,
and the API restricts the options to the function arguments. The API
functions are documented by
[Kisters](https://kisters.com.au/doco/hydllp.htm) (the creators), and
there is a bit more information about options from
[Queensland](https://water-monitoring.information.qld.gov.au/wini/Documents/RDMW_API_doco.pdf),
though there are discrepancies between states.

### WISKI/KiWIS

Most of the documentation I’ve found here is from the [Scottish
Environment Protection Agency](sepa.org.uk); I have not found good docs
straight from Kisters. The [Kisters docs
themselves](https://timeseries.sepa.org.uk/KiWIS/KiWIS?datasource=0&service=kisters&type=queryServices&request=getrequestinfo)
do seem to be available from SEPA though. These provide information
about available functions, allowed variables to request, etc.

A good [SEPA
walkthrough](https://timeseriesdoc.sepa.org.uk/api-documentation/api-function-reference/principal-query-functions).

Unlike Hydstra, which provides tailored arguments for different sorts of
API control, KiWIS primarily uses text search within columns. This can
be more flexible, but means we need to know column names and pay close
attention to the regex used to filter those columns to avoid
contaminating outputs.

## Similar packages

The [bomWater](https://github.com/buzacott/bomWater) and
[kiwisR](https://github.com/rywhale/kiwisR) packages have much of the
functionality needed to call the BoM API, targeted at Australia
(bomWater) and generally (kiwisR). I have learned a lot from them, and
have only chosen to reimplement the BoM work because neither quite had
what I needed for my workflow without being convoluted.

There are similar python packages
[mdba-gauge-getter](https://github.com/MDBAuth/MDBA_Gauge_Getter), which
calls state and BoM, and
[bomwater](github.com/csiro-hydroinformatics/pybomwater), which is the
BoM interface. Both of these are tailored for flow and stage timeseries,
with less emphasis than here on identifying available data and exposing
API funcationality.

An obvious missing piece is USGS gauges. The USGS provides the in-house
[dataRetrieval](https://github.com/DOI-USGS/dataRetrieval) package. At
present, I have not explored wrapping that here and doubt that would
make sense, given the existing tool.

## Notes

I have not done much systematic testing of speed for big requests (long
periods of record for lots of sites and variables). I am working on
optimizing the API calls. It’s certainly possible to overflow your
memory if you ask for everything for all sites.

## Development plans

This package is under active development, and has been put on github as
soon as the main functionality (`get_ts_traces`) was working. The
current high-priority next steps are:

- More helpful wrapper functions that automatically detect and pull data

  - Especially across both hydstra and KiWIS

- Selecting and finding sites based on criteria

  - *Especially* geographic

- Diagnostic plots for data inspection, though those will in general be
  made by the user

- Smarter/faster handling of multiple calls (optimising API calling)

## Contact

Please submit issues on
[GitHub](https://github.com/galenholt/hydrogauge/issues)

- Galen Holt, <g.holt@deakin.edu.au>
