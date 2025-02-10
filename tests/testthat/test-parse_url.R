test_that("parse_url works", {

  with_mock_dir('mocked_responses/parse_url/vic',
  expect_equal(parse_url('vic'), "https://data.water.vic.gov.au/WMIS/cgi/webservice.exe?")
  )
  with_mock_dir('mocked_responses/parse_url/nsw',
  expect_equal(parse_url('nsw'), "https://realtimedata.waternsw.com.au/cgi/webservice.exe?")
  )
  with_mock_dir('mocked_responses/parse_url/qld',
  expect_equal(parse_url('qld'),  "https://water-monitoring.information.qld.gov.au/cgi/webservice.exe?")
  )
  with_mock_dir('mocked_responses/parse_url/bom',
  expect_equal(parse_url('bom'), "http://www.bom.gov.au/waterdata/services")
  )
  with_mock_dir('mocked_responses/parse_url/sa',
  expect_equal(parse_url('sa'), "http://www.bom.gov.au/waterdata/services")
  )

  # capitals
  with_mock_dir('mocked_responses/parse_url/NSW',
  expect_equal(parse_url('NSW'), "https://realtimedata.waternsw.com.au/cgi/webservice.exe?")
  )

  # bare url
  with_mock_dir('mocked_responses/parse_url/bare',
  expect_equal(parse_url('http://httpbin.org/get'), "http://httpbin.org/get")
  )

  # not a url
  expect_error(parse_url('not_a_url'))


})
