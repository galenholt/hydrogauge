test_that("issues with mdba", {
  reqoutq <- find_hydstra_request(portal = 'qld',
                                 gauge = '422211A',
                                 var_list = '141',
                                 timeunit = 'day',
                                 statistic = 'mean',
                                 datasource = 'A')

  reqoutv <- find_hydstra_request(portal = 'vic',
                                 gauge = '407249',
                                 var_list = '141',
                                 timeunit = 'day',
                                 statistic = 'mean',
                                 datasource = 'A')

  reqoutn <- find_hydstra_request(portal = 'nsw',
                                 gauge = '422004',
                                 var_list = '100',
                                 timeunit = 'day',
                                 statistic = 'mean',
                                 datasource = 'A')

  expect_snapshot(reqoutn |> dplyr::select(-period_end))
  expect_snapshot(reqoutv |> dplyr::select(-period_end))
  expect_snapshot(reqoutn |> dplyr::select(-period_end))

})


test_that("double vars", {
  # This one (and some others) have a weird return
  reqoutnF <- find_hydstra_request(portal = 'nsw',
                                  gauge = '421001',
                                  var_list = '141',
                                  timeunit = 'day',
                                  statistic = 'mean',
                                  datasource = 'A',
                                  ignore_fromderived = FALSE)

  # This should fix
  reqoutnT <- find_hydstra_request(portal = 'nsw',
                                  gauge = '421001',
                                  var_list = '141',
                                  timeunit = 'day',
                                  statistic = 'mean',
                                  datasource = 'A',
                                  ignore_fromderived = TRUE)

  # but sometimes nothing returns when we don't ask for the 140-141s
  reqoutnO <- find_hydstra_request(portal = 'nsw',
                                  gauge = '425022',
                                  var_list = 130,
                                  timeunit = 'day',
                                  statistic = 'mean',
                                  datasource = 'A',
                                  ignore_fromderived = TRUE)

  expect_snapshot(reqoutnF)
  expect_snapshot(reqoutnT)
  expect_snapshot(reqoutnO)


})
