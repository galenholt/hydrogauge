get_datasources_by_site <- function(baseURL = "https://data.water.vic.gov.au/cgi/webservice.exe?",
                                    site_list) {

  # site_list needs to be a comma separated length-1 vector
  site_list <- paste(site_list, sep = ', ', collapse = ', ')

  # The json request needs a paramlist
  paramlist <- list("function" = 'get_datasources_by_site',
                    "version" = "1",
                    "params" = list("site_list" = site_list))

  # make the request and response
  response_body <- httr2::request(baseURL) |>
    httr2::req_body_json(paramlist) |>
    httr2::req_perform() |>
    httr2::resp_body_json(check_type = FALSE)


  # unpack the list
  bodytib <- tibble::as_tibble(response_body[2]) |> # the [2] drops the error column
    tidyr::unnest_longer(col = tidyselect::where(is.list)) |> # error and a `return` list
    tidyr::unnest_wider(col = tidyselect::where(is.list)) |> # error, site, and a `datasources` list
    tidyr::unnest_longer(col = tidyselect::where(is.list)) # fully unpacked into a long df

  # rename- the plurals are weird and cause issues with sites x datasource
  names(bodytib)[names(bodytib) == 'datasources'] <- 'datasource'

  return(bodytib)

}

#' Title
#'
#' @param baseURL
#' @param datasources character vector, 'A', 'TELEM', 'TELEMCOPY'. If multiple, c('A', 'TELEM')
#'
#' @return
#' @export
#'
#' @examples
get_sites_by_datasource <- function(baseURL = "https://data.water.vic.gov.au/cgi/webservice.exe?",
                                    datasources) {

  # The json request needs a paramlist
  paramlist <- list("function" = 'get_sites_by_datasource',
                    "version" = "1",
                    "params" = list("datasources" = datasources))

  # make the request and response
  response_body <- httr2::request(baseURL) |>
    httr2::req_body_json(paramlist) |>
    httr2::req_perform() |>
    httr2::resp_body_json(check_type = FALSE)


  # unpack the list
  bodytib <- tibble::as_tibble(response_body[2]) |> # the [2] drops the error column
    tidyr::unnest_longer(col = tidyselect::where(is.list)) |> #  `return` list
    tidyr::unnest_wider(col = tidyselect::where(is.list)) |> # site, and a `datasources` list
    tidyr::unnest_longer(col = tidyselect::where(is.list)) # fully unpacked into a long df

  # rename- the plurals are weird and cause issues with datasource x site
  names(bodytib)[names(bodytib) == 'sites'] <- 'site'

  return(bodytib)

}

plot_datasources_by_site <- function(ds_by_site, returntype = 'plot') {

  # some minor updates needed for this to work for site x datasource

  exist_table <- table(ds_by_site$site, ds_by_site$datasource)

  if (returntype == 'plot') {
    allopts <- ds_by_site %>%
      tidyr::expand(site, datasource)

    ds_in_data <- ds_by_site %>%
      mutate(indata = TRUE) %>%
      dplyr::right_join(allopts) %>%
      dplyr::mutate(indata = ifelse(is.na(indata), FALSE, indata))

    data_gg <- ggplot2::ggplot(ds_in_data,
                               aes(x = datasource, y = site, fill = indata)) +
      ggplot2::geom_tile(colour="white", linewidth=0.25) +
      ggplot2::scale_fill_discrete(type = c('firebrick', 'dodgerblue')) +
      ggplot2::labs(fill = NULL)

    return(data_gg)
  }

  # Why wouldn't the user just make this?
  if (returntype == 'table') {
    data_tab <- table(ds_by_site$site, ds_by_site$datasource)
  }
}
