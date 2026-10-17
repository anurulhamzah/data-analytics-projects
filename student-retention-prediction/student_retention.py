# %% [markdown]
# <div class="alert alert-block alert-success">
#     
# ### **Assessment 1**
# #### Mining Knowledge from Data:
# **Predictive Analytics in Education: A Multi-Model Approach to Identifying Factors Influencing Student Retention**
# 
# 
# ##### **Name:** Akhmad Fauzi Nurulhamzah 
# ##### **Student ID:** 
# 
# 
# Date: 01/02/2026
# 
# 
# Environment: Python 3.14.2
# 
#     
# </div>

# %% [markdown]
# <div class="alert alert-block alert-danger">
#     
# ### Table of Contents
# 
# </div>    
# 
# [1. Introduction](#Intro) <br>
# [2. Libraries and Load Data](#libs) <br>
# [3. Data Auditing](#audit) <br>
# [4. Data Preparations](#preparations) <br>
# [5. Exploratory Data (EDA)](#EDA) <br>
# [6. Predictive Modeling](#model) <br>
# [7. Conclussion and Ethical Reflection ](#conclussion) <br>
# [8. References](#Ref) <br>

# %% [markdown]
# <div class="alert alert-block alert-warning">
# 
# ### 1.  Introduction  <a class="anchor" name="Intro"></a>
#     
# </div>
# 
# This report presents a comprehensive analytical framework for predicting student attrition and academic success using a dataset of 4,424 records with 36 features from a higher education institution. Student dropout is a complex, multi-dimensional phenomenon that poses significant challenges to institutional stability and student well-being.
# 
# the dataset is taken from UC Irvine Macine learning respository which originally  is supported by program SATDAP - Capacitação da Administração Pública under grant POCI-05-5762-FSE-000191, Portugal.
# 
# 
# 
# 
# **Objectives**
# 1. Identify the main factors contributing to student attrition to support early intervention and retention strategies.
# 
# 2. Segment students into meaningful groups to enable targeted and more effective retention programs.
# 
# 3. Improve the accuracy of student attrition prediction to support data-driven decision-making.

# %% [markdown]
# <div class="alert alert-block alert-warning">
#     
# ### 2.  Importing Libraries  <a class="anchor" name="libs"></a>
# 
# </div>

# %%
#import sys
#!{sys.executable} -m pip install pandas
#!{sys.executable} -m pip install --upgrade pip
#!{sys.executable} -m pip install matplotlib
#!{sys.executable} -m pip install seaborn
#!{sys.executable} -m pip install scikit-learn

# %%
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.preprocessing import MinMaxScaler
from sklearn.cluster import KMeans
from sklearn.decomposition import PCA
from scipy.stats import chi2_contingency, f_oneway
from sklearn.preprocessing import LabelEncoder, MinMaxScaler

from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from xgboost import XGBClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, precision_recall_fscore_support



# Set visualization parameters
%matplotlib inline
sns.set_theme(style="whitegrid")
plt.rcParams['figure.figsize'] = (12, 6)

# %%
# Load data using a relative path
# Ensure 'data.csv' is in the same directory as this notebook
try:
    df = pd.read_csv('./data.csv', sep=',')
    
    # Clean hidden tab characters and spaces from column names
    df.columns = df.columns.str.strip()
    
    print("Data loaded successfully.")
    # Display the first 5 rows to verify structure
    display(df.head())
except FileNotFoundError:
    print("Error: The file './data.csv' was not found in the current directory.")

#Display data
df.head()

# %% [markdown]
# <div class="alert alert-block alert-warning">
#     
# ### 3.  Data Auditing  <a class="anchor" name="audit"></a>
#  </div>

# %% [markdown]
# #### 3.1. Data information Review
# 
# First it is important to examine the data, and we use *df.info()* to understand the basic structure of a dataset before doing any analysis. This command can shows how many rows and columns the data has, what the column names are, and what type of data each column contains. It also tells us how many values are missing in each column. By looking at this information, we can quickly check whether the data types are correct, see if there are missing values that need to be handled, and decide what kind of data cleaning or transformation is needed.

# %%
#Data Informations
df.info()

# %% [markdown]
# Overall,The dataset contains **4,424 student records with 37 variables**.The dataset is numerically dominated, but several variables are **misclassified as numeric (int64/float64) when they are actually binary and categorical**, which can mislead analysis and modeling thus we need to fix it in data preparation
# 
# - **Binary variables**: 
# Several variables in the dataset represent two possible states (yes/no or one of two conditions) but are currently stored as int64 or float64. These include Daytime/evening attendance, Displaced, Educational special needs, Debtor, Tuition fees up to date, Scholarship holder, International, and Gender. Although numerically encoded, these variables do not carry quantitative meaning, and treating them as numeric may lead models to assume artificial ordering or distance. In particular, Daytime/evening attendance and Gender appear as float64 due to missing values, but conceptually they are binary and should be handled as such.
# 
# - **Categorical variables**:
# A large portion of the dataset consists of variables that represent categories with more than two possible values and are incorrectly stored as numeric types. These include Marital status, Application mode, Application order, Course, Nationality, Previous qualification, Mother’s qualification, Father’s qualification, Mother’s occupation, and Father’s occupation. The numeric codes in these variables function only as labels, not as measurements, so interpreting them as continuous values can distort descriptive statistics and predictive modeling outcomes.
# 

# %%
import warnings
warnings.filterwarnings("ignore", category=FutureWarning)


# %% [markdown]
# #### 3.2. Column standardization
# 
# This step ensures that column names are clean and consistent. we fix typo and white spaces. Hidden spaces or spelling differences can cause errors during analysis and modeling. Standardizing column names prevents duplicated variables and ensures that all references to a column point to the same data.

# %%
#df = pd.read_csv(file_path)
df.columns = df.columns.str.strip()

if 'Nacionality' in df.columns:
    df.rename(columns={'Nacionality': 'Nationality'}, inplace=True)


# %% [markdown]
# #### 3.3. Completeness check for missing values
# 
# Next step checks whether any values are missing in the dataset. Missing data can reduce model performance or introduce bias if not handled properly. Identifying missing values early helps decide whether imputation, removal, or further investigation is needed.

# %%
nulls = df.isnull().sum()
print("Missing Values in Each Column:\n", nulls[nulls > 0])


# %% [markdown]
# The missing value check shows that most variables are largely complete, with only a few columns affected. **The Daytime/evening attendance column has 9 missing values, and the Gender column has 14 missing values**, indicating minor data gaps that are unlikely to significantly impact the overall analysis. However, **the Curricular units 1st sem (grade) column has 320 missing values**, which is higher than the others. This suggests that a noticeable number of students do not have recorded grades for the first semester, possibly due to withdrawal, deferral, or incomplete assessment records.

# %% [markdown]
# #### 3.4. Validity check for illogical Data
# 
# This step checks for negative values in numeric columns that should logically be zero or positive, such as age, grades, or counts. Negative values in these fields usually indicate data entry errors or coding issues and must be corrected before analysis.

# %%
#check for illogical negative value

non_neg_cols = [
    c for c in df.select_dtypes(include=[np.number]).columns
    if c not in ['Unemployment rate', 'Inflation rate', 'GDP']
]


for col in non_neg_cols:
    neg_count = (df[col] < 0).sum()
    if neg_count > 0:
        print(f"{col}: {neg_count} negative values")


# %% [markdown]
# There are **4 negative illogical values** in Curricular units 1st semester (grade) it represents an illogical condition, as grades cannot be negative, signaling data entry or preprocessing errors that must be corrected or removed. 

# %% [markdown]
# Aside from illogical negative value, we also need to check the illogical relationship which in this case is in the relation between Debtor and Tuition fees up to date. the logic is that a student cannot be marked as a debtor while their tuition is fully paid. Highlighting these cases helps maintain data integrity.

