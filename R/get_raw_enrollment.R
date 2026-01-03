# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data for Georgia
# schools from the Governor's Office of Student Achievement (GOSA).
#
# Data source:
# - GOSA (Governor's Office of Student Achievement) (2011-present):
#   https://gosa.georgia.gov/dashboards-data-report-card/downloadable-data
#   https://download.gosa.ga.gov/
#
# Data availability:
# - 2011-2024: Full demographics with GOSA format (enrollment by subgroup and grade)
#
# URL Pattern:
# - GOSA: https://download.gosa.ga.gov/{YEAR}/Enrollment_by_Subgroup_Metrics_{YYYY-YY}[_timestamp].csv
#
# Note: GOSA files may include timestamps in their filenames. The package attempts
# to discover the correct URL or uses known working URLs.
#
# For historical data prior to 2011, users must submit a data request to GOSA:
# https://gosa.georgia.gov/dashboards-data-report-card/data-requests
#
# ==============================================================================

#' Download raw enrollment data for Georgia
#'
#' Downloads enrollment data from the Governor's Office of Student Achievement
#' (GOSA) downloadable data repository.
#'
#' @param end_year School year end (e.g., 2023-24 = 2024). Valid range: 2011-2024
#' @return List with enrollment data frame(s)
#' @keywords internal
get_raw_enr <- function(end_year) {

  validate_year(end_year)

  message(paste("Downloading Georgia enrollment data for", end_year, "..."))
  message("  Using GOSA downloadable data...")

  raw_data <- download_gosa_data(end_year)

  raw_data
}


#' Validate year parameter
#'
#' Checks that the year is within the valid range for available data.
#' GOSA provides data from 2010-11 through 2023-24 school years.
#'
#' @param end_year School year end
#' @return NULL (throws error if invalid)
#' @keywords internal
validate_year <- function(end_year) {
  min_year <- 2011
  max_year <- 2024

  if (!is.numeric(end_year) || length(end_year) != 1) {
    stop("end_year must be a single numeric value")
  }

  if (end_year < min_year || end_year > max_year) {
    stop(paste0(
      "end_year must be between ", min_year, " and ", max_year, ".\n",
      "  - GOSA provides enrollment data from 2010-11 through 2023-24.\n",
      "  - For historical data prior to 2011, submit a GOSA data request:\n",
      "    https://gosa.georgia.gov/dashboards-data-report-card/data-requests"
    ))
  }
}


#' Get format era for a given year
#'
#' Returns the data format era for processing. All data comes from GOSA.
#'
#' @param end_year School year end
#' @return Character string indicating era (always "gosa" for supported years)
#' @keywords internal
get_format_era <- function(end_year) {
  # All supported years (2011-2024) use GOSA data format
  return("gosa")
}


#' Get available years for Georgia enrollment data
#'
#' Returns the range of years available from GOSA (Governor's Office of
#' Student Achievement). GOSA provides enrollment data from the 2010-11
#' school year (end_year = 2011) through 2023-24 (end_year = 2024).
#'
#' @return A list with components:
#'   \describe{
#'     \item{min_year}{Integer. The earliest available year (2011).}
#'     \item{max_year}{Integer. The most recent available year (2024).}
#'     \item{description}{Character. A description of the data availability.}
#'   }
#' @export
#' @examples
#' get_available_years()
#' # Returns list(min_year = 2011, max_year = 2024, description = "...")
get_available_years <- function() {
  list(
    min_year = 2011L,
    max_year = 2024L,
    description = "GOSA enrollment data (2010-11 through 2023-24 school years)"
  )
}


# ==============================================================================
# GOSA Download Functions (2011-present)
# ==============================================================================

#' Download GOSA enrollment data
#'
#' Downloads enrollment data from GOSA's downloadable data repository.
#' Uses Enrollment by Subgroup Metrics for demographics and special populations.
#'
#' @param end_year School year end (2023-24 = 2024)
#' @return List with enrollment data frame
#' @keywords internal
download_gosa_data <- function(end_year) {

  # Download subgroup data (demographics, special populations)
  message("  Downloading enrollment by subgroup data...")
  subgroup_data <- download_gosa_subgroup(end_year)

  # Download grade-level data
  message("  Downloading enrollment by grade data...")
  grade_data <- download_gosa_grade(end_year)

  # Merge subgroup and grade data
  if (!is.null(grade_data) && nrow(grade_data) > 0) {
    merged_data <- merge_gosa_data(subgroup_data, grade_data)
  } else {
    merged_data <- subgroup_data
  }

  # Add end_year column
  merged_data$end_year <- end_year

  list(
    enrollment = merged_data
  )
}


