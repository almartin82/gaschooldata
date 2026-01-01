# gaschooldata: Fetch and Process Georgia School Data

Downloads and processes school data from the Governor's Office of
Student Achievement (GOSA). Provides functions for fetching enrollment
data with demographic breakdowns and transforming it into tidy format
for analysis.

## Data Availability

The package supports enrollment data from 2011 through 2024:

- 2011-2024: GOSA (full demographics and special populations)

GOSA provides enrollment data from the 2010-11 school year through
2023-24. For historical data prior to 2011, users must submit a data
request directly to GOSA:
<https://gosa.georgia.gov/dashboards-data-report-card/data-requests>

## Main functions

- [`fetch_enr`](https://almartin82.github.io/gaschooldata/reference/fetch_enr.md):

  Fetch enrollment data for a school year

- [`fetch_enr_multi`](https://almartin82.github.io/gaschooldata/reference/fetch_enr_multi.md):

  Fetch enrollment data for multiple years

- [`get_available_years`](https://almartin82.github.io/gaschooldata/reference/get_available_years.md):

  Get range of available years (2011-2024)

- `tidy_enr`:

  Transform wide data to tidy (long) format

- `id_enr_aggs`:

  Add aggregation level flags

- `enr_grade_aggs`:

  Create grade-level aggregations

## Cache functions

- [`cache_status`](https://almartin82.github.io/gaschooldata/reference/cache_status.md):

  View cached data files

- [`clear_cache`](https://almartin82.github.io/gaschooldata/reference/clear_cache.md):

  Remove cached data files

## ID System

Georgia uses a hierarchical ID system:

- District IDs: 3-4 digits (system code, e.g., 660 = Fulton County)

- School IDs: 4 digits (school number within district)

- Full school code: district + school (e.g., 660-0001)

## Data Sources

Data is sourced exclusively from Georgia state sources:

- GOSA Downloadable Data:
  <https://gosa.georgia.gov/dashboards-data-report-card/downloadable-data>

- GOSA Data Repository: <https://download.gosa.ga.gov/>

## See also

Useful links:

- <https://almartin82.github.io/gaschooldata/>

- <https://github.com/almartin82/gaschooldata>

- Report bugs at <https://github.com/almartin82/gaschooldata/issues>

## Author

**Maintainer**: Al Martin <almartin@example.com>