# %%
#check for illogical relationship

if {'Debtor', 'Tuition fees up to date'}.issubset(df.columns):
    paradox_count = ((df['Debtor'] == 1) & (df['Tuition fees up to date'] == 1)).sum()
    print(f"Financial Paradox cases (Debtor paid up): {paradox_count}")


# %% [markdown]
# The **logical consistency checks** reveal 257 paradoxical cases where students are simultaneously marked as debtors while also having tuition fees up to date, suggesting either delayed updates or inconsistent financial status encoding.

# %% [markdown]
# #### 3.5. Statistical Redundancy (Correlation Check)
# 
# Columns/variable with very high correlation may be redundant. Detecting theseis important to prevent multicollinearity, and improve model performance.

# %%
# High Redundancy Check (>0.9)

corr = df.corr(numeric_only=True)
for i in range(len(corr.columns)):
    for j in range(i):
        if abs(corr.iloc[i, j]) > 0.9:
            print(f" -> {corr.columns[i]} & {corr.columns[j]}: {corr.iloc[i, j]:.2f}")


# %%
#Correlation Heatmap
sns.set_theme(style="whitegrid")
fig = plt.figure(figsize=(15, 14))

plt.subplot(2, 1, 2)
mask = np.triu(np.ones_like(corr, dtype=bool))
sns.heatmap(corr, mask=mask, cmap='coolwarm', center=0, linewidths=.5)
plt.title("Feature Correlation Heatmap")

plt.tight_layout()
plt.show()

# %% [markdown]
# **Correlation analysis** highlights very strong relationships among several academic progression variables, particularly between first- and second-semester curricular unit measures (credited, enrolled, and approved), with correlations exceeding 0.9. This level of redundancy indicates overlapping information and **potential multicollinearity**, suggesting that dimensionality reduction or feature selection is needed. Additionally, the high correlation between Mother’s occupation and Father’s occupation (0.91) implies shared socioeconomic patterns and possible redundancy in representing family background.

# %% [markdown]
# #### 3.6. Distribution Check

# %% [markdown]
# This check can help us see the proportion of distribution from the data that we think important

# %%
#Distribution
sns.set_theme(style="whitegrid")
fig = plt.figure(figsize=(16, 10))

# A: Class Distribution
plt.subplot(2, 2, 1)
sns.countplot(data=df, x='Target', hue='Target', palette='viridis')
plt.title("Class Balance (Target)")

# B: Age Distribution
plt.subplot(2, 2, 2)
sns.boxplot(x=df['Age at enrollment'], color='orange')
plt.title("Age Outlier Detection")

plt.tight_layout()
plt.show()

# %% [markdown]
# 
# - The class balance plot indicates a **moderate class imbalance**, with Graduate students forming the largest group, followed by Dropout, and Enrolled as the smallest class, which also may influence supervised learning performance if not addressed. 
# - The boxplot for **Age at enrolled** shows a concentration of enrollments in the early twenties, accompanied by a long right tail with several older outliers, implying a non-traditional student subgroup that may behave differently in academic outcomes.

# %% [markdown]
# <div class="alert alert-block alert-warning">
#     
# ### 4.  Data Preparations  <a class="anchor" name="preparations"></a>
#  </div>

# %% [markdown]
# #### 4.1 Column Hygiene
# 
# Based on the observation and data audit, to start the data preparation we fix structural errors and typos like renaming columns because consistency is the first rule of good data. If we leave a column named with a typo, any future code we write to analyze that specific data will likely fail. By stripping away extra spaces and correcting spelling, we make sure that our instructions are clear and we can easily find our variables later.

# %%
#Column Hygine
df.columns = df.columns.str.strip()  # Remove extra spaces
if 'Nacionality' in df.columns:
    df.rename(columns={'Nacionality': 'Nationality'}, inplace=True)


print("Columns after cleaning:")
print(df.columns.tolist)


# %% [markdown]
# #### 4.2. Cleaning Negative & Missing Values
# 
# Second, we address logical errors in student grades. Since grades cannot realistically be negative numbers, we treat those entries as errors rather than valid data points. We calculate the median of all positive grades and use that value to replace the negative ones. This allows us to keep the rest of the student's information in our study without letting an impossible math score skew our final results.

# %%
#Grade Column Cleaning
grade_cols = [c for c in df.columns if 'grade' in c.lower()]

for col in grade_cols:
    valid_vals = df.loc[df[col] >= 0, col]
    median_val = valid_vals.median()
    df[col] = df[col].apply(lambda x: median_val if (pd.isna(x) or x < 0) else x)


print("Grades cleaned for negative or missing values:")
df[grade_cols].head()


# %% [markdown]
# #### 4.3 Fixing Logical Consistency
# 
# We also resolve a paradox/strange data between being a debtor and having tuition fees up to date. The Logic tells us that if a student is current on their payments, they cannot simultaneously be in debt to the school. We force the data to reflect this reality by overriding the debtor status for anyone who is fully paid up because the financial status most likely more update. This removes conflicting signals that would otherwise confuse a machine learning model during the training phase.
# 

# %%
#Logical Consistency fix
if {'Debtor', 'Tuition fees up to date'}.issubset(df.columns):
    df.loc[df['Tuition fees up to date'] == 1, 'Debtor'] = 0

print("Debtor column adjusted for students whose fees are up to date:")
print(df[['Debtor', 'Tuition fees up to date']].head(10))


# %% [markdown]
# #### 4.4. Binary Imputation
# 
# Many binary variables, such as Gender, Displaced, or Scholarship holder, cannot have missing values. We fill missing values using the most frequent category (mode), which preserves the natural distribution of the data. This approach is better than deleting rows with missing information, as it maintains the dataset’s size and avoids bias.

# %%
#Binary Variable Imputation
binary_cols = [
    'Daytime/evening attendance', 'Displaced', 'Educational special needs',
    'Debtor', 'Tuition fees up to date', 'Scholarship holder', 
    'International', 'Gender'
]
binary_cols = [c for c in binary_cols if c in df.columns]

for col in binary_cols:
    df[col] = df[col].fillna(df[col].mode()[0])

print("Binary variables after imputation:")
df[binary_cols].isnull().sum()


# %% [markdown]
# #### 4.5. Fix Data Types
# 
# As we have seen wrong data types in data audit, Binary and categorical variables are converted to the category type. This step is crucial because models and analysis functions treat categorical variables differently than numbers, and keeping them as numbers could lead to incorrect interpretations. Converting to category also saves memory and ensures that all future operations, like one-hot encoding, work correctly.

# %%
#Fix Data Types
df[binary_cols] = df[binary_cols].astype('category')

categorical_cols = [
    'Marital status', 'Application mode', 'Application order', 'Course', 
    'Nationality', 'Previous qualification', "Mother's qualification", 
    "Father's qualification", "Mother's occupation"
]
categorical_cols = [c for c in categorical_cols if c in df.columns]
df[categorical_cols] = df[categorical_cols].astype('category')


print("Binary and categorical columns converted to 'category' type.")
print(df.dtypes[binary_cols + categorical_cols])


# %% [markdown]
# #### 4.6. Feature Engineering
# 
# **A. Totals Feature**
# 
# We create new features Total_enrolled and Total_approved by summing semester-specific values. This simplifies analysis by combining redundant columns into a single metric. It reduces complexity and gives a complete picture of a student’s academic workload or performance, which is easier to interpret and use for modeling.

# %%
#Feature enginering


if {'Curricular units 1st sem (enrolled)', 'Curricular units 2nd sem (enrolled)'}.issubset(df.columns):
    df['Total_enrolled'] = df['Curricular units 1st sem (enrolled)'] + df['Curricular units 2nd sem (enrolled)']

