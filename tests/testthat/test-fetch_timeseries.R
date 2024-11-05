test_that("simple check", {
  bomout <- fetch_timeseries(portal = 'bom',
                                   gauge = c('410730', 'A4260505'),
                             variable = 'discharge',
                             datatype = 'QaQc',
                             units = 'ML/d',
                             timeunit = 'Daily', #AsStored is the raw data
                             statistic = 'Mean',
                                   start_time = '2020-01-01 01:30:30',
                                   end_time = '20200105')

  # use datatype for datasource
  vicout <- fetch_timeseries(portal = 'vic',
                                          gauge = "233217",
                                          variable = 'discharge',
                             datatype = 'A',
                             units = 'ML/d',
                                          start_time = '20200101',
                                          end_time = '20200105',
                                          timeunit = 'Daily',
                                          statistic = 'mean')

  # will want to test various combos of gauge, portal, and gauge_portal.
  # ideally, can just feed a list of gauges and it'll go get them. but it does need to know the portals. Start with manual specicfication adn then figure out the auto-finding (with specific reference ot australia and not )
  # should also have a collapse for speed vs split for safety option.
  multiout <- fetch_timeseries(portal = c('vic', 'bom', 'nsw'),
                               gauge_portal = list(vic = c("233217", "405328"),
                                            bom = c('410730', 'A4260505', '615026'),
                                            nsw = '412078'),
                               start_time = '20200101',
                               end_time = '20200105',
                               variable = 'discharge',
                               units = 'ML/d',
                               datatype = c('A', 'QaQc', 'A'),
                               timeunit = 'day',
                               statistic = 'mean',
                               robustness = 'speed')


})


test_that("doubled gauges warn", {
  # Should be two warnings here.
  expect_snapshot(multiout <- fetch_timeseries(portal = c('vic', 'bom', 'nsw'),
                             gauge_portal = list(vic = c("404224", "405328", "405331"),
                                                 bom = c('410730', 'A4260505', '404224', '412078'),
                                                 nsw = '412078'),
                             start_time = '20200101',
                             end_time = '20200105',
                             variable = 'discharge',
                             units = 'ML/d',
                             datatype = c('A', 'QaQc', 'A'),
                             timeunit = 'day',
                             statistic = 'mean',
                             robustness = 'speed',
                             check_output = TRUE))


})

test_that("missings don't mess things up", {
  # stuff up gauge names, with one good
  expect_snapshot(missout1 <- fetch_timeseries(portal = c('vic', 'bom'),
                               gauge_portal = list(vic = c("233217", "40532"),
                                                   bom = c('410730', '40532')),
                               start_time = '20200101',
                               end_time = '20200105',
                               variable = 'discharge',
                               units = 'ML/d',
                               datatype = c('A', 'QaQc'),
                               timeunit = 'day',
                               statistic = 'mean',
                               robustness = 'speed',
                               check_output = TRUE))

  # none good
  expect_snapshot(missout2 <- fetch_timeseries(portal = c('vic', 'bom'),
                               gauge_portal = list(vic = c("23317", "40532"),
                                                   bom = c('41030', '40532')),
                               start_time = '20200101',
                               end_time = '20200105',
                               variable = 'discharge',
                               units = 'ML/d',
                               datatype = c('A', 'QaQc'),
                               timeunit = 'day',
                               statistic = 'mean',
                               robustness = 'speed',
                               check_output = TRUE))


})

