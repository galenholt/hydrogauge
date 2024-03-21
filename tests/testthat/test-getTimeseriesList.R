test_that("simple works", {
  bomout <- getTimeseriesList(portal = 'bom', station_no = c('410730', 'A4260505'))
  expect_snapshot_value(names(bomout), style = 'deparse')
  expect_equal(nrow(bomout), 200)

})

test_that("extra_list and returnfields", {
  bomout <- getTimeseriesList(portal = 'bom',
                           extra_list = list(station_name = 'River Murray*',
                                             ts_name = 'DMQaQc.Merged.DailyMean.24HR'),
                           returnfields = c('station_no', 'station_name', 'ts_name', 'ts_id', 'ts_path', 'coverage', 'station_latitude'))

  namevec <- c('station_no', 'station_name', 'ts_id', 'from', 'to')
  expect_snapshot_value(names(bomout), style = 'deparse')
  expect_equal(nrow(bomout), 199)
})

test_that("more returnfields", {

  # According to kisters, these exist
  all_return <- c('station_name', 'station_latitude', 'station_longitude', 'station_carteasting', 'station_cartnorthing', 'station_local_x', 'station_local_y', 'station_georefsystem', 'station_longname', 'ts_id', 'ts_name', 'ts_shortname', 'ts_path', 'ts_type_id', 'ts_type_name', 'parametertype_id', 'parametertype_name', 'stationparameter_name', 'stationparameter_no', 'stationparameter_longname', 'ts_unitname', 'ts_unitsymbol', 'ts_unitname_abs', 'ts_unitsymbol_abs', 'site_no', 'site_id', 'site_name', 'catchment_no', 'catchment_id', 'catchment_name', 'coverage', 'ts_density', 'ts_exchange', 'ts_spacing', 'ts_clientvalue##', 'datacart', 'ca_site', 'ca_sta', 'ca_par', 'ca_ts')
  # I get http 500 errors unless I cut to
  sub_return <- all_return[c(1:34, 37:40)]
  bomout <- getTimeseriesList(portal = 'bom',
                              station_no = c('410730', 'A4260505'),
                              returnfields =  sub_return)
  expect_snapshot_value(names(bomout), style = 'deparse')
  expect_equal(nrow(bomout), 200)

})