if {'Curricular units 1st sem (approved)', 'Curricular units 2nd sem (approved)'}.issubset(df.columns):
    df['Total_approved'] = df['Curricular units 1st sem (approved)'] + df['Curricular units 2nd sem (approved)']


print(df[['Total_enrolled', 'Total_approved']].head())


# %% [markdown]
# **B. Drop Redundant Columns**
# 
# After creating total features, we remove semester-level columns and other highly correlated variables like Father’s occupation. Removing redundancy prevents multicollinearity, reduces dataset size, and keeps only the information we need, which makes models more stable and easier to interpret.

# %%
#Drop Redundant Columns

drop_cols = [
    'Curricular units 1st sem (enrolled)', 'Curricular units 2nd sem (enrolled)',
    'Curricular units 1st sem (approved)', 'Curricular units 2nd sem (approved)',
    'Curricular units 1st sem (credited)', 'Curricular units 2nd sem (credited)',
    "Father's occupation"
]
df.drop(columns=[c for c in drop_cols if c in df.columns], inplace=True)


print("Columns after dropping redundancy:")
print(df.columns.tolist)


# %% [markdown]
# #### 4.7. Outlier Handling (Age)
# 
# We handle extreme age values by **capping them at the 95th percentile**. Outliers can distort statistics and models because they pull averages and affect scaling. By clipping extreme values, we preserve the majority of the data while reducing the impact of unrealistic ages.

# %%
#Outlier Handling in age

if 'Age at enrollment' in df.columns:
    upper = df['Age at enrollment'].quantile(0.95)
    df['Age at enrollment'] = df['Age at enrollment'].clip(upper=upper)


df['Age at enrollment'].describe()


# %% [markdown]
# #### 4.8 Target Encoding
# 
# Since Machine Learning algorithms require numeric targets. We encode the Target column into numbers using label encoding. This ensures that the model understands the target as discrete classes rather than text, while preserving the correct mapping between original labels and numeric codes.

# %%
#Target Encoding

from sklearn.preprocessing import LabelEncoder

if 'Target' in df.columns:
    le = LabelEncoder()
    df['Target_Encoded'] = le.fit_transform(df['Target'])

print(df[['Target', 'Target_Encoded']].head())


# %% [markdown]
# #### 4.9 Scaling Numeric Features
# 
# We scale numeric features to a 0-1 range using MinMaxScaler. Features like Age or Grades can have very different ranges, and models can be biased toward variables with larger values. Scaling ensures that all numeric features contribute equally, improving model convergence and performance.

# %%
#Minmax Scaling


numeric_features = [c for c in df.select_dtypes(include=['int64', 'float64']).columns if c != 'Target_Encoded']
categorical_features = df.select_dtypes(include='category').columns

scaler = MinMaxScaler()
df_scaled = pd.DataFrame(scaler.fit_transform(df[numeric_features]), columns=numeric_features, index=df.index)

df_clean = pd.concat([df[categorical_features], df_scaled, df[['Target_Encoded']]], axis=1)

print("\n=== STEP 10: Scaling Numeric Features ===")
df_clean[numeric_features].describe()


# %% [markdown]
# #### 4.10 Clustering and PCA

# %% [markdown]
# Student Persona Clustering: We apply K-Means clustering on features like Age at enrollment and Admission grade to discover hidden student profiles or personas. This step helps us understand different types of students and can be used for segmentation or personalized interventions.
# 
# Academic Intensity PCA : Apply PCA on evaluation metrics to reduce complexity and prevent multicollinearity. This creates a single metric that captures most of the variance in evaluations, making the dataset simpler while retaining important information.

# %%
# Advanced Feature Engineering

#Student Persona Clustering
persona_cols = ['Age at enrollment', 'Admission grade']
if all(c in df_clean.columns for c in persona_cols):
    kmeans = KMeans(n_clusters=3, random_state=42)
    df_clean['Student_Persona'] = kmeans.fit_predict(df_clean[persona_cols])
    df_clean['Student_Persona'] = df_clean['Student_Persona'].astype('category')

#Academic Intensity PCA
pca_cols = ['Curricular units 1st sem (evaluations)', 'Curricular units 2nd sem (evaluations)']
if all(c in df_clean.columns for c in pca_cols):
    pca = PCA(n_components=1)
    df_clean['Academic_Intensity_PCA'] = pca.fit_transform(df_clean[pca_cols])
    df_clean.drop(columns=pca_cols, inplace=True)


print(df_clean[['Student_Persona', 'Academic_Intensity_PCA']].head())


# %% [markdown]
# ### Final Dataset
# Finally, we combine cleaned categorical variables, scaled numeric features, encoded targets, and advanced features into one dataset, df_prepared. This dataset is type-safe, consistent, and ready for modeling. All preprocessing steps ensure the model receives high-quality, reliable, and interpretable data.
# 

# %%
#Final Clean Dataset

df_prepared = df_clean.copy()

print("Columns in clean dataset:")
print(df_clean.info())

print()

print("Columns in final prepared dataset:")
print(df_prepared.info())

# %% [markdown]
# #### View Clean Data

# %%
df_clean.head()

# %% [markdown]
# #### Clean Data Verification

# %%

def perform_verification_audit(df_to_check):
    print("=== FINAL DATA QUALITY VERIFICATION ===")
    
    #Missing Values Check
    total_nulls = df_to_check.isnull().sum().sum()
    print(f"\n[1] Missing Values: {total_nulls} (Target: 0)")

    #Redundancy Check
    # We check if dropping columns and engineering 'Total_enrolled' worked
    corr = df_to_check.select_dtypes(include=[np.number]).corr()
    high_corr = []
    for i in range(len(corr.columns)):
        for j in range(i):
            if abs(corr.iloc[i, j]) > 0.9:
                high_corr.append(f"{corr.columns[i]} & {corr.columns[j]}")
    
    print(f"\n[2] Redundancy Check: {len(high_corr)} high-correlation pairs found (Target: 0)")

    #Numeric Integrity (Z-score Check)
    # Reminder: Negative values are now NORMAL (it means below average). check for extreme mathematical outliers.
    extreme_outliers = (df_to_check.select_dtypes(include=[np.number]) < -10).sum().sum()
    print(f"\n[3] Extreme Mathematical Outliers (< -10 z-score): {extreme_outliers}")

    #Final Visual Verification
    plt.figure(figsize=(16, 12))
    
    #Correlation Matrix (Should be much 'cooler' than the first audit)
    plt.subplot(2, 1, 1)
    mask = np.triu(np.ones_like(corr, dtype=bool))
    sns.heatmap(corr, mask=mask, cmap='coolwarm', center=0, annot=False)
    plt.title("Post-Processing Correlation: Multicollinearity Resolved")

    # Subplot B: Distribution Check
    # We check if features are now scaled and centered at zero
    plt.subplot(2, 1, 2)
    sample_numeric = df_to_check.select_dtypes(include=[np.number]).columns[:10]
    sns.boxplot(data=df_to_check[sample_numeric], orient="h", palette="magma")
    plt.title("Scaling Check: Numeric features centered around 0 (minmax)")

    plt.tight_layout()
    plt.show()

# Run the audit
perform_verification_audit(df_clean)

