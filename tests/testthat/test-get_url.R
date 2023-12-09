test_that("get_url works", {

  expect_equal(get_url('vic'), "https://data.water.vic.gov.au/cgi/webservice.exe?")
  expect_equal(get_url('nsw'), "https://realtimedata.waternsw.com.au/cgi/webservice.exe?")
  expect_equal(get_url('qld'),  "https://water-monitoring.information.qld.gov.au/cgi/webservice.exe?")
  expect_equal(get_url('bom'), "http://www.bom.gov.au/waterdata/services")
  expect_equal(get_url('sa'), "http://www.bom.gov.au/waterdata/services")

  expect_equal(get_url('NSW'), "https://realtimedata.waternsw.com.au/cgi/webservice.exe?")

})
