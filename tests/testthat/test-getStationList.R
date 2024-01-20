test_that("simple works", {
  bomout <- getStationList(portal = 'bom', site_list = c('410730', 'A4260505'))

  namevec <- c('station_id', 'station_no', 'station_name', 'site_id', 'site_no', 'site_name', 'catchment_id', 'catchment_no', 'catchment_name', 'station_latitude', 'station_longitude', 'station_carteasting', 'station_cartnorthing', 'station_local_x', 'station_local_y', 'object_type', 'object_type_shortname', 'station_georefsystem', 'river_id', 'river_name', 'area_id', 'area_name', 'station_longname', 'station_area_wkt', 'station_area_wkt_org', 'station_uuid', 'site_uuid')
  expect_equal(names(bomout), namevec)
  expect_equal(nrow(bomout), 2)
})

test_that("extra_list", {
  bomout <- getStationList(portal = 'bom', extra_list = list(station_name = 'River Murray*'))

  namevec <- c('station_id', 'station_no', 'station_name', 'site_id', 'site_no', 'site_name', 'catchment_id', 'catchment_no', 'catchment_name', 'station_latitude', 'station_longitude', 'station_carteasting', 'station_cartnorthing', 'station_local_x', 'station_local_y', 'object_type', 'object_type_shortname', 'station_georefsystem', 'river_id', 'river_name', 'area_id', 'area_name', 'station_longname', 'station_area_wkt', 'station_area_wkt_org', 'station_uuid', 'site_uuid')
  expect_equal(names(bomout), namevec)
  expect_equal(nrow(bomout), 77)
})

test_that("returnfields and all data", {
  bomout <- getStationList(portal = 'bom', returnfields = c('station_id', 'station_no', 'station_name', 'site_id', 'station_latitude', 'station_longitude'))

namevec <- c('station_id', 'station_no', 'station_name', 'site_id', 'station_latitude', 'station_longitude')
expect_equal(names(bomout), namevec)
  expect_true(nrow(bomout) > 132000) # The actual number keeps changing. Currently 132205
})