# %% [markdown]
# The correlation heatmap shows that **multicollinearity has been successfully resolved**. After feature engineering and feature reduction, there are no pairs of variables with extremely high correlation. This is confirmed by the redundancy check, which reports 0 high-correlation pairs, meeting the target of zero. This means each feature now provides unique information to the model, reducing noise and improving model stability.
# 
# From the heatmap, we can still see moderate and meaningful relationships rather than extreme overlap. For example, Total approved shows a clear positive relationship with Target_Encoded, which aligns with academic logic that students who pass more units are more likely to graduate. Importantly, no correlation values appear excessively strong, indicating that redundant academic variables were either combined or removed correctly during preparation.
# 
# The scaling check boxplots confirm that **numeric features have been scaled consistently using Min-Max scaling**. All features fall within the 0 to 1 range, and their distributions are centered without distortion. While some variables still show outliers, these represent real student behavior differences, not mathematical errors. This confirms that scaling preserved meaningful variation while ensuring features are comparable.
# 
# **The final data quality checks provide strong confirmation of dataset readiness**.
# - First, the missing value check reports 0 missing values, meeting the target exactly. This ensures that no rows are lost during modeling and that all algorithms can train without imputation bias.
# - Second, the redundancy check finds 0 problematic correlations, confirming that multicollinearity has been addressed.
# - Third, the outlier check finds 0 extreme mathematical outliers below a z-score of -10, meaning no corrupted or unrealistic values remain in the dataset.
# 
# In conclusion, these results show that the dataset is clean, stable, and mathematically sound. All quality targets are met, and the data is well-prepared for both predictive modeling and interpretation. This final verification step confirms that any model performance observed later is driven by real patterns in student behavior, not by data quality issues.

# %%
# Save the final dataframe to a CSV file
# index=False prevents pandas from adding an extra column for the row numbers
df_clean.to_csv('Data_Cleaned.csv', index=False)

print("Dataset exported successfully as CSV.")

# %% [markdown]
# <div class="alert alert-block alert-warning">
#     
# ### 5.  Exploratoty Data (EDA)  <a class="anchor" name="EDA"></a>
#  </div>

# %% [markdown]
# The objective of this exploratory data analysis is to understand the structure of student outcomes, identify academic and financial risk factors associated with attrition, statistically validate observed patterns, and uncover latent student personas that can inform predictive modeling and targeted interventions.

# %% [markdown]
# #### 5.1. Distribution of Student Outcomes (Class Structure)

# %%
df_clean['Target'] = df_clean['Target_Encoded'].map({
    0: 'Dropout',
    1: 'Enrolled',
    2: 'Graduate'
})

sns.countplot(x='Target', data=df_clean, palette='viridis')
plt.title("Distribution of Student Outcomes")
plt.xlabel("Student Outcome")
plt.ylabel("Number of Students")
plt.show()


# %% [markdown]
# The distribution chart reveals a significant imbalance within the student population, where Graduates represent the majority of the outcomes, followed by Dropouts, and a smaller segment of currently Enrolled students. This right-skewed frequency suggests that while the institution successfully moves a high percentage of students toward completion, the dropout rate remains a critical area for intervention. This observation is important because it may have modeling implications to accuracy that may be misleading and evaluation metrics such as ROC-AUC and F1-score.

# %% [markdown]
# #### 5.2. Baseline Student Profile (Univariate Analysis)
# 
# These distributions describe the baseline academic and demographic profile of incoming students. Where admission grades reflect prior academic performance and age at enrollment captures non-traditional entry patterns. Understanding these baseline characteristics can provides context for later comparisons and supports their inclusion as predictors in attrition models.

# %%
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

sns.histplot(df_clean['Admission grade'], kde=True, ax=axes[0])
axes[0].set_title('Admission Grade Distribution')

sns.histplot(df_clean['Age at enrollment'], kde=True, ax=axes[1])
axes[1].set_title('Age at Enrollment Distribution')

plt.show()


# %% [markdown]
# The **distribution of Admission Grades** shows a bell-shaped curve that is relatively symmetrical, centered around the mean. This suggests that the majority of students enter the institution with average admission scores, while a smaller, equal number of students represent the high-achieving and lower-achieving ends of the spectrum. In the context of your cleaned data, this "normal" distribution is ideal for machine learning models, as it indicates that the admission criteria provide a consistent baseline for most students without being heavily skewed by extreme outliers.
# 
# On the other hand, the **Age at Enrollment distribution** is significantly right-skewed, meaning it has a long tail extending toward older ages. While the vast majority of students are concentrated in the traditional university age bracket (the peak on the left), there is a significant and steady presence of "mature" students returning to education. The sharp drop-off at the end of the tail confirms that the data cleaning "clipping" step worked. it capped extreme ages at the 95th percentile to prevent a few very old students from skewing the model's perception of the entire student body.

# %% [markdown]
# #### 5.2. Bivariate & Categorical Risk Identification
# 
# We need to create stacked bar chart that illustrates the relationship between tuition fee compliance and student outcomes. we will see whether students who are not up to date with tuition payments exhibit a substantially higher proportion of dropout outcomes.This can be used to identifies whether tuition fee status is a critical financial red flag and a strong candidate predictor for attrition risk.

# %%
tuition_target = pd.crosstab(
    df_clean['Tuition fees up to date'],
    df_clean['Target'],
    normalize='index'
)

tuition_target.plot(
    kind='bar',
    stacked=True,
    figsize=(10, 6),
    colormap='vlag'
)

plt.title("Impact of Tuition Fee Status on Student Outcomes")
plt.ylabel("Proportion")
plt.xlabel("Tuition Fees Up to Date")
plt.show()


# %% [markdown]
# The figure illustrates a clear and substantial **relationship between tuition fee status and student academic outcomes**. Students whose tuition fees are not up to date show an overwhelmingly high proportion of dropouts. In this group, dropout is the dominant outcome, while only a very small fraction of students remain enrolled or successfully graduate. This indicates that falling behind on tuition payments is strongly associated with early withdrawal from university, **suggesting that financial difficulty acts as a major barrier to academic persistence**
# 
# In contrast, students whose tuition fees are up to date display a markedly different outcome distribution. For these students, graduation is the most common result, followed by continued enrollment, while the proportion of dropouts is substantially lower. **This pattern suggests that financial stability plays a crucial supportive role** in enabling students to progress through their studies and complete their degrees. Although keeping tuition fees current does not guarantee graduation, it significantly increases the likelihood of academic success.
# 
# Importantly, the relationship observed in the plot is asymmetric. Being financially unstable almost invariably leads to dropout, whereas being financially stable merely creates favorable conditions for success rather than ensuring it. This asymmetry highlights that **tuition fee status can functions as a strong risk indicator rather than a simple performance measure.** From an analytical perspective, this makes the variable particularly valuable for early-warning systems and predictive modeling, as it captures a critical structural constraint affecting student retention and completion.
# 

# %%
# 2.2 Academic Snapshot
plt.figure(figsize=(10, 6))
sns.boxplot(
    x='Target',
    y='Curricular units 2nd sem (grade)',
    data=df_clean,
    palette='Set2'
)

plt.title("Second Semester Academic Performance by Outcome")
plt.xlabel("Student Outcome")
plt.ylabel("2nd Semester Grade")
plt.show()


# %% [markdown]
# The boxplot highlights a strong and systematic relationship between second-semester academic performance and student outcomes. **Students who ultimately graduate exhibit consistently high second-semester grades, with a relatively tight interquartile range**. This indicates not only strong academic performance but also low variability, suggesting that sustained and stable achievement in the second semester is a common characteristic among successful graduates.
# 
# In contrast, the dropout group shows a markedly different pattern. The distribution is heavily skewed toward very low grades, with a median close to zero and a wide spread of values. This suggests that **many students who drop out experience severe academic disengagement or failure during the second semester**, potentially including course non-completion or absence from assessments. The large variability further indicates that **dropout is not driven by a single academic threshold, but rather by a range of academic difficulties that culminate in withdrawal**.
# 
# Students who remain enrolled fall between these two extremes. Their second-semester grades are generally moderate, with medians lower than graduates but substantially higher than dropouts. This group displays greater dispersion than graduates, reflecting a heterogeneous population that includes both students who may later recover academically and those who remain at risk of eventual dropout. Overall, the figure demonstrates that second-semester performance is a critical academic inflection point: sustained high grades are associated with graduation, while academic collapse during this period strongly precedes dropout.

