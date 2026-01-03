# ==============================================================================
# LIVE Pipeline Tests for gaschooldata
# ==============================================================================
#
# These tests verify EACH STEP of the data pipeline using LIVE network calls.
# No mocks - we verify actual connectivity and data correctness.
#
# Test Categories:
# 1. URL Availability - HTTP status codes
# 2. File Download - Successful download and file type verification
# 3. File Parsing - Read file into R
# 4. Column Structure - Expected columns exist
# 5. Year Filtering - Extract data for specific years
# 6. Data Quality - No Inf/NaN, valid ranges
# 7. Aggregation Logic - Row counts and structure
# 8. Output Fidelity - tidy=TRUE matches raw data
#
# ==============================================================================

library(testthat)
library(httr)

# Skip if no network connectivity
skip_if_offline <- function() {
  tryCatch({
    response <- httr::HEAD("https://www.google.com", httr::timeout(5))
    if (httr::http_error(response)) {
      skip("No network connectivity")
    }
  }, error = function(e) {
    skip("No network connectivity")
  })
}

# ==============================================================================
# STEP 1: URL Availability Tests
# ==============================================================================

test_that("GOSA download server is accessible", {
  skip_if_offline()

  response <- httr::HEAD("https://download.gosa.ga.gov/", httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

test_that("GOSA 2024 directory is accessible", {
  skip_if_offline()

  response <- httr::HEAD("https://download.gosa.ga.gov/2024/", httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

test_that("find_gosa_subgroup_url finds valid URL for 2024", {
  skip_if_offline()

  url <- gaschooldata:::find_gosa_subgroup_url(2024)
  expect_true(!is.null(url), info = "URL should not be NULL")
  expect_true(grepl("Enrollment_by_Subgroup", url), info = "URL should contain Enrollment_by_Subgroup")
  expect_true(grepl("2023-24", url), info = "URL should contain 2023-24")

  # Verify URL actually works
  response <- httr::HEAD(url, httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

test_that("find_gosa_subgroup_url finds valid URL for older years (2022)", {
  skip_if_offline()

  url <- gaschooldata:::find_gosa_subgroup_url(2022)
  expect_true(!is.null(url), info = "URL should not be NULL for 2022")
  expect_true(grepl("Enrollment", url), info = "URL should contain Enrollment")

  # Verify URL actually works
  response <- httr::HEAD(url, httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

test_that("find_gosa_grade_url finds valid URL for 2024", {
  skip_if_offline()

  url <- gaschooldata:::find_gosa_grade_url(2024)
  expect_true(!is.null(url), info = "Grade URL should not be NULL for 2024")
  expect_true(grepl("Enrollment_by_Grade", url), info = "URL should contain Enrollment_by_Grade")

  # Verify URL actually works
  response <- httr::HEAD(url, httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

# ==============================================================================
# STEP 2: File Download Tests
# ==============================================================================

test_that("Can download 2024 enrollment subgroup file", {
  skip_if_offline()

  url <- gaschooldata:::find_gosa_subgroup_url(2024)
  expect_true(!is.null(url))

  temp_file <- tempfile(fileext = ".csv")
  on.exit(unlink(temp_file))

  response <- httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    httr::timeout(120)
  )

  expect_equal(httr::status_code(response), 200)
  expect_true(file.exists(temp_file))
  expect_gt(file.info(temp_file)$size, 10000, label = "File should be > 10KB")
})

test_that("Downloaded file is CSV not HTML error page", {
  skip_if_offline()

  url <- gaschooldata:::find_gosa_subgroup_url(2024)
  temp_file <- tempfile(fileext = ".csv")
  on.exit(unlink(temp_file))

  httr::GET(url, httr::write_disk(temp_file, overwrite = TRUE), httr::timeout(120))

  # Read first line - should not be HTML
  first_line <- readLines(temp_file, n = 1)
  expect_false(grepl("<!DOCTYPE|<html|<HTML", first_line),
               info = "File should not be HTML")
  expect_true(grepl("SCHOOL|ENROLL|RPT", first_line, ignore.case = TRUE),
              info = "First line should contain enrollment-related headers")
})

# ==============================================================================
# STEP 3: File Parsing Tests
# ==============================================================================

test_that("Can parse 2024 enrollment CSV with readr", {
  skip_if_offline()

  url <- gaschooldata:::find_gosa_subgroup_url(2024)
  temp_file <- tempfile(fileext = ".csv")
  on.exit(unlink(temp_file))

  httr::GET(url, httr::write_disk(temp_file, overwrite = TRUE), httr::timeout(120))

  df <- readr::read_csv(
    temp_file,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )

  expect_true(is.data.frame(df))
  expect_gt(nrow(df), 1000, label = "Should have > 1000 rows")
  expect_gt(ncol(df), 10, label = "Should have > 10 columns")
})

# ==============================================================================
# STEP 4: Column Structure Tests
# ==============================================================================

test_that("2024 enrollment file has expected columns", {
  skip_if_offline()

  url <- gaschooldata:::find_gosa_subgroup_url(2024)
  temp_file <- tempfile(fileext = ".csv")
  on.exit(unlink(temp_file))

  httr::GET(url, httr::write_disk(temp_file, overwrite = TRUE), httr::timeout(120))
  df <- readr::read_csv(temp_file, col_types = readr::cols(.default = readr::col_character()),
                        show_col_types = FALSE)

  cols <- names(df)

  # Check for key columns
  expect_true("LONG_SCHOOL_YEAR" %in% cols || "SCHOOL_YEAR" %in% cols,
              info = "Should have school year column")
  expect_true("DETAIL_LVL_DESC" %in% cols,
              info = "Should have detail level (State/District/School)")
  expect_true(any(grepl("DSTRCT", cols)),
              info = "Should have district columns")
  expect_true(any(grepl("INSTN", cols)),
              info = "Should have institution columns")

  # Check for demographic columns
  expect_true(any(grepl("ENROLL_PCT", cols)),
              info = "Should have enrollment percentage columns")
  expect_true(any(grepl("MALE|FEMALE", cols)),
              info = "Should have gender columns")
  expect_true(any(grepl("BLACK|WHITE|ASIAN|HISPANIC", cols)),
              info = "Should have race/ethnicity columns")
})

test_that("2024 grade file has expected columns", {
  skip_if_offline()

  url <- gaschooldata:::find_gosa_grade_url(2024)
  if (is.null(url)) skip("Grade file not available for 2024")

  temp_file <- tempfile(fileext = ".csv")
  on.exit(unlink(temp_file))

  httr::GET(url, httr::write_disk(temp_file, overwrite = TRUE), httr::timeout(120))
  df <- readr::read_csv(temp_file, col_types = readr::cols(.default = readr::col_character()),
                        show_col_types = FALSE)

  cols <- names(df)

  # Check for grade-related columns
  expect_true(any(grepl("GRADE|GR_", cols)),
              info = "Should have grade-related columns")
  expect_true(any(grepl("DSTRCT", cols)),
              info = "Should have district columns")
})

# ==============================================================================
# STEP 5: get_raw_enr() Function Tests
# ==============================================================================

test_that("get_raw_enr returns data for 2024", {
  skip_if_offline()

  raw <- gaschooldata:::get_raw_enr(2024)

  expect_true(is.list(raw))
  expect_true("enrollment" %in% names(raw))
  expect_true(is.data.frame(raw$enrollment))
  expect_gt(nrow(raw$enrollment), 1000,
            label = "Should have > 1000 rows of enrollment data")
})

test_that("get_raw_enr returns data for older year (2022)", {
  skip_if_offline()

  raw <- gaschooldata:::get_raw_enr(2022)

  expect_true(is.list(raw))
  expect_true("enrollment" %in% names(raw))
  expect_gt(nrow(raw$enrollment), 1000,
            label = "Should have > 1000 rows for 2022")
})

test_that("get_raw_enr filters to correct school year", {
  skip_if_offline()

  raw <- gaschooldata:::get_raw_enr(2024)

  # Check that data is filtered to 2023-24
  school_years <- unique(raw$enrollment$LONG_SCHOOL_YEAR)
  expect_equal(length(school_years), 1, info = "Should have exactly one school year")
  expect_equal(school_years[1], "2023-24", info = "Should be 2023-24 school year")
})

test_that("get_available_years returns valid year range", {
  result <- gaschooldata::get_available_years()

  expect_true(is.list(result))
  expect_true("min_year" %in% names(result))
  expect_true("max_year" %in% names(result))
  expect_true(result$min_year >= 2010 & result$min_year <= 2015)
  expect_true(result$max_year >= 2023 & result$max_year <= 2030)
  expect_lt(result$min_year, result$max_year)
})

# ==============================================================================
# STEP 6: Data Quality Tests
# ==============================================================================

test_that("Raw data has no Inf or NaN values in numeric columns", {
  skip_if_offline()

  raw <- gaschooldata:::get_raw_enr(2024)

  # Convert numeric columns and check for Inf/NaN
  numeric_cols <- c("ENROLL_PCT_ASIAN", "ENROLL_PCT_BLACK", "ENROLL_PCT_WHITE",
                    "ENROLL_PCT_HISPANIC", "ENROLL_PCT_MALE", "ENROLL_PCT_FEMALE")

  for (col in numeric_cols) {
    if (col %in% names(raw$enrollment)) {
      vals <- suppressWarnings(as.numeric(raw$enrollment[[col]]))
      vals <- vals[!is.na(vals)]

      expect_false(any(is.infinite(vals)),
                   info = paste("No Inf in", col))
      expect_false(any(is.nan(vals)),
                   info = paste("No NaN in", col))
    }
  }
})

test_that("Percentage values are in valid range (0-100)", {
  skip_if_offline()

  raw <- gaschooldata:::get_raw_enr(2024)

  pct_cols <- grep("^ENROLL_PCT_", names(raw$enrollment), value = TRUE)

  for (col in pct_cols) {
    vals <- suppressWarnings(as.numeric(raw$enrollment[[col]]))
    vals <- vals[!is.na(vals)]

    if (length(vals) > 0) {
      expect_true(all(vals >= 0),
                  info = paste(col, "should be >= 0"))
      expect_true(all(vals <= 100),
                  info = paste(col, "should be <= 100"))
    }
  }
})

test_that("Data has all three detail levels (State, District, School)", {
  skip_if_offline()

  raw <- gaschooldata:::get_raw_enr(2024)

  detail_levels <- unique(raw$enrollment$DETAIL_LVL_DESC)

  expect_true("State" %in% detail_levels, info = "Should have State level")
  expect_true("District" %in% detail_levels, info = "Should have District level")
  expect_true("School" %in% detail_levels, info = "Should have School level")
})

# ==============================================================================
# STEP 7: Aggregation Tests
# ==============================================================================

test_that("State level has exactly one row", {
  skip_if_offline()

  raw <- gaschooldata:::get_raw_enr(2024)

  state_rows <- raw$enrollment[raw$enrollment$DETAIL_LVL_DESC == "State", ]
  expect_equal(nrow(state_rows), 1,
               info = "Should have exactly 1 state-level row")
})

test_that("District count is reasonable for Georgia", {
  skip_if_offline()

  raw <- gaschooldata:::get_raw_enr(2024)

  district_rows <- raw$enrollment[raw$enrollment$DETAIL_LVL_DESC == "District", ]

  # Georgia has 180 school districts
  expect_gt(nrow(district_rows), 150,
            label = "Should have > 150 districts")
  expect_lt(nrow(district_rows), 250,
            label = "Should have < 250 districts")
})

test_that("School count is reasonable for Georgia", {
  skip_if_offline()

  raw <- gaschooldata:::get_raw_enr(2024)

  school_rows <- raw$enrollment[raw$enrollment$DETAIL_LVL_DESC == "School", ]

  # Georgia has ~2300 public schools
  expect_gt(nrow(school_rows), 2000,
            label = "Should have > 2000 schools")
  expect_lt(nrow(school_rows), 3000,
            label = "Should have < 3000 schools")
})

# ==============================================================================
# STEP 8: fetch_enr() Integration Tests
# ==============================================================================

test_that("fetch_enr returns data for 2024", {
  skip_if_offline()

  data <- gaschooldata::fetch_enr(2024, use_cache = FALSE)

  expect_true(is.data.frame(data))
  expect_gt(nrow(data), 1000)
})

test_that("fetch_enr with caching works correctly", {
  skip_if_offline()

  # First call - should download
  data1 <- gaschooldata::fetch_enr(2024, use_cache = TRUE)

  # Second call - should use cache
  data2 <- gaschooldata::fetch_enr(2024, use_cache = TRUE)

  expect_equal(nrow(data1), nrow(data2))
  expect_equal(ncol(data1), ncol(data2))
})

# ==============================================================================
# STEP 9: Multi-Year Coverage Tests
# ==============================================================================

test_that("URL discovery works for all supported years", {
  skip_if_offline()

  years_info <- gaschooldata::get_available_years()

  # Test a sample of years
  test_years <- c(years_info$max_year, years_info$max_year - 2,
                  years_info$max_year - 5, years_info$min_year)
  test_years <- test_years[test_years >= years_info$min_year]

  for (year in test_years) {
    url <- gaschooldata:::find_gosa_subgroup_url(year)
    expect_true(!is.null(url),
                info = paste("Should find URL for year", year))
  }
})

# ==============================================================================
# Cache Tests
# ==============================================================================

test_that("Cache functions exist and work", {
  path <- gaschooldata:::get_cache_path(2024, "enrollment")
  expect_true(is.character(path))
  expect_true(grepl("2024", path))
})
