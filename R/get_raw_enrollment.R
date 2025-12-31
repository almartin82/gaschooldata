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
#' @param end_year School year end (2023-24 = 2024). Valid range: 2011-2024
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
#' @return Integer vector of available years (2011-2024)
#' @export
#' @examples
#' get_available_years()
get_available_years <- function() {
  2011:2024
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
    df <- df[grepl(as.character(end_year), df$LONG_SCHOOL_YEAR), ]
  }

  df
}


#' Find the correct GOSA subgroup URL for a given year
#'
#' GOSA files have timestamps in their names. This function attempts to
#' construct or discover the correct URL.
#'
#' @param end_year School year end
#' @return URL string or NULL if not found
#' @keywords internal
find_gosa_subgroup_url <- function(end_year) {

  school_year <- paste0(end_year - 1, "-", substr(end_year, 3, 4))
  folder_year <- end_year

  base_url <- paste0("https://download.gosa.ga.gov/", folder_year, "/")

  # Try common filename patterns (without timestamp)
  patterns <- c(
    paste0("Enrollment_by_Subgroup_Metrics_", school_year, ".csv"),
    paste0("Enrollment_by_Subgroup_", school_year, ".csv"),
    paste0("Enrollment_by_Subgroups_Programs_", folder_year, ".csv")
  )

  for (pattern in patterns) {
    test_url <- paste0(base_url, pattern)
    response <- try(httr::HEAD(test_url, httr::timeout(10)), silent = TRUE)
    if (!inherits(response, "try-error") && httr::status_code(response) == 200) {
      return(test_url)
    }
  }

  # Try known URLs with timestamps (discovered from GOSA repository)
  known_urls <- list(
    "2025" = "https://download.gosa.ga.gov/2025/Enrollment_by_Subgroup_Metrics_2024-25.csv",
    "2024" = "https://download.gosa.ga.gov/2024/Enrollment_by_Subgroup_Metrics_2023-24.csv",
    "2023" = "https://download.gosa.ga.gov/2023/Enrollment_by_Subgroup_Metrics_2022-23.csv",
    "2022" = "https://download.gosa.ga.gov/2022/Enrollment_by_Subgroup_Metrics_2021-22.csv",
    "2021" = "https://download.gosa.ga.gov/2021/Enrollment_by_Subgroup_Metrics_2020-21.csv",
    "2020" = "https://download.gosa.ga.gov/2020/Enrollment_by_Subgroup_Metrics_2019-20.csv",
    "2019" = "https://download.gosa.ga.gov/2019/Enrollment_by_Subgroup_Metrics_2018-19.csv",
    "2018" = "https://download.gosa.ga.gov/2018/Enrollment_by_Subgroup_Metrics_2017-18.csv",
    "2017" = "https://download.gosa.ga.gov/2017/Enrollment_by_Subgroup_Metrics_2016-17.csv",
    "2016" = "https://download.gosa.ga.gov/2016/Enrollment_by_Subgroup_Metrics_2015-16.csv",
    "2015" = "https://download.gosa.ga.gov/2015/Enrollment_by_Subgroup_Metrics_2014-15.csv",
    "2014" = "https://download.gosa.ga.gov/2014/Enrollment_by_Subgroup_Metrics_2013-14.csv",
    "2013" = "https://download.gosa.ga.gov/2013/Enrollment_by_Subgroup_Metrics_2012-13.csv",
    "2012" = "https://download.gosa.ga.gov/2012/Enrollment_by_Subgroup_Metrics_2011-12.csv",
    "2011" = "https://download.gosa.ga.gov/2011/Enrollment_by_Subgroup_Metrics_2010-11.csv"
  )

  year_str <- as.character(end_year)
  if (year_str %in% names(known_urls)) {
    test_url <- known_urls[[year_str]]
    response <- try(httr::HEAD(test_url, httr::timeout(10)), silent = TRUE)
    if (!inherits(response, "try-error") && httr::status_code(response) == 200) {
      return(test_url)
    }

    # Try with timestamp pattern (files often have timestamps appended)
    # Pattern: Enrollment_by_Subgroup_Metrics_YYYY-YY_YYYY-MM-DD_HH_MM_SS.csv
    # Try to discover via directory listing or alternative URLs
  }

  # Try alternate URL structures
  alt_patterns <- c(
    paste0("https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/document/",
           "Enrollment_by_Subgroup_Metrics_", school_year, ".csv"),
    paste0("https://download.gosa.ga.gov/", folder_year, "/",
           "Enrollment_by_Subgroups_Programs_", folder_year, "_OCT_22_2020.csv")
  )

  for (alt_url in alt_patterns) {
    response <- try(httr::HEAD(alt_url, httr::timeout(10)), silent = TRUE)
    if (!inherits(response, "try-error") && httr::status_code(response) == 200) {
      return(alt_url)
    }
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

  if ("SCHOOL_YEAR" %in% names(df)) {
    df <- df[df$SCHOOL_YEAR == school_year, ]
  }

  df
}


#' Find the correct GOSA grade-level URL for a given year
#'
#' @param end_year School year end
#' @return URL string or NULL if not found
#' @keywords internal
find_gosa_grade_url <- function(end_year) {

  school_year <- paste0(end_year - 1, "-", substr(end_year, 3, 4))
  folder_year <- end_year

  base_url <- paste0("https://download.gosa.ga.gov/", folder_year, "/")

  patterns <- c(
    paste0("Enrollment_by_Grade_", school_year, ".csv"),
    paste0("Enrollment_Grade_", school_year, ".csv")
  )

  for (pattern in patterns) {
    test_url <- paste0(base_url, pattern)
    response <- try(httr::HEAD(test_url, httr::timeout(10)), silent = TRUE)
    if (!inherits(response, "try-error") && httr::status_code(response) == 200) {
      return(test_url)
    }
  }

  NULL
}


#' Merge GOSA subgroup and grade data
#'
#' Combines the subgroup demographics with grade-level enrollment.
#'
#' @param subgroup_df Subgroup enrollment data
#' @param grade_df Grade-level enrollment data
#' @return Merged data frame
#' @keywords internal
merge_gosa_data <- function(subgroup_df, grade_df) {

  id_cols <- c("SCHOOL_DSTRCT_CD", "INSTN_NUMBER", "SCHOOL_YEAR")
  id_cols <- id_cols[id_cols %in% names(subgroup_df) & id_cols %in% names(grade_df)]

  if (length(id_cols) == 0) {
    return(subgroup_df)
  }

  grade_cols <- grep("^GRADE_|^GR_|_GRADE$", names(grade_df), value = TRUE)

  if (length(grade_cols) == 0) {
    return(subgroup_df)
  }

  grade_subset <- grade_df[, c(id_cols, grade_cols), drop = FALSE]
  merged <- dplyr::left_join(subgroup_df, grade_subset, by = id_cols)

  merged
}


