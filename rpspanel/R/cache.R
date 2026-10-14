#' Manage the download cache
#'
#' Downloads are cached as `.rds` files so that a panel can be rebuilt
#' offline and so that a data vintage stays pinned until you refresh it.
#' `rps_cache_dir()` returns the cache directory, `rps_cache_list()` lists
#' cached downloads and `rps_cache_clear()` deletes them.
#'
#' The cache directory defaults to `tools::R_user_dir("rpspanel", "cache")`
#' and can be changed with `options(rpspanel.cache_dir = "path")`.
#'
#' @return `rps_cache_dir()`: a path. `rps_cache_list()`: a data frame with
#'   `file`, `source`, `retrieved` and `size_kb`. `rps_cache_clear()`: the
#'   number of files removed, invisibly.
#' @name cache
#' @examples
#' rps_cache_dir()
NULL

#' @rdname cache
#' @export
rps_cache_dir <- function() {
  getOption("rpspanel.cache_dir", tools::R_user_dir("rpspanel", which = "cache"))
}

#' @rdname cache
#' @export
rps_cache_list <- function() {
  files <- list.files(rps_cache_dir(), pattern = "\\.rds$", full.names = TRUE)
  if (length(files) == 0) {
    return(data.frame(file = character(), source = character(),
                      retrieved = character(), size_kb = numeric()))
  }
  meta <- lapply(files, function(f) {
    obj <- tryCatch(readRDS(f), error = function(e) NULL)
    c(attr(obj, "rps_source") %||% NA_character_,
      attr(obj, "rps_retrieved") %||% NA_character_)
  })
  data.frame(
    file = basename(files),
    source = vapply(meta, `[`, "", 1),
    retrieved = vapply(meta, `[`, "", 2),
    size_kb = round(file.size(files) / 1024, 1),
    stringsAsFactors = FALSE
  )
}

#' @rdname cache
#' @export
rps_cache_clear <- function() {
  files <- list.files(rps_cache_dir(), pattern = "\\.rds$", full.names = TRUE)
  unlink(files)
  cli::cli_inform("Removed {length(files)} cached file{?s}.")
  invisible(length(files))
}

cache_key <- function(...) {
  s <- paste(..., sep = "|", collapse = "|")
  f <- tempfile()
  on.exit(unlink(f))
  writeLines(s, f, useBytes = TRUE)
  unname(tools::md5sum(f))
}

cache_path <- function(key) {
  file.path(rps_cache_dir(), paste0(key, ".rds"))
}

cache_get <- function(key) {
  path <- cache_path(key)
  if (!file.exists(path)) {
    return(NULL)
  }
  max_age <- getOption("rpspanel.cache_max_age", Inf)
  age_days <- as.numeric(difftime(Sys.time(), file.mtime(path), units = "days"))
  if (age_days > max_age) {
    return(NULL)
  }
  tryCatch(readRDS(path), error = function(e) NULL)
}

cache_set <- function(key, value) {
  dir <- rps_cache_dir()
  ok <- tryCatch({
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    saveRDS(value, cache_path(key))
    TRUE
  }, error = function(e) FALSE, warning = function(w) FALSE)
  if (!ok) {
    cli::cli_warn("Could not write to the cache directory {.path {dir}}.")
  }
  invisible(value)
}

# Run `fetch()` unless a cached copy exists. The value gets "rps_source" and
# "rps_retrieved" attributes so vintages can be reported later.
with_cache <- function(key, source, fetch, cache = TRUE, refresh = FALSE) {
  if (cache && !refresh) {
    hit <- cache_get(key)
    if (!is.null(hit)) {
      return(hit)
    }
  }
  value <- fetch()
  attr(value, "rps_source") <- source
  attr(value, "rps_retrieved") <- now_utc()
  if (cache) {
    cache_set(key, value)
  }
  value
}
