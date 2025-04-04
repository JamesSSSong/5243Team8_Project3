title: "Project 3: Designing and Conducting an Experiment (or A/B Test)"
output: github_document

## Project Overview

Experiments play a crucial role in statistical studies, allowing researchers to establish causal relationships and evaluate the effectiveness of interventions. Experimental design ensures that studies are conducted systematically, with minimized bias and maximized reliability.

In applied data science, A/B testing is a common framework used in web optimization, marketing, and product development. It compares two or more versions of a system (e.g., a webpage or ad) to determine which performs better based on metrics like conversion rates or engagement.

This project provides hands-on experience in designing, executing, and analyzing an experiment, reinforcing key principles of experimental design and data-driven decision-making.

---

## Project Objectives

By completing this project, you will:

- Design and conduct an experiment or A/B test aligned with real-world decision-making.
- Collect and analyze data to assess the impact of the experiment.
- Apply statistical methods to evaluate the significance of findings.
- Communicate insights through a structured report.

---

## Project Expectations

Each group should:

- **Formulate a Research Question:** Identify a problem or hypothesis testable via experimentation.
- **Design the Experiment or A/B Test:** Define control/treatment groups, metrics, and ensure random assignment.
- **Collect and Process Data:** Use real or simulated environments to gather data.
- **Analyze the Data:** Use statistical techniques to compare groups and assess significance.
- **Interpret and Report Findings:** Summarize results, discuss limitations, and provide actionable insights.

---

## Project Deliverables *(Due April 23rd at 11:59 PM)*

1. **Final Report:**  
   - Introduction & Research Question  
   - Experimental Design & Methodology  
   - Data Collection  
   - Statistical Analysis & Results  
   - Interpretation & Conclusion  
   - Challenges & Limitations  

2. **Code Files:**  
   - Well-commented R or Python scripts  
   - Submit via GitHub with documentation and a `README.md` explaining how to run the code

---

## Conducting an A/B Test (Optional)

You may use a Shiny web app for your A/B test. Your app should have two distinct versions with modified elements such as:

- **Visual Design Changes**: Colors, button placement, fonts, layout.
- **Feature Modifications**: Adding/removing inputs, changing flow/navigation.
- **Content Adjustments**: Text, tooltips, or messaging.

### Example Metrics:
- Click-through rate (CTR)  
- Time spent on sections  
- Form submission rate  
- Bounce or exit rates

Consider using **Google Analytics** to collect user behavior data:
- [Adding Google Analytics](https://shiny.posit.co/r/articles/build/google-analytics/)  
- [Event Tracking](https://hypebright.nl/en/r-en/event-tracking-your-shiny-application-with-google-analytics/)  
- [Appsilon GA for R Shiny](https://www.appsilon.com/post/r-shiny-google-analytics)

### Random Assignment Methods:
- **URL Parameters:** `?group=A` vs. `?group=B`
- **Cookie-Based Assignment**

### Increasing Sample Size:
- Share your app with classmates or publicly to gather more data.

---

## Evaluation Rubrics

| Category                     | Basic (3pt)         | Intermediate (6pt)               | Advanced (10pt)                            |
|-----------------------------|---------------------|----------------------------------|--------------------------------------------|
| **Experimental Design**     | Unclear goals       | Reasonable structure             | Well-structured and justified methodology  |
| **Data Collection & Quality** | Limited data        | Original data with minor gaps    | High-quality data with clear documentation |
| **Statistical Analysis**    | Incorrect methods   | Appropriate but incomplete       | Strong and well-interpreted analysis       |
| **Results & Insights**      | Weak discussion     | Reasonable interpretation        | Insightful conclusions with clear support  |
| **Report Structure**        | Poor formatting     | Adequate organization            | Clear structure, flow, and professionalism |
| **Code & Reproducibility**  | Poor documentation  | Functional with comments         | Fully reproducible and well-documented     |

---

*End of README*
