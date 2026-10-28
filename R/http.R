rpspanel_user_agent <- function() {
  paste0("rpspanel/", utils::packageVersion("rpspanel"),
         " (https://github.com/adebayomoses/rpspanel)")
}

build_request <- function(url, query = list()) {
  req <- httr2::request(url)
  req <- do.call(
    httr2::req_url_query,
    c(list(req), query, list(.multi = "explode"))
  )
  req <- httr2::req_user_agent(req, rpspanel_user_agent())
  req <- httr2::req_timeout(req, 120)
  # EIA's gateway returns sporadic 500s that succeed on retry
  transient <- function(resp) {
    httr2::resp_status(resp) %in% c(429, 500, 502, 503, 504)
  }
  httr2::req_retry(req, max_tries = 4, is_transient = transient)
}

# All network traffic goes through here so tests can mock a single function.
perform_json <- function(req, what) {
  resp <- tryCatch(
    httr2::req_perform(req),
    error = function(e) {
      cli::cli_abort(
        c("Could not download {what}.",
          x = conditionMessage(e),
          i = paste0("Check your internet connection and API key, ",
                     "or use cached data.")),
        class = "rpspanel_http_error", parent = e
      )
    }
  )
  # Some APIs answer errors (such as a missing key) with an HTML page
  if (!grepl("json", httr2::resp_content_type(resp) %||% "", fixed = TRUE)) {
    key_error <- identical(
      httr2::resp_header(resp, "X-DataWebAPI-KeyError"), "1"
    ) || grepl("(missing|invalid)_key", httr2::resp_url(resp))
    hint <- if (key_error) {
      paste0("The service rejected the request because the API key is ",
             "missing or invalid.")
    } else {
      paste0("The service returned a web page instead of data; it may be ",
             "down or the request invalid.")
    }
    cli::cli_abort(c("Could not download {what}.", x = hint),
                   class = "rpspanel_http_error")
  }
  httr2::resp_body_json(resp, simplifyVector = TRUE)
}

get_api_key <- function(key, env, service, signup) {
  key <- key %||% ""
  if (!nzchar(key)) {
    key <- Sys.getenv(env)
  }
  if (!nzchar(key)) {
    cli::cli_abort(
      c("No {service} API key found.",
        i = "Register for a free key at {.url {signup}}.",
        i = paste0("Then add {.code {env}=<your key>} to your ",
                   "{.file .Renviron} file.")),
      class = "rpspanel_no_key"
    )
  }
  key
}
