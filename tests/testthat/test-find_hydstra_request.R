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
})
