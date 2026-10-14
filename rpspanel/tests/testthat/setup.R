# Keep the download cache out of the user's directory during tests.
withr::local_options(
  rpspanel.cache_dir = file.path(tempdir(), "rpspanel-test-cache"),
  .local_envir = teardown_env()
)
withr::local_envvar(
  EIA_API_KEY = "test-eia-key", BEA_API_KEY = "test-bea-key",
  .local_envir = teardown_env()
)
