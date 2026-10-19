
# ============================================================
# PROJECT: Clothing Size Survey - Statistical Analysis
# COURSE : Probability and Statistics
# LANGUAGE: R
# ============================================================

# 1. Install ggplot2 once if it is not installed
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  install.packages("ggplot2")
}

library(ggplot2)

# 2. Define project paths
input_file <- "data/raw/clothing_size_survey.csv"

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/plots", recursive = TRUE, showWarnings = FALSE)

# 3. Import dataset
data <- read.csv(
  input_file,
  check.names = FALSE,
  stringsAsFactors = FALSE,
  strip.white = TRUE
)

# Clean column-name whitespace and remove empty columns
names(data) <- trimws(names(data))
data <- data[, names(data) != "" & !grepl("^Unnamed", names(data)),
             drop = FALSE]

# Verify required columns
required_columns <- c(
  "Jenis Kelamin",
  "Ukuran Baju",
  "Kode UB"
)

missing_columns <- setdiff(required_columns, names(data))

if (length(missing_columns) > 0) {
  stop(
    "Kolom tidak ditemukan: ",
    paste(missing_columns, collapse = ", "),
    ". Periksa header CSV."
  )
}

# 4. Select variables needed for analysis
data <- data[, required_columns, drop = FALSE]

data$`Jenis Kelamin` <- trimws(data$`Jenis Kelamin`)
data$`Kode UB` <- toupper(trimws(data$`Kode UB`))
data$`Ukuran Baju` <- suppressWarnings(
  as.numeric(data$`Ukuran Baju`)
)

# Remove missing or invalid records
data <- data[
  !is.na(data$`Jenis Kelamin`) &
    data$`Jenis Kelamin` != "" &
    !is.na(data$`Ukuran Baju`) &
    !is.na(data$`Kode UB`) &
    data$`Kode UB` != "",
  ,
  drop = FALSE
]

# Define the logical order of clothing-size categories
size_order <- c(
  "XS", "S", "M", "L", "XL",
  "XXL", "3XL", "4XL", "5XL"
)

data$`Kode UB` <- factor(
  data$`Kode UB`,
  levels = size_order,
  ordered = TRUE
)

# Exclude any size codes outside the defined list
data <- data[!is.na(data$`Kode UB`), , drop = FALSE]

# Save cleaned dataset
write.csv(
  data,
  "data/processed/clothing_size_clean.csv",
  row.names = FALSE
)

# 5. Dataset overview
cat("\n===== DATA OVERVIEW =====\n")
cat("Total valid responses:", nrow(data), "\n")
cat("Number of variables:", ncol(data), "\n\n")

print(str(data))
print(summary(data))

# 6. Frequency distribution of clothing sizes
size_frequency <- as.data.frame(
  table(data$`Kode UB`),
  stringsAsFactors = FALSE
)

names(size_frequency) <- c("Kode_Ukuran", "Frekuensi")

size_frequency$Persentase <- round(
  size_frequency$Frekuensi / nrow(data) * 100,
  2
)

write.csv(
  size_frequency,
  "outputs/tables/size_frequency.csv",
  row.names = FALSE
)

cat("\n===== SIZE FREQUENCY =====\n")
print(size_frequency)

# 7. Descriptive statistics for numerical size codes
numeric_size <- data$`Ukuran Baju`

descriptive_stats <- data.frame(
  Statistik = c(
    "Count", "Mean", "Median", "Minimum", "Maximum",
    "Range", "Variance", "Standard Deviation",
    "Q1", "Q3", "IQR"
  ),
  Nilai = c(
    length(numeric_size),
    mean(numeric_size),
    median(numeric_size),
    min(numeric_size),
    max(numeric_size),
    diff(range(numeric_size)),
    var(numeric_size),
    sd(numeric_size),
    unname(quantile(numeric_size, 0.25)),
    unname(quantile(numeric_size, 0.75)),
    IQR(numeric_size)
  )
)

write.csv(
  descriptive_stats,
  "outputs/tables/descriptive_statistics.csv",
  row.names = FALSE
)

cat("\n===== DESCRIPTIVE STATISTICS =====\n")
print(descriptive_stats)

# 8. Empirical probability for each size category
size_probability <- size_frequency
size_probability$Probabilitas <- (
  size_probability$Frekuensi / nrow(data)
)

