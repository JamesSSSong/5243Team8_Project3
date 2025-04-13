# Project 3: A/B Test with Shiny Web App - Full Instruction Guide

## Overview
This project involves designing and conducting an A/B Test using a web app built with R Shiny. You'll create two versions of the app, collect user interaction data, analyze the results using statistical techniques, and submit a structured report along with reproducible code.

---

## Step-by-Step Instructions

### Step 1: Choose the A/B Test Option
You are selecting the A/B testing route instead of a traditional experiment. This means you will build (or reuse) a Shiny app and create two slightly different versions of it to test how a change affects user behavior.

---

### Step 2: Formulate a Research Question
Come up with a hypothesis or question that your A/B test can answer. Example questions:

- Does changing the button color increase form submission rate?
- Does reordering the questions improve survey completion?
- Does adding tooltips help users complete tasks faster?

---

### Step 3: Design the A/B Test

1. **Build Two Versions of Your Shiny App:**
   - **Version A (Control):** Original version
   - **Version B (Treatment):** Includes one meaningful change (UI, layout, content, etc.)

2. **Incorporate a Survey or Task:**
   - Create a form or survey inside the app
   - Ensure users interact with it (e.g., fill out answers, click buttons)

3. **Key Metrics to Track:**
   - Task completion rate
   - Time taken to complete task
   - Click-through rates

4. **Random Assignment to Versions:**
   - Use URL parameters (e.g., `?group=A` or `?group=B`)
   - Or use cookies to consistently assign users to a version

---

### Step 4: Collect Data

- Log each user’s group (A or B)
- Capture interaction metrics (e.g., clicks, completions, time)
- Use R code or Google Analytics (optional)
- Make sure data is clean, organized, and documented

---

### Step 5: Analyze the Data

- Use appropriate statistical tests:
  - **T-tests** for comparing means (e.g., time)
  - **Chi-squared tests** for proportions (e.g., completion rate)
  - **Regression models** for multi-variable analysis
- Evaluate whether differences are statistically significant

---

### Step 6: Interpret Results

- Answer your research question:
  - Was there a significant improvement?
  - How strong is the effect?
- Discuss implications of the findings
- List limitations (sample size, user diversity, measurement errors)

---

### Step 7: Write the Final Report (Due April 23rd, 11:59 PM)
Your report should be well-structured and include:

1. **Introduction & Research Question**
2. **Experimental Design & Methodology**
3. **Data Collection**
4. **Statistical Analysis & Results**
5. **Interpretation & Conclusion**
6. **Challenges & Limitations**

---

### Step 8: Submit Code & GitHub Repository

- Upload your R (or Python) code with clear comments
- Create a GitHub repo that includes:
  - Your code files
  - A `README.md` file with:
    - Description of the experiment
    - How to run the app and analysis
    - Explanation of each file

---

## Evaluation Rubric (60 points total)

| Category                 | Points | Description                                                                 |
|--------------------------|--------|-----------------------------------------------------------------------------|
| Experimental Design      | 10     | Clear hypothesis and sound methodology                                      |
| Data Collection & Quality| 10     | High-quality, well-documented data                                          |
| Statistical Analysis     | 10     | Correct methods and clear interpretations                                   |
| Results & Insights       | 10     | Meaningful conclusions and insights                                         |
| Report Writing           | 10     | Structured, clear, and professionally formatted                             |
| Code & Reproducibility   | 10     | Clean, commented, and reproducible code                                     |

---

## Tips for Success
- Keep the design change between versions simple and focused
- Collect data from enough users (share link with friends/classmates)
- Document everything carefully
- Test your app thoroughly before collecting data

---

Need help with app ideas or R Shiny setup? Just ask!
