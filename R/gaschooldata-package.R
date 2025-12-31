#' gaschooldata: Fetch and Process Georgia School Data
#'
#' Downloads and processes school data from the Georgia Department of Education
#' (GaDOE) and the Governor's Office of Student Achievement (GOSA). Provides
#' functions for fetching enrollment data with demographic breakdowns and
#' transforming it into tidy format for analysis.
#'
#' @section Main functions:
#' \describe{
#'   \item{\code{\link{fetch_enr}}}{Fetch enrollment data for a school year}
#'   \item{\code{\link{fetch_enr_multi}}}{Fetch enrollment data for multiple years}
#'   \item{\code{\link{tidy_enr}}}{Transform wide data to tidy (long) format}
#'   \item{\code{\link{id_enr_aggs}}}{Add aggregation level flags}
#'   \item{\code{\link{enr_grade_aggs}}}{Create grade-level aggregations}
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
#' Data is sourced from two Georgia agencies:
#' \itemize{
#'   \item GOSA: \url{https://gosa.georgia.gov/dashboards-data-report-card/downloadable-data}
#'   \item GaDOE: \url{https://georgiainsights.gadoe.org/data-downloads/}
#' }
#'
#' @docType package
#' @name gaschooldata-package
#' @aliases gaschooldata
#' @keywords internal
"_PACKAGE"

#' Pipe operator
#'
#' See \code{magrittr::\link[magrittr:pipe]{\%>\%}} for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom dplyr %>%
#' @usage lhs \%>\% rhs
#' @param lhs A value or the magrittr placeholder.
#' @param rhs A function call using the magrittr semantics.
#' @return The result of calling `rhs(lhs)`.
NULL