write.csv(
  size_probability,
  "outputs/tables/size_probability.csv",
  row.names = FALSE
)

cat("\n===== EMPIRICAL PROBABILITY =====\n")
print(size_probability)

# 9. Cross-tabulation: gender vs clothing size
gender_size_table <- table(
  data$`Jenis Kelamin`,
  data$`Kode UB`
)

write.csv(
  as.data.frame.matrix(gender_size_table),
  "outputs/tables/gender_size_crosstab.csv"
)

cat("\n===== GENDER VS SIZE =====\n")
print(gender_size_table)

# Row percentages: size distribution within each gender group
gender_size_percentage <- prop.table(
  gender_size_table,
  margin = 1
) * 100

write.csv(
  round(as.data.frame.matrix(gender_size_percentage), 2),
  "outputs/tables/gender_size_percentage.csv"
)

# 10. Conditional probability example: size L given gender
gender_counts <- table(data$`Jenis Kelamin`)

size_L_by_gender <- table(
  data$`Jenis Kelamin`,
  data$`Kode UB`
)

if ("L" %in% colnames(size_L_by_gender)) {
  conditional_L <- size_L_by_gender[, "L"] / gender_counts
  
  conditional_probability <- data.frame(
    Jenis_Kelamin = names(conditional_L),
    Probabilitas_Memilih_L = as.numeric(conditional_L),
    Persentase = round(as.numeric(conditional_L) * 100, 2)
  )
  
  write.csv(
    conditional_probability,
    "outputs/tables/conditional_probability_L.csv",
    row.names = FALSE
  )
  
  cat("\n===== P(SIZE L | GENDER) =====\n")
  print(conditional_probability)
}

# 11. Plot: clothing-size frequency
p1 <- ggplot(
  size_frequency,
  aes(x = Kode_Ukuran, y = Frekuensi)
) +
  geom_col(fill = "steelblue") +
  geom_text(
    aes(label = Frekuensi),
    vjust = -0.4,
    size = 3.5
  ) +
  labs(
    title = "Clothing Size Distribution",
    x = "Clothing Size",
    y = "Number of Respondents"
  ) +
  theme_minimal()

ggsave(
  "outputs/plots/clothing_size_distribution.png",
  plot = p1,
  width = 8,
  height = 5,
  dpi = 300
)

# 12. Plot: size distribution by gender
gender_plot_data <- as.data.frame(gender_size_table)
names(gender_plot_data) <- c(
  "Jenis_Kelamin", "Kode_Ukuran", "Frekuensi"
)

p2 <- ggplot(
  gender_plot_data,
  aes(
    x = Kode_Ukuran,
    y = Frekuensi,
    fill = Jenis_Kelamin
  )
) +
  geom_col(position = "dodge") +
  labs(
    title = "Clothing Size by Gender",
    x = "Clothing Size",
    y = "Number of Respondents",
    fill = "Gender"
  ) +
  theme_minimal()

ggsave(
  "outputs/plots/clothing_size_by_gender.png",
  plot = p2,
  width = 9,
  height = 5,
  dpi = 300
)

# 13. Plot: numerical size-code distribution
p3 <- ggplot(
  data,
  aes(x = `Ukuran Baju`)
) +
  geom_histogram(
    binwidth = 2,
    boundary = 0,
    fill = "darkseagreen",
    color = "white"
  ) +
  labs(
    title = "Distribution of Numerical Size Codes",
    x = "Numerical Size Code",
    y = "Frequency"
  ) +
  theme_minimal()

ggsave(
  "outputs/plots/numerical_size_distribution.png",
  plot = p3,
  width = 8,
  height = 5,
  dpi = 300
)

# 14. Boxplot by gender
p4 <- ggplot(
  data,
  aes(
    x = `Jenis Kelamin`,
    y = `Ukuran Baju`,
    fill = `Jenis Kelamin`
  )
) +
  geom_boxplot() +
  labs(
    title = "Numerical Size Codes by Gender",
    x = "Gender",
    y = "Numerical Size Code"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(
  "outputs/plots/size_code_boxplot_by_gender.png",
  plot = p4,
  width = 8,
  height = 5,
  dpi = 300
)

print(p3)
cat("\nAnalysis completed successfully.\n")
cat("Check the outputs/tables and outputs/plots folders.\n")



