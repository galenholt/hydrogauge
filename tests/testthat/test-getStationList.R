# Everything
return_all <- c('station_no', 'station_id', 'station_uuid', 'station_name', 'catchment_no', 'catchment_id', 'catchment_name', 'station_latitude', 'station_longitude', 'station_carteasting', 'station_cartnorthing', 'station_local_x', 'station_local_y', 'site_no', 'site_id', 'site_uuid', 'site_name', 'parametertype_id', 'parametertype_name', 'parametertype_shortname', 'stationparameter_name', 'stationparameter_no', 'stationparameter_id', 'parametertype_longname', 'object_type', 'object_type_shortname', 'station_georefsystem', 'station_longname', 'station_area_wkt', 'station_area_wkt_org', 'river_id', 'river_name', 'area_id', 'area_name', 'TimeZone', 'ShortName_CodeSpace', 'LongName_CodeSpace', 'StationName_CodeSpace', 'WDTF_regulation_shortname_combination', 'station_diary', 'WDTF_REGULATION_WCD', 'DATA_OWNER', 'WDTF_REGULATION_WCL', 'station_diary_status', 'ngr_letter', 'admin_level', 'WDTF_REGULATION', 'region_district', 'WDTF_REGULATIONS', 'admin_name', 'REGULATION_NAME', 'DATA_OWNER_NAME')
# default
returnfields <- c('station_no', 'station_id', 'station_name', 'station_latitude', 'station_longitude', 'station_carteasting', 'station_cartnorthing', 'site_no', 'site_id', 'site_name', 'parametertype_id', 'parametertype_name', 'parametertype_shortname', 'stationparameter_name', 'stationparameter_no', 'stationparameter_id', 'parametertype_longname', 'object_type', 'object_type_shortname', 'station_georefsystem', 'station_longname')

test_that("simple works", {
  with_mock_dir('mocked_responses/getStationList/simple',
  bomout <- getStationList(portal = 'bom',
                           station_no = c('410730', 'A4260505'))
  )
  expect_equal(names(bomout), returnfields)
  expect_equal(nrow(bomout), 204)
})

test_that("all returns", {
  with_mock_dir('mocked_responses/getStationList/all',
  bomout <- getStationList(portal = 'bom',
                           returnfields = 'all',
                           station_no = c('410730', 'A4260505'))
  )

  # From the code, but the ca_* expand at the end
  expect_equal(names(bomout), return_all)
  expect_equal(nrow(bomout), 204)
})

test_that("extra_list", {
  with_mock_dir('mocked_responses/getStationList/extra',
  bomout <- getStationList(portal = 'bom',
                           extra_list = list(station_name = 'River Murray*')))

  expect_equal(names(bomout), returnfields)
  expect_equal(nrow(bomout), 2797)
})

test_that("groups in extra_list", {
  with_mock_dir('mocked_responses/getStationList/groupextra',
  bomout <- getStationList(portal = 'bom',
                           extra_list = list(stationgroup_id = '20017550'))
  )
  expect_equal(names(bomout), returnfields)
  expect_equal(nrow(bomout), 12182)
})

test_that("returnfields and all data", {
  with_mock_dir('mocked_responses/getStationList/returnfields',
  bomout <- getStationList(portal = 'bom',
                           returnfields = c('station_id', 'station_no', 'station_name',
                                            'site_id', 'station_latitude', 'station_longitude'))
  )

namevec <- c('station_id', 'station_no', 'station_name', 'site_id', 'station_latitude', 'station_longitude')
expect_equal(names(bomout), namevec)
  expect_true(nrow(bomout) > 132000) # The actual number keeps changing. Currently 132205
})

test_that("all returnfields", {

  # According to kisters, these exist
  all_return <- c('station_no', 'station_id', 'station_uuid', 'station_name', 'catchment_no',
                  'catchment_id', 'catchment_name', 'station_latitude', 'station_longitude',
                  'station_carteasting', 'station_cartnorthing',
                  'station_local_x', 'station_local_y', 'station_timezone', 'station_utcoffset',
                  'station_posmethod', 'site_no', 'site_id', 'site_uuid',
                  'site_name', 'site_longname', 'parametertype_id', 'parametertype_name',
                  'parametertype_shortname', 'stationparameter_name',
                  'stationparameter_no', 'stationparameter_id', 'parametertype_longname',
                  'object_type', 'object_type_shortname', 'station_georefsystem',
                  'station_longname', 'station_area_wkt', 'station_area_wkt_org',
                  'river_id', 'river_name', 'area_id', 'area_name', 'ca_site', 'ca_sta')
  # I get http 500 errors unless I cut to
  sub_return <- all_return[c(1:13, 17:20, 22:40)]
  with_mock_dir('mocked_responses/getStationList/all_return',
  bomout <- getStationList(portal = 'bom',
                           station_no = c('410730', 'A4260505'),
                           returnfields = sub_return)
  )

  expect_equal(names(bomout), return_all)
  expect_equal(nrow(bomout), 204)

  # get the data owner- useful for later
  # According to kisters, these exist
  ownerreturn <- c('station_no', 'station_name', 'station_latitude', 'station_longitude',
                   'parametertype_id', 'parametertype_name', 'ca_sta')

  with_mock_dir('mocked_responses/getStationList/owner',
  bomout_own <- getStationList(portal = 'bom',
                               extra_list = list(station_name = 'River Murray*'),
                           returnfields = ownerreturn)
  )

  # expands the ca_
  expect_equal(names(bomout), return_all)
})
