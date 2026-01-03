#' gaschooldata: Fetch and Process Georgia School Data
#'
#' Downloads and processes school data from the Governor's Office of Student
#' Achievement (GOSA). Provides functions for fetching enrollment data with
#' demographic breakdowns and transforming it into tidy format for analysis.
#'
#' @section Data Availability:
#' The package supports enrollment data from 2011 through 2024:
#' \itemize{
#'   \item 2011-2024: GOSA (full demographics and special populations)
#' }
#'
#' GOSA provides enrollment data from the 2010-11 school year through 2023-24.
#' For historical data prior to 2011, users must submit a data request directly
#' to GOSA: \url{https://gosa.georgia.gov/dashboards-data-report-card/data-requests}
#'
#' @section Main functions:
#' \describe{
#'   \item{\code{\link{fetch_enr}}}{Fetch enrollment data for a school year}
#'   \item{\code{\link{fetch_enr_multi}}}{Fetch enrollment data for multiple years}
#'   \item{\code{\link{get_available_years}}}{Get range of available years (2011-2024)}
#' }
#'
#' @section Cache functions:
#' \describe{
#'   \item{\code{\link{cache_status}}}{View cached data files}
#'   \item{\code{\link{clear_cache}}}{Remove cached data files}
#' }
#'
#' @section ID System:
#' Georgia uses a hierarchical ID system:
#' \itemize{
#'   \item District IDs: 3-4 digits (system code, e.g., 660 = Fulton County)
#'   \item School IDs: 4 digits (school number within district)
#'   \item Full school code: district + school (e.g., 660-0001)
#' }
#'
#' @section Data Sources:
#' Data is sourced exclusively from Georgia state sources:
#' \itemize{
#'   \item GOSA Downloadable Data: \url{https://gosa.georgia.gov/dashboards-data-report-card/downloadable-data}
#'   \item GOSA Data Repository: \url{https://download.gosa.ga.gov/}
#' }
#'
#' @docType package
#' @name gaschooldata-package
#' @aliases gaschooldata
#' @keywords internal
"_PACKAGE"