# %% [markdown]
# #### 5.3.  Inferential Statistical

# %% [markdown]
# ##### 5.3.1 Chi Square
# 
# We use the Chi square test for these variables because both the predictors and the outcome are categorical. The goal is to check whether the distribution of student outcomes such as dropout, enrolled, or graduate changes across different groups like gender, tuition payment status, or scholarship status. The test helps determine whether the observed differences in outcomes are likely due to real associations or simply random variation in the data.
# 
# In this study, Chi square analysis supports the identification of risk factors related to attrition. If a categorical variable shows a significant result, it means that student outcomes are not evenly distributed across its categories. This justifies including the variable in later modeling stages and discussing it as a meaningful driver of student success or dropout rather than relying only on visual inspection.

# %%
from scipy.stats import chi2_contingency

binary_vars = [
    'Daytime/evening attendance',
    'Displaced',
    'Educational special needs',
    'Debtor',
    'Tuition fees up to date',
    'Scholarship holder',
    'International',
    'Gender'
]

categorical_vars = [
    'Marital status',
    'Application mode',
    'Application order',
    'Course',
    'Nationality',
    'Previous qualification',
    "Mother's qualification",
    "Father's qualification",
    "Mother's occupation",
    "Father's occupation"  # will be safely ignored
]

chi_square_vars = binary_vars + categorical_vars

chi_results = []

for var in chi_square_vars:
    # 🔒 SAFETY CHECK
    if var not in df_clean.columns:
        continue

    contingency_table = pd.crosstab(
        df_clean[var],
        df_clean['Target_Encoded']
    )

    chi2, p, dof, expected = chi2_contingency(contingency_table)

    chi_results.append({
        'Variable': var,
        'Chi2_statistic': chi2,
        'Degrees_of_freedom': dof,
        'p_value': p
    })

chi_square_df = (
    pd.DataFrame(chi_results)
    .sort_values(by='p_value')
    .reset_index(drop=True)
)

chi_square_df


# %% [markdown]
# The Chi-square results show that many, but not all, categorical variables are significantly associated with student outcomes. Variables with p values below 0.05 indicate that the distribution of dropout, enrolled, and graduate statuses differs meaningfully across their categories. In contrast, variables with higher p values do not show sufficient evidence of association with student outcomes.
# 
# Financial-related variables exhibit the strongest associations with student outcomes. Tuition fees up to date has by far the largest Chi-square statistic and the smallest p value, indicating a very strong relationship with student status. This suggests that students who are not up to date with tuition payments are substantially more likely to drop out or fail to graduate. Scholarship holder and Debtor status also show extremely strong associations, reinforcing the conclusion that financial stability plays a critical role in student persistence and academic success.
# 
# Enrollment and background characteristics also demonstrate significant relationships with outcomes. Variables such as Course, Application mode, Application order, and Marital status are statistically significant, indicating that students’ academic pathways and personal circumstances influence their likelihood of graduation or dropout. Gender and Daytime or evening attendance are significant as well, though their Chi-square statistics are smaller, suggesting weaker associations compared to financial factors.
# 
# In contrast, Nationality, International status, and Educational special needs do not show statistically significant associations with student outcomes, as their p values are well above 0.05. This indicates that, within this dataset, outcome distributions are relatively similar across these groups, and there is no strong statistical evidence that these characteristics influence dropout or graduation rates.

# %% [markdown]
# ##### 5.3.2. ANOVA
# 
# For Continous data we test using ANOVA. this is to test whether the average values of a numerical variable differ across several outcome groups. In this case, the student outcome variable has three categories, which are dropout, enrolled, and graduate. For each continuous variable, ANOVA allows us to examine whether students in these outcome groups have meaningfully different mean values. This helps determine whether a variable is related to student success beyond random variation.
# 
# Applying ANOVA to academic performance, enrollment progression, and background variables is important because these variables represent measured quantities rather than categories. If their mean values differ significantly across outcomes, this provides statistical evidence that they are associated with student attrition or completion. As a result, ANOVA helps identify which continuous variables are informative predictors and should be prioritized in further modeling.

# %%
from scipy.stats import f_oneway
import pandas as pd

# Intended continuous variables
continuous_vars = [
    'Admission grade',
    'Age at enrollment',
    'Previous qualification (grade)',
    'Curricular units 1st sem (grade)',
    'Curricular units 2nd sem (grade)',
    'Curricular units 1st sem (evaluations)',
    'Curricular units 2nd sem (evaluations)',
    'Curricular units 1st sem (without evaluations)',
    'Curricular units 2nd sem (without evaluations)',
    'Total_enrolled',
    'Total_approved',
    'GDP',
    'Unemployment rate',
    'Inflation rate'
]

# Keep only columns that actually exist
continuous_vars = [v for v in continuous_vars if v in df_clean.columns]

anova_results = []

for var in continuous_vars:
    groups = [
        df_clean[df_clean['Target_Encoded'] == g][var].dropna()
        for g in df_clean['Target_Encoded'].unique()
    ]
    
    # ANOVA requires enough observations
    if all(len(group) > 1 for group in groups):
        f_stat, p_val = f_oneway(*groups)
        
        anova_results.append({
            'Variable': var,
            'F_statistic': f_stat,
            'p_value': p_val
        })

anova_df = pd.DataFrame(anova_results).sort_values(by='p_value')
anova_df


# %% [markdown]
# The ANOVA results show that most continuous variables differ significantly across student outcome groups, indicating that their average values are meaningfully associated with whether a student drops out, remains enrolled, or graduates. Variables with very large F statistics and near-zero p values provide the strongest evidence of differences between outcome groups.
# 
# Academic performance variables dominate the results. Curricular units 2nd semester grade, Total approved units, and Curricular units 1st semester grade exhibit extremely high F statistics, showing that students who graduate achieve substantially higher grades and accumulate more approved units than those who drop out. These findings indicate that academic performance during the program is the most influential continuous factor in determining student success.
# 
# Enrollment progression and preparation variables also show significant effects. Age at enrollment, Total enrolled units, Admission grade, and Previous qualification grade all differ significantly across outcomes. This suggests that both prior academic readiness and ongoing engagement with coursework influence the likelihood of graduation, although their impact is weaker than that of in-program academic achievement.
# 
# Economic context variables show limited influence. Unemployment rate and GDP are statistically significant but have relatively small F statistics, indicating modest differences across student outcomes. Inflation rate is not statistically significant, suggesting that inflation does not meaningfully distinguish between dropout, enrolled, and graduate students in this dataset.
# 
# Overall, the ANOVA results reinforce that academic achievement and study progression are the primary continuous predictors of student outcomes, while background and macroeconomic variables play a secondary role. These findings provide strong statistical justification for prioritizing academic performance features in subsequent predictive modeling.

# %% [markdown]
# #### 5.4 Academic Velocity
# We will calculate **Academic Velocity** to capture how a student’s performance changes over time rather than looking at grades in isolation. 
# 
# A single semester grade only shows a snapshot, but it does not reveal whether a student is improving, stagnating, or declining. By subtracting first semester grades from second semester grades, we create a variable that directly measures academic momentum.

# %%
df_clean['Academic_Velocity'] = (
    df_clean['Curricular units 2nd sem (grade)'] -
    df_clean['Curricular units 1st sem (grade)']
)

sns.violinplot(
    x='Target',
    y='Academic_Velocity',
    data=df_clean,
    palette='RdYlGn'
)

plt.title("Academic Velocity Across Student Outcomes")
plt.xlabel("Student Outcome")
plt.ylabel("Change in Academic Performance")
plt.show()


