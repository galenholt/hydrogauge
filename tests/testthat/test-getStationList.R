test_that("simple works", {
  bomout <- getStationList(portal = 'bom',
                           station_no = c('410730', 'A4260505'))

  namevec <- c('station_id', 'station_no', 'station_name', 'site_id', 'site_no', 'site_name', 'catchment_id', 'catchment_no', 'catchment_name', 'station_latitude', 'station_longitude', 'station_carteasting', 'station_cartnorthing', 'station_local_x', 'station_local_y', 'object_type', 'object_type_shortname', 'station_georefsystem', 'river_id', 'river_name', 'area_id', 'area_name', 'station_longname', 'station_area_wkt', 'station_area_wkt_org', 'station_uuid', 'site_uuid')
  expect_equal(names(bomout), namevec)
  expect_equal(nrow(bomout), 204)
})

test_that("extra_list", {
  bomout <- getStationList(portal = 'bom',
                           extra_list = list(station_name = 'River Murray*'))

  namevec <- c('station_id', 'station_no', 'station_name', 'site_id', 'site_no', 'site_name', 'catchment_id', 'catchment_no', 'catchment_name', 'station_latitude', 'station_longitude', 'station_carteasting', 'station_cartnorthing', 'station_local_x', 'station_local_y', 'object_type', 'object_type_shortname', 'station_georefsystem', 'river_id', 'river_name', 'area_id', 'area_name', 'station_longname', 'station_area_wkt', 'station_area_wkt_org', 'station_uuid', 'site_uuid')
  expect_equal(names(bomout), namevec)
  expect_equal(nrow(bomout), 2797)
})

test_that("groups in extra_list", {
  bomout <- getStationList(portal = 'bom',
                           extra_list = list(stationgroup_id = '20017550'))

  expect_snapshot_value(names(bomout), style = 'deparse')
  expect_equal(nrow(bomout), 207)
})

test_that("returnfields and all data", {
  bomout <- getStationList(portal = 'bom',
                           returnfields = c('station_id', 'station_no', 'station_name', 'site_id', 'station_latitude', 'station_longitude'))

namevec <- c('station_id', 'station_no', 'station_name', 'site_id', 'station_latitude', 'station_longitude')
expect_equal(names(bomout), namevec)
  expect_true(nrow(bomout) > 132000) # The actual number keeps changing. Currently 132205
})

test_that("all returnfields", {

  # According to kisters, these exist
  all_return <- c('station_no', 'station_id', 'station_uuid', 'station_name', 'catchment_no', 'catchment_id', 'catchment_name', 'station_latitude', 'station_longitude', 'station_carteasting', 'station_cartnorthing', 'station_local_x', 'station_local_y', 'station_timezone', 'station_utcoffset', 'station_posmethod', 'site_no', 'site_id', 'site_uuid', 'site_name', 'site_longname', 'parametertype_id', 'parametertype_name', 'parametertype_shortname', 'stationparameter_name', 'stationparameter_no', 'stationparameter_id', 'parametertype_longname', 'object_type', 'object_type_shortname', 'station_georefsystem', 'station_longname', 'station_area_wkt', 'station_area_wkt_org', 'river_id', 'river_name', 'area_id', 'area_name', 'ca_site', 'ca_sta')
  # I get http 500 errors unless I cut to
  sub_return <- all_return[c(1:13, 17:20, 22:40)]

  bomout <- getStationList(portal = 'bom',
                           station_no = c('410730', 'A4260505'),
                           returnfields = sub_return)

  namevec <- c('station_id', 'station_no', 'station_name', 'site_id', 'station_latitude', 'station_longitude')
  expect_equal(names(bomout), namevec)
  expect_equal(nrow(bomout), 204)

  # get the data owner- useful for later
  # According to kisters, these exist
  ownerreturn <- c('station_no', 'station_name', 'station_latitude', 'station_longitude','parametertype_id', 'parametertype_name', 'ca_sta')
  bomout_own <- getStationList(portal = 'bom',
                               extra_list = list(station_name = 'River Murray*'),
                           returnfields = ownerreturn)

  expect_equal(names(bomout), namevec)
})