#' Download GOSA Enrollment by Subgroup data
#'
#' Downloads the Enrollment_by_Subgroup_Metrics CSV from GOSA.
#' This file contains demographic breakdowns and special population counts.
#'
#' @param end_year School year end
#' @return Data frame with subgroup enrollment data
#' @keywords internal
download_gosa_subgroup <- function(end_year) {

  school_year <- paste0(end_year - 1, "-", substr(end_year, 3, 4))

  url <- find_gosa_subgroup_url(end_year)

  if (is.null(url)) {
    stop(paste("Could not find Enrollment by Subgroup data for year", end_year))
  }

  temp_file <- tempfile(fileext = ".csv")

  tryCatch({
    response <- httr::GET(
      url,
      httr::write_disk(temp_file, overwrite = TRUE),
      httr::timeout(300),
      httr::user_agent("gaschooldata R package")
    )

    if (httr::http_error(response)) {
      stop(paste("HTTP error:", httr::status_code(response)))
    }

  }, error = function(e) {
    stop(paste("Failed to download subgroup data for year", end_year,
               "\nError:", e$message))
  })

  df <- readr::read_csv(
    temp_file,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )

  unlink(temp_file)

  # Filter to the correct school year
  if ("SCHOOL_YEAR" %in% names(df)) {
    df <- df[df$SCHOOL_YEAR == school_year, ]
  } else if ("LONG_SCHOOL_YEAR" %in% names(df)) {
    df <- df[df$LONG_SCHOOL_YEAR == school_year, ]
  }

  df
}


#' Find the correct GOSA subgroup URL for a given year
#'
#' GOSA files have timestamps in their names. This function scrapes the
#' directory listing to discover the correct URL.
#'
#' @param end_year School year end
#' @return URL string or NULL if not found
#' @keywords internal
find_gosa_subgroup_url <- function(end_year) {

  school_year <- paste0(end_year - 1, "-", substr(end_year, 3, 4))
  folder_year <- end_year

  base_url <- paste0("https://download.gosa.ga.gov/", folder_year, "/")

  # Scrape directory listing to find enrollment files
  dir_response <- try(httr::GET(base_url, httr::timeout(30)), silent = TRUE)

  if (inherits(dir_response, "try-error") || httr::http_error(dir_response)) {
    return(NULL)
  }

  dir_content <- httr::content(dir_response, as = "text", encoding = "UTF-8")

  # Pattern 1: Enrollment_by_Subgroup_Metrics_YYYY-YY_*.csv (2023+)
  subgroup_pattern <- paste0("Enrollment_by_Subgroup_Metrics_", school_year, "_[^\"]+\\.csv")
  matches <- regmatches(dir_content, gregexpr(subgroup_pattern, dir_content))[[1]]

  if (length(matches) > 0) {
    # Return the most recent file (last in sorted order by timestamp)
    latest_file <- sort(matches, decreasing = TRUE)[1]
    return(paste0(base_url, latest_file))
  }

  # Pattern 2: Enrollment_by_Subgroups_Programs_YYYY_*.csv (2015-2022)
  programs_pattern <- paste0("Enrollment_by_Subgroups_Programs_", folder_year, "_[^\"]+\\.csv")
  matches <- regmatches(dir_content, gregexpr(programs_pattern, dir_content))[[1]]

  if (length(matches) > 0) {
    latest_file <- sort(matches, decreasing = TRUE)[1]
    return(paste0(base_url, latest_file))
  }

  NULL
}


