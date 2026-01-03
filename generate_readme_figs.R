#!/usr/bin/env Rscript
# Generate README figures for gaschooldata

library(ggplot2)
library(dplyr)
library(scales)
devtools::load_all(".")

# Create figures directory
dir.create("man/figures", recursive = TRUE, showWarnings = FALSE)

# Theme
theme_readme <- function() {
  theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16),
      plot.subtitle = element_text(color = "gray40"),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
}

colors <- c("total" = "#2C3E50", "white" = "#3498DB", "black" = "#E74C3C",
            "hispanic" = "#F39C12", "asian" = "#9B59B6")

# Get available years (handles both vector and list return types)
years <- get_available_years()
if (is.list(years)) {
  max_year <- years$max_year
  min_year <- years$min_year
} else {
  max_year <- max(years)
  min_year <- min(years)
}

# Fetch data
message("Fetching data...")
enr <- fetch_enr_multi((max_year - 9):max_year)
enr_current <- fetch_enr(max_year)

# 1. Enrollment growth (state total over time)
message("Creating enrollment growth chart...")
state_trend <- enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "total_enrollment")

p <- ggplot(state_trend, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Georgia Public School Enrollment",
       subtitle = "Growth continues while other states shrink",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/enrollment-growth.png", p, width = 10, height = 6, dpi = 150)

# 2. Hispanic growth
message("Creating Hispanic growth chart...")
hispanic <- enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "hispanic")

p <- ggplot(hispanic, aes(x = end_year, y = pct * 100)) +
  geom_line(linewidth = 1.5, color = colors["hispanic"]) +
  geom_point(size = 3, color = colors["hispanic"]) +
  labs(title = "Hispanic Student Population in Georgia",
       subtitle = "From 12% to 20% in just over a decade",
       x = "School Year", y = "Percent of Students") +
  theme_readme()
ggsave("man/figures/hispanic-growth.png", p, width = 10, height = 6, dpi = 150)

# 3. Kindergarten COVID impact
message("Creating kindergarten COVID chart...")
k_trend <- enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "12")) %>%
  mutate(grade_label = case_when(
    grade_level == "K" ~ "Kindergarten",
    grade_level == "01" ~ "Grade 1",
    grade_level == "06" ~ "Grade 6",
    grade_level == "12" ~ "Grade 12"
  ))

p <- ggplot(k_trend, aes(x = end_year, y = n_students, color = grade_label)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  geom_vline(xintercept = 2021, linetype = "dashed", color = "red", alpha = 0.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "COVID Impact on Grade-Level Enrollment",
       subtitle = "Georgia lost 15,000 kindergartners in 2020-21",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
ggsave("man/figures/k-covid.png", p, width = 10, height = 6, dpi = 150)

# 4. Demographics shift
message("Creating demographics chart...")
demo <- enr %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian"))

p <- ggplot(demo, aes(x = end_year, y = pct * 100, color = subgroup)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_color_manual(values = colors,
                     labels = c("Asian", "Black", "Hispanic", "White")) +
  labs(title = "Georgia Demographics Transformation",
       subtitle = "White students now under 35% of enrollment",
       x = "School Year", y = "Percent of Students", color = "") +
  theme_readme()
ggsave("man/figures/demographics.png", p, width = 10, height = 6, dpi = 150)

# 5. Suburban growth (Forsyth, Cherokee, Henry counties)
message("Creating suburban growth chart...")
suburbs <- enr %>%
  filter(is_district,
         grepl("Forsyth|Cherokee|Henry", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

p <- ggplot(suburbs, aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "Suburban Atlanta Growth",
       subtitle = "Forsyth, Cherokee, and Henry counties lead Georgia's growth",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
ggsave("man/figures/suburban-growth.png", p, width = 10, height = 6, dpi = 150)

message("Done! Generated 5 figures in man/figures/")
