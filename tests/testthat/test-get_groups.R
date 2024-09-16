test_that("get_groups returns a tibble with the right names", {
  grps <- get_groups(portal = 'vic', site_list = "233217")

  expect_true("tbl_df" %in% class(grps))
  expect_equal(names(grps), c("group_decode", "group", "value", "value_decode", "stations"))
})


test_that("get_groups works with multiple groups comma sep", {
  grps <- get_groups(portal = 'vic', site_list = "233217, 405328")

  expect_true("tbl_df" %in% class(grps))
  expect_equal(names(grps), c("group_decode", "group", "value", "value_decode", "stations"))
})

test_that("get_groups works with multiple groups c() together", {
  grps <- get_groups(portal = 'vic', site_list = c("233217", "405328"))

  expect_true("tbl_df" %in% class(grps))
  expect_equal(names(grps), c("group_decode", "group", "value", "value_decode", "stations"))
})

test_that("states", {
  vds <- get_groups(portal = 'vic', site_list = "233217")
  qds <- get_groups(portal = 'qld', site_list = "422211A")
  nds <- get_groups(portal = 'nsw', site_list = "422004")

  expect_snapshot(vds)
  expect_snapshot(qds)
  expect_snapshot(nds)
})

test_that("groups", {
  # This works, but it's unclear what this means.
  vdsg <- get_groups(portal = 'vic', site_list = "GROUP(WEB_SW_TELEM)")
  qdsg <- get_groups(portal = 'qld', site_list = "GROUP(OPEN_STATIONS)")
  ndsg <- get_groups(portal = 'nsw', site_list = "GROUP(WATER_QUALITY)")

  expect_snapshot(vdsg)
  expect_snapshot(qdsg)
  expect_snapshot(ndsg)
})
