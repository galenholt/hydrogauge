redfun <- function(x) {
  x <- x |>
    gsub_response("www.bom.gov.au/waterdata", "b/") |>
    gsub_response("realtimedata.waternsw.com.au/cgi/", "n/") |>
    gsub_response("data.water.vic.gov.au/WMIS/cgi/", "v/") |>
    gsub_response("water-monitoring.information.qld.gov.au/cgi", "q/") |>
    # why doesn't this one do anything?
    gsub_response("webservice.exe.json", 'w')

  return(x)
}



set_redactor(redfun)
