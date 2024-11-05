#' Gets the available datasources for each site
#'
#' As far as I can tell, these will be "A", "TELEM", or "TELEMCOPY", but haven't
#' checked all sites
#'
#' @inheritParams get_ts_traces
#'
#' @return a tibble of the sites and datasources present
#' @export
#'
#' @examples
#' checkdata <- get_datasources_by_site(portal = 'vic', site_list = c("233217, 405328, 405331, 405837"))
get_datasources_by_site <- function(portal,
                                    site_list) {

  baseURL <- parse_url(portal)

  # site_list needs to be a comma separated length-1 vector
  site_list <- paste(site_list, sep = ', ', collapse = ', ')

  # The json request needs a api_body_list
  api_body_list <- list("function" = 'get_datasources_by_site',
                    "version" = "1",
                    "params" = list("site_list" = site_list))

  # hit the api
  response_body <- get_response(baseURL, api_body_list)


  # unpack the list
  bodytib <- tibble::as_tibble(response_body$return) |> # the [2] drops the error column
    # tidyr::unnest_longer(col = tidyselect::where(is.list)) |> # error and a `return` list
    tidyr::unnest_wider(col = tidyselect::where(is.list)) |> # error, site, and a `datasources` list
    tidyr::unnest_longer(col = tidyselect::where(is.list)) # fully unpacked into a long df

  # rename- the plurals are weird and cause issues with sites x datasource
  names(bodytib)[names(bodytib) == 'datasources'] <- 'datasource'

  return(bodytib)

}

#' Plot heatmap of which sites have which datasource
#'
#' Needs work to make more general to feed it more than a few sites
#'
#' @param ds_by_site tibble with `site` and `datasource` columns
#' @param returntype `'plot'` or `'table'` Plot much more useful- not sure why the user wouldn't just make a table.
#'
#' @return a ggplot, typically
#' @export
#'
plot_datasources_by_site <- function(ds_by_site, returntype = 'plot') {

  # some minor updates needed for this to work for site x datasource

  exist_table <- table(ds_by_site$site, ds_by_site$datasource)

  if (returntype == 'plot') {
    allopts <- ds_by_site |>
      tidyr::expand(site, datasource)

    ds_in_data <- ds_by_site |>
      dplyr::mutate(indata = TRUE) |>
      dplyr::right_join(allopts) |>
      dplyr::mutate(indata = ifelse(is.na(indata), FALSE, indata))

    data_gg <- ggplot2::ggplot(ds_in_data,
                               ggplot2::aes(x = datasource, y = site, fill = indata)) +
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
