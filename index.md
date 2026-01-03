# gaschooldata

**[Documentation](https://almartin82.github.io/gaschooldata/)** \|
**[Getting
Started](https://almartin82.github.io/gaschooldata/articles/quickstart.html)**
\| **[Enrollment
Trends](https://almartin82.github.io/gaschooldata/articles/enrollment-trends.html)**

Fetch and analyze Georgia school enrollment data from the Governor’s
Office of Student Achievement (GOSA) in R or Python.

## What can you find with gaschooldata?

**14 years of enrollment data (2011-2024).** 1.7 million students today.
Over 180 districts. Here are ten stories hiding in the numbers - see the
[Enrollment
Trends](https://almartin82.github.io/gaschooldata/articles/enrollment-trends.html)
vignette for interactive visualizations:

1.  [Georgia keeps growing while other states
    shrink](https://almartin82.github.io/gaschooldata/articles/enrollment-trends.html#georgia-keeps-growing-while-other-states-shrink)
2.  [The Hispanic population
    surge](https://almartin82.github.io/gaschooldata/articles/enrollment-trends.html#the-hispanic-population-surge)
3.  [COVID hit kindergarten
    hardest](https://almartin82.github.io/gaschooldata/articles/enrollment-trends.html#covid-hit-kindergarten-hardest)
4.  [Georgia’s demographics
    transformation](https://almartin82.github.io/gaschooldata/articles/enrollment-trends.html#georgias-demographics-transformation)
5.  [Suburban Atlanta
    growth](https://almartin82.github.io/gaschooldata/articles/enrollment-trends.html#suburban-atlanta-growth)
6.  [Gwinnett County is Georgia’s school system
    giant](https://almartin82.github.io/gaschooldata/articles/enrollment-trends.html#gwinnett-county-is-georgias-school-system-giant)
7.  [Atlanta Public Schools is
    shrinking](https://almartin82.github.io/gaschooldata/articles/enrollment-trends.html#atlanta-public-schools-is-shrinking)
8.  [Rural Georgia is emptying
    out](https://almartin82.github.io/gaschooldata/articles/enrollment-trends.html#rural-georgia-is-emptying-out)
9.  [English Learners exceed
    100,000](https://almartin82.github.io/gaschooldata/articles/enrollment-trends.html#english-learners-exceed-100000)
10. [Charter school growth
    accelerates](https://almartin82.github.io/gaschooldata/articles/enrollment-trends.html#charter-school-growth-accelerates)

------------------------------------------------------------------------

## Installation

``` r
# install.packages("remotes")
remotes::install_github("almartin82/gaschooldata")
```

## Quick start

### R

``` r
library(gaschooldata)
library(dplyr)

# Fetch one year
enr_2024 <- fetch_enr(2024)

# Fetch multiple years
enr_recent <- fetch_enr_multi(2020:2024)

# State totals
enr_2024 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# District breakdown
enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students))

# Demographics by district
enr_2024 %>%
  filter(is_district, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  group_by(district_name, subgroup) %>%
  summarize(n = sum(n_students, na.rm = TRUE))
```

### Python

``` python
import pygaschooldata as ga

# See available years
years = ga.get_available_years()
print(f"Data available from {years['min_year']} to {years['max_year']}")

# Fetch one year
enr_2024 = ga.fetch_enr(2024)

# Fetch multiple years
enr_multi = ga.fetch_enr_multi([2020, 2021, 2022, 2023, 2024])

# State totals
state_total = enr_2024[
    (enr_2024['is_state'] == True) &
    (enr_2024['subgroup'] == 'total_enrollment') &
    (enr_2024['grade_level'] == 'TOTAL')
]

# District breakdown
districts = enr_2024[
    (enr_2024['is_district'] == True) &
    (enr_2024['subgroup'] == 'total_enrollment') &
    (enr_2024['grade_level'] == 'TOTAL')
].sort_values('n_students', ascending=False)
```

## Data availability

| Years         | Source                 | Aggregation Levels      | Demographics                      | Notes                       |
|---------------|------------------------|-------------------------|-----------------------------------|-----------------------------|
| **2011-2024** | GOSA Downloadable Data | State, District, School | Race, Gender, Special Populations | Full demographic breakdowns |

### What’s available

- **Levels:** State, district (~180), and school (~2,300)
- **Demographics:** White, Black, Hispanic, Asian, Native American,
  Pacific Islander, Multiracial
- **Special populations:** English Learners (LEP), Special Education,
  Economically Disadvantaged
- **Grade levels:** Pre-K through Grade 12

### ID System

Georgia uses district and school codes: - **District Code:** 3-digit
code (e.g., 660 for Gwinnett County) - **School Code:** 4-digit code
within district

## Data source

Governor’s Office of Student Achievement: [GOSA Downloadable
Data](https://download.gosa.ga.gov/) \| [Report
Card](https://gosa.georgia.gov/)

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data
in Python and R.

**All 50 state packages:**
[github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (<almartin@gmail.com>)

## License

MIT
