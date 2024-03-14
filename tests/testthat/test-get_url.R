test_that("parse_url works", {

  expect_equal(parse_url('vic'), "https://data.water.vic.gov.au/cgi/webservice.exe?")
  expect_equal(parse_url('nsw'), "https://realtimedata.waternsw.com.au/cgi/webservice.exe?")
  expect_equal(parse_url('qld'),  "https://water-monitoring.information.qld.gov.au/cgi/webservice.exe?")
  expect_equal(parse_url('bom'), "http://www.bom.gov.au/waterdata/services")
  expect_equal(parse_url('sa'), "http://www.bom.gov.au/waterdata/services")

  # capitals
  expect_equal(parse_url('NSW'), "https://realtimedata.waternsw.com.au/cgi/webservice.exe?")

  # bare url
  expect_equal(parse_url('http://httpbin.org/get'), "http://httpbin.org/get")

  # not a url
  expect_error(parse_url('not_a_url'))

})
