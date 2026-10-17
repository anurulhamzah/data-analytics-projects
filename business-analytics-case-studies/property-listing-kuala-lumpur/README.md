# Property Listing in Kuala Lumpur

Exploratory and statistical analysis (correlation and regression) of property listings in Kuala Lumpur, to understand the company's product and find how to maximise its 20% profit share on property sales.

**Tools and methods:** Spreadsheet, XLMiner Analysis ToolPak, EDA, descriptive statistics, correlation, regression, assumption checks

## Business context
ABC Company lists properties in Kuala Lumpur and other major Malaysian cities and earns 20% of the profit through a joint profit-sharing arrangement. High-priced properties with many or oversized rooms are harder to sell.

## Objectives
- Extract insight from the dataset.
- Find which attributes have the strongest relationship with price.
- Make recommendations.

## Process
Exploratory data analysis, descriptive statistics, correlation, regression, assumption checks.

## Key insights
- The most common listing is a partly furnished built-up condominium.
- Each property class has its own profile, with price following size and facilities:
  - Affordable: 3 rooms, 3 bathrooms, 2 car parks
  - Reasonable: 4 rooms, 4 bathrooms, 2 car parks
  - Luxury: 5 rooms, 5 bathrooms, 2 car parks
- Mont Kiara and KLCC have the most listings.
- Of three regression models tested, the third performed best, with all variables significant at the 5% level.

## Recommendations
- Segment potential customers by economic circumstances.
- Let buyers choose area by property type, since property types differ by region.
- Large homes (about 6 rooms, 6 bathrooms, 8,681 sqft at about RM 1,072/sqft): Country Heights Damansara, Bukit Tunku, Bangsar South.
- Affordable homes (about 4 rooms, 3 bathrooms, 2,262 sqft at about RM 535/sqft): Gombak, Mid Valley City, Sunway SPK.
- Smaller homes (2 rooms, 2 bathrooms, 804 sqft): KL City, KLCC, Brickfields.

## Limitations and next steps
- The regression model violates the homoscedasticity assumption, so the model needs review with the head of data.
- Review outliers, try other combinations of independent variables, and check all linear regression assumptions.

## Contents
- [report.pdf](report.pdf): full presentation
