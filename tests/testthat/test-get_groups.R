test_that("get_groups returns a tibble with the right names", {
  grps <- get_groups(site_list = "233217")

  expect_true("tbl_df" %in% class(grps))
  expect_equal(names(grps), c("group_decode", "group", "value", "value_decode", "stations"))
})


test_that("get_groups works with multiple groups comma sep", {
  grps <- get_groups(site_list = "233217, 405328")

  expect_true("tbl_df" %in% class(grps))
  expect_equal(names(grps), c("group_decode", "group", "value", "value_decode", "stations"))
})

test_that("get_groups works with multiple groups c() together", {
  grps <- get_groups(site_list = c("233217", "405328"))

  expect_true("tbl_df" %in% class(grps))
  expect_equal(names(grps), c("group_decode", "group", "value", "value_decode", "stations"))
})