#' Download GOSA Enrollment by Grade data
#'
#' Downloads the Enrollment_by_Grade CSV from GOSA.
#' This file contains grade-level enrollment counts.
#'
#' @param end_year School year end
#' @return Data frame with grade enrollment data, or NULL if not available
#' @keywords internal
download_gosa_grade <- function(end_year) {

  school_year <- paste0(end_year - 1, "-", substr(end_year, 3, 4))

  url <- find_gosa_grade_url(end_year)

  if (is.null(url)) {
    message("    Note: Grade-level data not found separately; will use total enrollment only")
    return(NULL)
  }

  temp_file <- tempfile(fileext = ".csv")

  tryCatch({
    response <- httr::GET(
      url,
      httr::write_disk(temp_file, overwrite = TRUE),
      httr::timeout(300),
      httr::user_agent("gaschooldata R package")
    )

    if (httr::http_error(response)) {
      message("    Note: Grade-level data download failed; using total enrollment only")
      return(NULL)
    }

  }, error = function(e) {
    message("    Note: Grade-level data not available; using total enrollment only")
    return(NULL)
  })

  df <- readr::read_csv(
    temp_file,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )

  unlink(temp_file)

  # Filter to the correct school year
  if ("SCHOOL_YEAR" %in% names(df)) {
    df <- df[df$SCHOOL_YEAR == school_year, ]
  } else if ("LONG_SCHOOL_YEAR" %in% names(df)) {
    df <- df[df$LONG_SCHOOL_YEAR == school_year, ]
  }

  df
}


#' Find the correct GOSA grade-level URL for a given year
#'
#' GOSA files have timestamps in their names. This function scrapes the
#' directory listing to discover the correct URL.
#'
#' @param end_year School year end
#' @return URL string or NULL if not found
#' @keywords internal
find_gosa_grade_url <- function(end_year) {

  school_year <- paste0(end_year - 1, "-", substr(end_year, 3, 4))
  folder_year <- end_year

  base_url <- paste0("https://download.gosa.ga.gov/", folder_year, "/")

  # Scrape directory listing to find grade files
  dir_response <- try(httr::GET(base_url, httr::timeout(30)), silent = TRUE)

  if (inherits(dir_response, "try-error") || httr::http_error(dir_response)) {
    return(NULL)
  }

  dir_content <- httr::content(dir_response, as = "text", encoding = "UTF-8")

  # Pattern: Enrollment_by_Grade_YYYY-YY_*.csv
  grade_pattern <- paste0("Enrollment_by_Grade_", school_year, "_[^\"]+\\.csv")
  matches <- regmatches(dir_content, gregexpr(grade_pattern, dir_content))[[1]]

  if (length(matches) > 0) {
    # Return the most recent file (last in sorted order by timestamp)
    latest_file <- sort(matches, decreasing = TRUE)[1]
    return(paste0(base_url, latest_file))
  }

  NULL
}


#' Merge GOSA subgroup and grade data
#'
#' The grade data has multiple rows per entity (one per grade level),
#' while subgroup data has one row per entity. Merging would cause
#' row explosion. For now, we pivot grade data to wide format to
#' add grade-level enrollment columns to the subgroup data.
#'
#' @param subgroup_df Subgroup enrollment data
#' @param grade_df Grade-level enrollment data
#' @return Merged data frame with grade-level enrollment counts
#' @keywords internal
merge_gosa_data <- function(subgroup_df, grade_df) {

  # Check for required columns in grade data
  if (!all(c("SCHOOL_DSTRCT_CD", "INSTN_NUMBER", "GRADE_LEVEL", "ENROLLMENT_COUNT") %in% names(grade_df))) {
    return(subgroup_df)
  }

  # Get Fall enrollment period (Fall snapshot, not Spring)
  if ("ENROLLMENT_PERIOD" %in% names(grade_df)) {
    grade_df <- grade_df[grepl("Fall", grade_df$ENROLLMENT_PERIOD, ignore.case = TRUE), ]
  }

  # Pivot grade data to wide format (one row per entity)
  grade_wide <- tryCatch({
    # Suppress warnings from "TFS" (too few students) values
    grade_df$ENROLLMENT_COUNT <- suppressWarnings(as.numeric(grade_df$ENROLLMENT_COUNT))
    grade_df$GRADE_LEVEL <- paste0("GRADE_", gsub("[^A-Za-z0-9]", "_", grade_df$GRADE_LEVEL))

    tidyr::pivot_wider(
      grade_df[, c("SCHOOL_DSTRCT_CD", "INSTN_NUMBER", "GRADE_LEVEL", "ENROLLMENT_COUNT")],
      names_from = "GRADE_LEVEL",
      values_from = "ENROLLMENT_COUNT",
      values_fn = sum
    )
  }, error = function(e) {
    return(NULL)
  })

  if (is.null(grade_wide) || nrow(grade_wide) == 0) {
    return(subgroup_df)
  }

  # Merge on district and institution codes
  merged <- dplyr::left_join(
    subgroup_df,
    grade_wide,
    by = c("SCHOOL_DSTRCT_CD", "INSTN_NUMBER")
  )

  merged
}


