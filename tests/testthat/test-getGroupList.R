test_that("simple works", {
  bomout <- getGroupList(portal = 'bom')
  expect_snapshot_value(names(bomout))
  expect_equal(nrow(bomout), 8)

})