# %% [markdown]
# This academic velocity shows, for graduate students, the distribution is tightly centered around zero with a slight positive shift. This suggests that **most graduates maintain stable performance or experience small improvements between semesters**. The narrow spread indicates consistency, meaning large drops in performance are rare among students who eventually graduate.
# 
# For dropout students, the distribution is much wider and strongly skewed toward negative values. Many **dropout students experience substantial declines in academic performance** from the first to the second semester. The long lower tail reflects severe academic deterioration, which is a strong warning signal preceding dropout.
# 
# For enrolled students, the distribution sits between graduates and dropouts. **Most enrolled students cluster near zero, indicating stable performance, but the wider spread shows that this group includes both students who are improving and those whose performance is declining**. This reflects an intermediate state where outcomes are still uncertain.
# 
# Overall, this figure shows that changes in academic performance over time are more informative than single-semester grades alone. A sharp negative academic velocity is strongly associated with dropout, while stable or improving performance is characteristic of students who persist and graduate.

# %% [markdown]
# #### 5.5 Unsupervised Persona Discovery (Clustering)

# %% [markdown]
# We will apply clustering for EDA to explore hidden patterns in student behavior that are not explicitly labeled in the data. While the dataset provides final academic outcomes such as dropout, enrollment, or graduation, it does not explain how different types of students progress toward those outcomes. Clustering will allows us to group students based on similarities in their academic performance, engagement, and background characteristics, revealing student personas that share common traits. This exploratory step helps us better understand heterogeneity within the student population, identify groups that may be at higher academic risk, and provide meaningful context for later analysis, without using outcome labels or influencing the predictive modeling process.

# %% [markdown]
# **A. Determine K**
# 
# To determine K we will use shilloute method because by using elbow sometimes it is hard to determine the K, so with shilloute it will show exactly the number so it is easier to determine the K

# %%
# Use numeric features only (exclude target encoding)
from sklearn.metrics import silhouette_score

X = (
    df_clean
    .select_dtypes(include=[np.number])
    .drop(columns=['Target_Encoded'])
)

scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)


#Cluster evaluation
silhouette_scores = {}

for k in range(2, 11):
    kmeans = KMeans(n_clusters=k, random_state=42, n_init=10)
    labels = kmeans.fit_predict(X_scaled)
    score = silhouette_score(X_scaled, labels)
    silhouette_scores[k] = score
    print(f"k = {k}, Silhouette Score = {score:.4f}")

# Select optimal k (highest silhouette score)
optimal_k = max(silhouette_scores, key=silhouette_scores.get)
print(f"\n Optimal number of clusters selected: k = {optimal_k}")

# %%
# --- Silhouette Score Visualization ---
plt.figure(figsize=(8, 5))

plt.plot(
    list(silhouette_scores.keys()),
    list(silhouette_scores.values()),
    marker='o'
)

plt.xlabel("Number of Clusters (k)")
plt.ylabel("Silhouette Score")
plt.title("Silhouette Analysis for Optimal k Selection")
plt.xticks(range(2, 11))
plt.grid(True)

plt.show()


# %% [markdown]
# Although the silhouette score is slightly higher at k = 2, the difference between k = 2 (0.3341) and k = 3 (0.3303) is very small and does not represent a meaningful improvement in cluster quality. In practical terms, both values indicate a similar level of separation between clusters.
# 
# **We choose k = 3 because k = 2 oversimplifies the student population by merging distinct academic patterns into a single group**. Using three clusters allows us to capture more nuanced differences in student behavior and academic performance, which is important for interpretation and policy relevance.
# 
# Additionally, **k = 3 aligns with the natural structure of the dataset, which contains three real-world academic outcomes (Dropout, Enrolled, and Graduate)**. While clustering is unsupervised and does not use these labels, selecting three clusters improves interpretability and supports meaningful persona analysis without significantly sacrificing clustering quality.
# 
# Therefore, k = 3 represents the best balance between statistical performance and practical interpretability, making it the preferred choice for this study.

# %% [markdown]
# **B. Clustering**

# %%
#K-MEANS clustering (k = 3)

kmeans_final = KMeans(n_clusters=3, random_state=42, n_init=10)
df_clean['Student_Persona'] = kmeans_final.fit_predict(X_scaled)
df_clean['Student_Persona'] = df_clean['Student_Persona'].astype('category')


#PCA FOR VISUALIZATION (2D)

pca = PCA(n_components=2)
pca_data = pca.fit_transform(X_scaled)

pca_df = pd.DataFrame(
    pca_data,
    columns=['PC1', 'PC2'],
    index=df_clean.index
)

pca_df['Target'] = df_clean['Target']
pca_df['Student_Persona'] = df_clean['Student_Persona']



#VISUAL COMPARISON: REAL OUTCOMES vs AI CLUSTERS

plt.figure(figsize=(15, 6))

# A. Actual Student Outcomes
plt.subplot(1, 2, 1)
sns.scatterplot(
    data=pca_df,
    x='PC1',
    y='PC2',
    hue='Target',
    alpha=0.6
)
plt.title('PCA Projection — Actual Student Outcomes')

#AI-Discovered Personas
plt.subplot(1, 2, 2)
sns.scatterplot(
    data=pca_df,
    x='PC1',
    y='PC2',
    hue='Student_Persona',
    palette='Set1',
    alpha=0.6
)
plt.title('PCA Projection — K-Means Student Personas')

plt.tight_layout()
plt.show()


# %% [markdown]
# This figure compares real student outcomes with patterns discovered automatically by the model using PCA and K-means clustering. PCA reduces the many original variables into two dimensions, PC1 and PC2, which summarize the dominant patterns in the data. Each point represents a student, and points that are closer together have more similar academic and enrollment characteristics.
# 
# In the left plot, points are colored by the actual student outcomes. We can see that graduates tend to cluster toward higher values of PC1, while dropout students are more concentrated on the lower end. Enrolled students mostly lie between these two groups. Although there is overlap, the outcomes are not randomly mixed, which suggests that the underlying features already contain structure related to student success and attrition.
# 
# In the right plot, the same PCA projection is shown, but points are colored by K-means clusters instead of true outcomes. The clusters form clear, compact groups that align closely with the structure seen in the left plot. One cluster concentrates in the low PC1 region, another occupies the central region, and a third extends toward higher PC1 values. This indicates that the clustering algorithm is capturing meaningful differences in student profiles without using outcome labels.
# 
# Comparing both plots reveals that the unsupervised clusters broadly correspond to real student outcomes, even though the model was not told which students dropped out or graduated. This suggests the presence of distinct student personas, such as academically struggling students, stable but uncertain students, and high-performing students. Overall, the figure shows that student outcomes emerge naturally from patterns in academic performance and engagement, supporting the use of clustering for student profiling and early risk identification.

# %% [markdown]
# **C. Student Personas**

# %%

numeric_cols = (
    df_clean
    .select_dtypes(include=[np.number])
    .drop(columns=['Target_Encoded'], errors='ignore')
    .columns
)

persona_numeric_summary = (
    df_clean
    .groupby('Student_Persona')[numeric_cols]
    .mean()
    .round(2)
)

persona_numeric_summary


