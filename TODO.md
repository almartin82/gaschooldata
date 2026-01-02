# TODO - gaschooldata pkgdown build issues

## Network Timeout Error (2026-01-01)

The pkgdown build is failing due to network connectivity issues when
trying to check CRAN/Bioconductor links.

### Error Details

    Error in `httr2::req_perform(req)`:
    ! Failed to perform HTTP request.
    Caused by error in `curl::curl_fetch_memory()`:
    ! Timeout was reached [cloud.r-project.org]:
    Connection timed out after 10001 milliseconds

### Stack Trace

The failure occurs in: 1.
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)
2. `pkgdown:::data_home_sidebar_links(pkg)` 3.
`pkgdown:::cran_link(pkg$package)` 4. `httr2::req_perform(req)`

### Notes

- This is a transient network issue, not a package configuration problem
- The package does not have vignettes, so no vignette-related fixes are
  needed
- ICMP ping to cloud.r-project.org works, but HTTP requests via
  httr2/curl are timing out
- This may be related to firewall/proxy settings or curl library
  configuration
- Try running the build again when network conditions improve
- The GitHub Actions CI/CD workflow should succeed if run on GitHub’s
  infrastructure
