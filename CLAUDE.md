# gaschooldata Package

Georgia school enrollment data package using ONLY Georgia state data sources.

## Data Sources

### Governor's Office of Student Achievement (GOSA) - PRIMARY SOURCE
- Downloadable Data Portal: https://gosa.georgia.gov/dashboards-data-report-card/downloadable-data
- Direct Downloads: https://download.gosa.ga.gov/
- Available Years: 2010-11 through 2023-24 (end_year 2011-2024)

### Data Files Used
- **Enrollment by Subgroup Metrics**: Demographics, special populations, FTE counts
  - URL Pattern: `https://download.gosa.ga.gov/{end_year}/Enrollment_by_Subgroup_Metrics_{school_year}[_timestamp].csv`
  - Example: `https://download.gosa.ga.gov/2023/Enrollment_by_Subgroup_Metrics_2022-23_2023-12-15_18_54_53.csv`
- **Enrollment by Grade**: Grade-level enrollment counts (optional, merged if available)
  - URL Pattern: `https://download.gosa.ga.gov/{end_year}/Enrollment_by_Grade_{school_year}.csv`

### Historical Data (Pre-2011)
For data prior to 2010-11, users must submit a GOSA Data Request:
https://gosa.georgia.gov/dashboards-data-report-card/data-requests

## DO NOT USE

- Urban Institute Education Data Portal API (educationdata.urban.org)
- NCES Common Core of Data (CCD)
- Any federal data sources

This package uses ONLY Georgia state data sources (GOSA).

## URL Discovery

GOSA files may include timestamps in their filenames. The package:
1. First tries common filename patterns without timestamps
2. Falls back to known working URLs for each year
3. Attempts alternate URL structures if needed

## Georgia ID System

- District IDs: 3-4 digit system codes (e.g., 660 = Fulton County)
- School IDs: 4-digit school numbers within district
- Full school code: district + school (e.g., 660-0001)

## Key Columns in GOSA Data

- `SCHOOL_DSTRCT_CD`: District code
- `INSTN_NUMBER`: School number
- `SCHOOL_YEAR`: School year (format: YYYY-YY)
- `LONG_SCHOOL_YEAR`: Full school year description
- Demographic columns: Asian, Black, Hispanic, Multiracial, Native, White percentages
- Special populations: ED (Economically Disadvantaged), SWD, LEP, Migrant

## Package Functions

- `get_available_years()`: Returns 2011:2024
- `fetch_enr(end_year)`: Download enrollment for one year
- `fetch_enr_multi(years)`: Download enrollment for multiple years