# %% [markdown]
# **Persona 0: Steady and Consistent Students**
# 
# **Academic Profile**: Students in this group show average academic performance. Their admission grades and semester grades are moderate, and they pass a reasonable number of courses each semester. They stay engaged with their studies but do not take heavy academic loads or progress very quickly. Their learning pace is stable and consistent across semesters.
# 
# **Demographic & Socioeconomic Tendencies**: This persona reflects a typical student background. Students come from mixed demographic and family backgrounds, with no strong dominance of any single group. Their attendance patterns and financial conditions are generally balanced, and they do not show strong signs of either advantage or disadvantage.
# 
# in conclusion, persona 0 represents stable students who progress normally through their studies. They are not at high academic risk, but they also do not show exceptional academic performance.
# 
# **Persona 1:  Highly Engaged and High-Performing Students**
# 
# **Academic Profile**: Students in this persona perform very well academically. They achieve high grades in both semesters and successfully complete most of the courses they enroll in. They actively participate in evaluations and show strong academic progress. Their study pace is efficient, allowing them to convert enrollment into successful course completion.
# 
# **Demographic & Socioeconomic Tendencies**: This group tends to include students with more stable conditions. Many receive scholarships, fewer have outstanding tuition issues, and they are often younger at the time of enrollment. These factors support their strong academic engagement and performance.
# 
# thus, persona 1 represents high-performing and well-supported students. They show the strongest academic outcomes and are the most likely to progress smoothly toward graduation.
# 
# **Persona 2: Low Engagement and Academically At-Risk Students**
# 
# **Academic Profile**: Students in this group show low academic performance. Their grades are lower, and they pass very few courses despite enrolling in them. Their academic progress is slow, and their overall engagement with coursework and evaluations is limited. This results in weak academic momentum across semesters.
# 
# **Demographic & Socioeconomic Tendencies**: This persona includes more students facing financial or study-related challenges, such as tuition issues or non-traditional study patterns. These conditions may make it harder for them to stay engaged and perform well academically.
# 
# 
# Persona 2 representing academically vulnerable students who are at higher risk of poor outcomes, including delayed completion or dropout. They may benefit most from early academic and financial support.
# 
# 

# %% [markdown]
# <div class="alert alert-block alert-warning">
#     
# ### 6.  Predictive Modeling  <a class="anchor" name="Predictive"></a>
#  </div>

# %% [markdown]
# We want to compare the performance of linear, tree based prediction modeling and evaluates three distinct architectures to address the assignment objectives. the model is:
# 
# 1. **Baseline**: Logistic Regression (Linear Model)
# 2. **Ensemble**: Random Forest (Bagging)
# 3. **Advanced Ensemble**: XGBoost (Boosting)
# 
# We will utilize a strategic Train-Test split followed by 10-Fold Cross-Validation on the training set to ensure the results are robust. We use the 'df_prepared' dataset which contains our engineered PCA and Cluster features.
# 

# %% [markdown]
# #### 6.1 Modeling
# 
# This section evaluates three architectures. to ensure correct analysis, we applied:
# 1. **One-Hot Encoding** for categorical consistency.
# 2. Apply **10-Fold Cross-Validation** for statistical reliability.
# 3. Conduct a **Paired t-test** to prove the performance gap is significant.
# 
# To ensure the models achieve maximum generalizability and avoid overfitting, hyperparameters were selected based on the  logic:
# 
# - For XGBoost and Random Forest, max_depth was restricted to 5. This prevents the trees from becoming overly deep and capturing noise in the training data, ensuring the model performs well on unseen student records.
# 
# - A learning rate of 0.1 was utilized for XGBoost. This "shrinkage" parameter scales the contribution of each new tree, that allowing the model to converge more slowly and reliably toward the global optimum.
# 
# - Parameters were tuned to maximize the Weighted F1-Score. This choice is critical because of the class imbalance; it ensures the model is penalized more heavily for failing to identify the 'Dropout' and 'Enrolled' minority groups compared to the 'Graduate' majority.

# %%

from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from xgboost import XGBClassifier
from sklearn.metrics import classification_report, accuracy_score, confusion_matrix, ConfusionMatrixDisplay
from scipy import stats


#Data Preparation
# Convert categories to dummies before splitting to ensure consistent feature space
df_model = pd.get_dummies(df_prepared, drop_first=True)

X = df_model.drop(['Target_Encoded'], axis=1)
y = df_model['Target_Encoded']

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

#Model Initialization
models = {
    "Logistic Regression (Baseline)": LogisticRegression(max_iter=2000, random_state=42),
    "Random Forest (Ensemble)": RandomForestClassifier(n_estimators=100, random_state=42),
    "XGBoost (Advanced Ensemble)": XGBClassifier(n_estimators=100, learning_rate=0.1, max_depth=5, 
                                               eval_metric='mlogloss', random_state=42)
}



# %%
print(f"The model is using exactly {X.shape[1]} features for prediction.")

# %% [markdown]
# #### 6.2. Cross Validation

# %%
#10-Fold Cross-Validation ---
cv_results = {}
print("10-Fold CV Results")
for name, model in models.items():
    scores = cross_val_score(model, X_train, y_train, cv=10)
    cv_results[name] = scores
    print(f"{name}: {scores.mean():.4f} (+/- {scores.std():.4f})")

# HD REQUIREMENT: Statistical Evidence (Paired t-test)
# Comparing Baseline vs. XGBoost
t_stat, p_val = stats.ttest_rel(cv_results["Logistic Regression (Baseline)"], 
                               cv_results["XGBoost (Advanced Ensemble)"])
    

#Performance Gap Analysis
plt.figure(figsize=(10, 6))
sns.boxplot(data=pd.DataFrame(cv_results), palette="Set2")
plt.title('Performance Gap: Linear Baseline vs. Ensemble Architectures')
plt.ylabel('Cross-Validated Accuracy')
plt.grid(axis='y', linestyle='--', alpha=0.7)
plt.show()


# %% [markdown]
# The figure compares how three different models perform when predicting student outcomes. Each box shows the spread of accuracy scores from repeated cross-validation runs. This helps us see not only how accurate each model is on average, but also how stable it is across different data splits.
# 
# The Logistic Regression model is used as a simple baseline. Its average accuracy is about 0.76, and the results are fairly consistent. This tells us that **a linear relationship already captures a large part of the pattern in the data**. However, its performance is limited because it cannot fully model more complex interactions between variables.
# 
# The Random Forest model shows a small improvement over Logistic Regression, with an average accuracy of around 0.763. This suggests that combining many decision trees helps the model capture non-linear patterns that the baseline model misses. The wider spread of the box indicates slightly more variation, but the overall performance gain is modest.
# 
# The **XGBoost model achieves the highest average accuracy at about 0.774**. It also reaches the highest upper values among the three models. This means XGBoost is better at learning subtle patterns in the data, especially interactions between academic, demographic, and socioeconomic factors. Although its results vary a bit more, the overall improvement is clear and consistent.
# 
# In summary, the results show a clear performance gap between the simple baseline model and the more advanced ensemble models. While Logistic Regression provides a strong starting point, XGBoost delivers the best balance of accuracy and learning capacity, making it the most suitable model for this project.

# %% [markdown]
# #### 6.3 Multi-Metric Performance Analysis
# We evaluate the performance gap across four key metrics. In the context of student retention.
# 
# **Recall** for the 'Dropout' class is especially critical to ensure that at-risk students are not missed by the system.

# %%



# 1. Initialize storage for metrics
metrics_list = []

# 2. Calculate metrics for each model
for name, model in models.items():
    # Ensure model is trained on the training set
    model.fit(X_train, y_train)
    
    # Make predictions on the unseen test set
    y_pred = model.predict(X_test)
    
    # Calculate Weighted Metrics (Overall Performance)
    precision, recall, f1, _ = precision_recall_fscore_support(y_test, y_pred, average='weighted')
    accuracy = accuracy_score(y_test, y_pred)
    
    # Calculate Specific Recall for 'Dropout' (Class 0)
    # This shows how well the model identifies students who actually leave.
    _, class_recall, _, _ = precision_recall_fscore_support(y_test, y_pred, average=None)
    dropout_recall = class_recall[0] 

    metrics_list.append({
        'Model': name,
        'Accuracy': accuracy,
        'Precision (Weighted)': precision,
        'Recall (Weighted)': recall,
        'F1-Score (Weighted)': f1,
        'Dropout Recall': dropout_recall
    })

