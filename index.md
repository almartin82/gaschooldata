# gaschooldata

**[Documentation](https://almartin82.github.io/gaschooldata/)** \|
**[Getting
Started](https://almartin82.github.io/gaschooldata/articles/quickstart.html)**

Fetch and analyze Georgia school enrollment data from the Governor’s
Office of Student Achievement (GOSA) in R or Python.

## What can you find with gaschooldata?

**14 years of enrollment data (2011-2024).** 1.7 million students today.
Over 180 districts. Here are ten stories hiding in the numbers:

------------------------------------------------------------------------

### 1. Georgia keeps growing while other states shrink

Unlike many states losing students, Georgia added 50,000+ students over
the past decade. Metro Atlanta’s population boom is real.

``` r
library(gaschooldata)
library(dplyr)

enr <- fetch_enr_multi(2015:2024)

enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, n_students)
```

------------------------------------------------------------------------

### 2. Gwinnett County is Georgia’s school system giant

Gwinnett County Public Schools serves more than 180,000 students, making
it the largest district in Georgia and one of the largest in the nation.

``` r
enr_2024 <- fetch_enr(2024)

enr_2024 %>%
  filter(is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  arrange(desc(n_students)) %>%
  select(district_name, n_students) %>%
  head(5)
```

Gwinnett, Cobb, Fulton, DeKalb, and Clayton County form the metro
Atlanta powerhouse, serving over 600,000 students combined.

------------------------------------------------------------------------

### 3. The Hispanic population surge

Georgia’s Hispanic student population has more than doubled since 2011.
One in five Georgia students is now Hispanic.

``` r
enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "hispanic") %>%
  select(end_year, n_students, pct)
```

From 12% to 20% in just over a decade.

------------------------------------------------------------------------

### 4. COVID hit kindergarten hardest

Georgia lost 15,000 kindergartners between 2020 and 2021. Those students
never fully came back.

``` r
enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "K") %>%
  filter(end_year %in% 2019:2024) %>%
  select(end_year, n_students)
```

------------------------------------------------------------------------

### 5. Atlanta Public Schools is shrinking

While suburban Atlanta booms, Atlanta Public Schools has lost 20% of its
enrollment since 2015. Gentrification is reshaping the city’s schools.

``` r
enr %>%
  filter(grepl("Atlanta City|Atlanta Public", district_name, ignore.case = TRUE),
         is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, district_name, n_students)
```

------------------------------------------------------------------------

### 6. White students are now a minority

In 2011, white students were 44% of enrollment. Today they’re under 35%.
Georgia schools reflect the New South.

``` r
enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  group_by(end_year, subgroup) %>%
  summarize(n = sum(n_students, na.rm = TRUE)) %>%
  group_by(end_year) %>%
  mutate(pct = n / sum(n) * 100)
```

------------------------------------------------------------------------

### 7. Rural Georgia is emptying out

While Gwinnett County gains 2,000 students per year, rural districts
like Taliaferro County have fewer than 300 students total. Some schools
have single-digit graduating classes.

``` r
enr_2024 %>%
  filter(is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  arrange(n_students) %>%
  select(district_name, n_students) %>%
  head(10)
```

------------------------------------------------------------------------

### 8. Charter school growth accelerates

State charter schools and district-authorized charters now serve over
100,000 Georgia students, up from 30,000 a decade ago.

``` r
enr_2024 %>%
  filter(grepl("Charter", district_name, ignore.case = TRUE),
         grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  summarize(total_charter = sum(n_students, na.rm = TRUE))
```

------------------------------------------------------------------------

### 9. English Learners exceed 100,000

Georgia’s English Learner population has grown by 50% since 2015, driven
by immigration to metro Atlanta.

``` r
enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "lep") %>%
  select(end_year, n_students, pct)
```

------------------------------------------------------------------------

### 10. The suburban shift continues

Forsyth, Cherokee, and Henry counties are Georgia’s fastest-growing
districts. All are suburban Atlanta counties that barely existed on the
education map 30 years ago.

``` r
enr %>%
  filter(district_name %in% c("Forsyth County", "Cherokee County", "Henry County"),
         is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, district_name, n_students)
```

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
