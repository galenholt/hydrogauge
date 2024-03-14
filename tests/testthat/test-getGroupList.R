test_that("simple works", {
  bomout <- getGroupList(portal = 'bom')
  expect_snapshot(names(bomout))
  expect_equal(nrow(bomout), 8)

})
