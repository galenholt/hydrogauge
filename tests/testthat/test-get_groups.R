test_that("get_groups returns a tibble with the right names", {
  with_mock_dir('mocked_responses/get_groups/simple',
  grps <- get_groups(portal = 'vic', site_list = "233217")
  )

  expect_true("tbl_df" %in% class(grps))
  expect_equal(names(grps), c("group_decode", "group", "value", "value_decode", "stations"))
})


test_that("get_groups works with multiple groups comma sep", {
  with_mock_dir('mocked_responses/get_groups/comma_sep',
  grps <- get_groups(portal = 'vic', site_list = "233217, 405328")
  )

  expect_true("tbl_df" %in% class(grps))
  expect_equal(names(grps), c("group_decode", "group", "value", "value_decode", "stations"))
})

test_that("get_groups works with multiple groups c() together", {
  with_mock_dir('mocked_responses/get_groups/c_ed',
  grps <- get_groups(portal = 'vic', site_list = c("233217", "405328"))
  )

  expect_true("tbl_df" %in% class(grps))
  expect_equal(names(grps), c("group_decode", "group", "value", "value_decode", "stations"))
})

test_that("states", {
  with_mock_dir('mocked_responses/get_groups/vic',
  vds <- get_groups(portal = 'vic', site_list = "233217"))
  with_mock_dir('mocked_responses/get_groups/qld',
  qds <- get_groups(portal = 'qld', site_list = "422211A"))
  with_mock_dir('mocked_responses/get_groups/nsw',
  nds <- get_groups(portal = 'nsw', site_list = "422004"))

  expect_snapshot(vds)
  expect_snapshot(qds)
  expect_snapshot(nds)
})

test_that("groups", {
  # This works, but it's unclear what this means.
  with_mock_dir('mocked_responses/get_groups/vicname',
  vdsg <- get_groups(portal = 'vic', site_list = "GROUP(WEB_SW_TELEM)"))
  with_mock_dir('mocked_responses/get_groups/qldname',
  qdsg <- get_groups(portal = 'qld', site_list = "GROUP(OPEN_STATIONS)"))
  with_mock_dir('mocked_responses/get_groups/nswname',
  ndsg <- get_groups(portal = 'nsw', site_list = "GROUP(WATER_QUALITY)"))

  # These change a lot, so snapshots aren't working
  expect_gt(nrow(vdsg), 15000)
  expect_gt(nrow(qdsg), 5000)
  expect_gt(nrow(ndsg), 40000)
})
