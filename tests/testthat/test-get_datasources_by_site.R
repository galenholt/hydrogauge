test_that("states datasources by site", {
  with_mock_dir('mocks/get_datasources_by_site/vic',
  vds <- get_datasources_by_site(portal = 'vic', site_list = "233217")
  )
  with_mock_dir('mocks/get_datasources_by_site/qld',
  qds <- get_datasources_by_site(portal = 'qld', site_list = "422211A")
  )
  with_mock_dir('mocks/get_datasources_by_site/nsw',
  nds <- get_datasources_by_site(portal = 'nsw', site_list = "422004")
  )

  expect_snapshot(vds)
  expect_snapshot(qds)
  expect_snapshot(nds)
})


# test_that("states datasources by site", {
#   vdd <- get_sites_by_datasource(portal = 'vic', datasources = 'A')
#   qdd <- get_sites_by_datasource(portal = 'qld', datasources = 'A')
#   ndd <- get_sites_by_datasource(portal = 'nsw', datasources = 'A')
#
#   expect_snapshot(vdd)
#   expect_snapshot(qdd)
#   expect_snapshot(ndd)
# })