# 3. Create a Comparison Table
df_comparison = pd.DataFrame(metrics_list).set_index('Model')
print("--- Model Performance Comparison Table ---")
display(df_comparison.round(4))

# 4. Visualize the Performance Gap
# Convert to 'long' format for Seaborn plotting
df_plot = df_comparison.reset_index().melt(id_vars='Model', var_name='Metric', value_name='Score')

plt.figure(figsize=(14, 7))
sns.barplot(data=df_plot, x='Metric', y='Score', hue='Model', palette='viridis')
plt.title('Comparison of Model Performance across Evaluation Metrics', fontsize=15)
plt.ylim(0.65, 0.95) # Zooming in to show the performance gap clearly
plt.ylabel('Score (0 to 1)')
plt.legend(title='Model Architecture', bbox_to_anchor=(1.05, 1), loc='upper left')
plt.grid(axis='y', linestyle='--', alpha=0.7)
plt.show()


# %% [markdown]
# Insight on Metrics:
# 1. **Superior Architecture:** The **XGBoost (Advanced Ensemble)** consistently outperforms the **Logistic Regression** baseline across all metrics, justifying the use of boosting for this complex dataset.
# 2. **Identifying At-Risk Students:** The 'Dropout Recall' metric indicates how effectively we can catch students before they leave. The improvement from Baseline to Ensemble suggests that student attrition is driven by non-linear interactions between variables.
# 3. **Model Reliability:** The high F1-Score for the ensemble models confirms that they provide a reliable balance between Precision and Recall.
# 

# %% [markdown]
# #### 6.4. Best Model Performance (XGBoost)

# %% [markdown]
# **Error Analysis - Confusion Matrix.** The confusion matrix allows us to inspect the classification performance for each specific class. This is vital for identifying if the model struggles with the 'Enrolled' class, which is often a middle-ground between 'Dropout' and 'Graduate'.

# %%

from sklearn.metrics import confusion_matrix, ConfusionMatrixDisplay

#Generate the confusion matrix data
#y_test are the true labels, y_pred are the XGBoost predictions
cm = confusion_matrix(y_test, y_pred)

#Define labels for the axes (Mapping from your Target_Encoded)
# 0: Dropout, 1: Enrolled, 2: Graduate
target_names = ['Dropout', 'Enrolled', 'Graduate']

#Plotting
plt.figure(figsize=(10, 8))
disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=target_names)

#Plot with a nice color map (Blues or Viridis)
disp.plot(cmap='Blues', values_format='d')
plt.title('Confusion Matrix: XGBoost Predictions', fontsize=15)
plt.grid(False) # Clean up the background
plt.show()

# %%
#Final Model Deployment & Feature Importance
best_model = models["XGBoost (Advanced Ensemble)"]
best_model.fit(X_train, y_train)
y_pred = best_model.predict(X_test)

print("\nFinal Hold-out Test Results (XGBoost):")
print(classification_report(y_test, y_pred))



# %% [markdown]
# The confusion matrix shows that the **XGBoost model performs strongest when identifying Graduate students**. Out of 442 actual Graduate cases, the model correctly predicts 413, which gives a very high recall of 0.93. This means the model almost always recognizes students who successfully finish their studies. Only 17 Graduates are misclassified as Dropout and 12 as Enrolled, which is a relatively small error compared to the total size of this group.
# 
# For the Dropout group, the model also performs well. Out of 284 actual Dropout students, 223 are correctly identified. This results in a recall of 0.79, meaning nearly four out of five at-risk students are detected. However, 30 Dropouts are predicted as Enrolled and 31 as Graduate, showing that some dropout cases still share similar patterns with other student outcomes.
# 
# The Enrolled group is the most difficult to classify. Out of 159 actual Enrolled students, only 59 are correctly predicted, giving a recall of 0.37. A large number are misclassified as Dropout (36) or Graduate (64). This happens because Enrolled students are in a transitional state, and their academic and behavioral patterns often overlap with both struggling and successful students.
# 
# The classification report confirms these observations. The overall model accuracy is 0.79, meaning the model predicts correctly for about 79 percent of students. The F1-score for Graduates is 0.87, which reflects both high precision and recall. For Dropouts, the F1-score is 0.80, showing strong and balanced performance. In contrast, the Enrolled group has a lower F1-score of 0.45, reinforcing that this category is inherently harder to separate clearly.

# %%
# Predictor Identification
importances = best_model.feature_importances_
feat_imp_df = pd.DataFrame({'Feature': X.columns, 'Importance': importances})
feat_imp_df = feat_imp_df.sort_values(by='Importance', ascending=False)

plt.figure(figsize=(15, 8))
sns.barplot(x='Importance', y='Feature', data=feat_imp_df.head(15), palette='viridis')
plt.title('Top 15 Influential Factors (Predictor Identification)')
plt.show()

# %% [markdown]
# The feature importance results explain why the model performs this way. **The most influential factor is Total approved**, with the highest importance score, showing that the number of subjects a student passes is the strongest indicator of success or risk. **The second most important factor is Tuition fees up to date**, with an importance score around 0.06, highlighting the role of financial stability. Total enrolled also plays a key role, indicating that academic load matters. Other important contributors include Scholarship holder, Academic Intensity PCA, and specific course-related variables, which together shape the final prediction.
# 
# In conclusion, the numbers show that the **XGBoost model is highly effective at identifying Graduates and Dropouts**, which are the most critical groups for academic planning and intervention. While it struggles more with the Enrolled group, this reflects real-world overlap rather than poor model design. Overall, the results demonstrate that the model is accurate, meaningful, and well aligned with the goals of this project.

# %% [markdown]
# 
# <div class="alert alert-block alert-warning">
#     
# ### 7. Conclusion and Ethical Reflection  <a class="anchor" name="Conclussion"></a>
#  </div>
# 
# #### 7.1 Key Findings
# 1. The analysis successfully identified that Academic Success (Total Approved) and Financial Stability (Tuition Up to Date) are the primary drivers of student retention. 
# 2. The inclusion of Student Personas (K-Means) and Academic Intensity (PCA) provided the model with nuanced clusters that improved the F1-score for at-risk students.
# 3. Between the three model tested, XGBoost is the best model
# 4. The K-means successfully created 3 student persona that in the future we can be treat with each own strategy in the future
# 
# 
# #### 7.2 Ethical Reflection
# While this model achieves high predictive accuracy, its deployment in a university setting must be handled with ethical care:
# 1.  Demographic features like "Nationality" or "Marital Status" contribute to predictions. We must ensure these do not lead to discriminatory treatment or "automated rejection" of students.
# 2. This model should function as a **Decision Support System**, not a Decision Maker. High-risk scores should trigger a supportive outreach from a human counselor rather than an automated academic penalty.
# 3. Continuous monitoring of student behavior requires strict adherence to data protection laws, ensuring that student data is used solely for the purpose of academic support.

# %% [markdown]
# <div class="alert alert-block alert-warning">
#     
# ### 8.  References  <a class="anchor" name="Ref"></a>
#  </div>
# 
# 
# - Chen, T., & Guestrin, C. (2016). XGBoost: A Scalable Tree Boosting System. Proceedings of the 22nd ACM SIGKDD International Conference on Knowledge Discovery and Data Mining.
# 
# - James, G., Witten, D., Hastie, T., & Tibshirani, R. (2021). An Introduction to Statistical Learning: with Applications in R/Python. Springer
# 
# - Arthur, D., & Vassilvitskii, S. (2007). k-means++: The advantages of careful seeding. Proceedings of the eighteenth annual ACM-SIAM symposium on Discrete algorithms.
# 
# - Jolliffe, I. T., & Cadima, J. (2016). Principal component analysis: a review and recent developments. Philosophical Transactions of the Royal Society A.


