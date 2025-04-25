# Project 3 : A/B Test

This project evaluates whether adding a guided tutorial improves user engagement in a Shiny web application. The experiment was conducted using A/B testing methodology with randomized user group assignment and user behavior tracking through Google Analytics.

Deployed Web App: https://ruoshi-zhang.shinyapps.io/Project3_AB_test/

## Project Goal

To determine if a tutorial overlay improves user interaction metrics such as:
- Click-through rate (CTR)
- Bounce rate
- Average session duration

Users were randomly assigned to either:
- **Version A**: App with a guided tutorial pop-up (treatment group)
- **Version B**: App without the tutorial (control group)

## Project Overview

This project implements an A/B test using a Shiny web application called *Interactive Data Analysis App*. Users were randomly assigned to each version via URL query parameters, and user engagement was tracked using Google Analytics. Key events, including button clicks, bounce rate, and average session time were recorded and compared to determine which version performed better.

## GitHub Files

- `web_dev (V1).R`: Simply the original version from Project 2. It served as the base code for this project. (control version)
- `web_dev (V2).R`: Contains code for tutorial pop-up window and Google Analytics integration, along with original code for web design. The deployed web link was shared with fellow students in the class  for collecting data. (Treatment)
- `AB_test_codes.qmd`: Includes statistical tests implemented for testing CTR, bounce rate, and session time for both groups.
- `Total.csv` & `Group Data.csv`: Data exported from Google Analytics. They includes all the necessary data used in statistical test. 
- `Final_Report.qmd` & `Final_Report.pdf`: Final report files

Please note: Branch `main` contains files for submission. Branch `history` includes all the files each group member worked with and uploaded.

## Contribution

- **A/B Testing Design**:  *Ruoshi Zhang*, *Dailin Song*, *Yi Lu*

- **Google Analytics Data Collection**:  *Ruoshi Zhang*, *Dailin Song*, *Yi Lu*  

- **Statistical Testing for A/B Groups**:  *Yi Lu*  

- **Final Report Writing**:  *Ruoshi Zhang*

## Results Summary

The tutorial improved directional guidance and task efficiency but had limited effect on increasing user engagement or retention. Group A users completed tasks more directly, while Group B users engaged in more exploratory behavior.
