# Project 3 : Designing and Conducting an Experiment (or A/B Test)

## Project Overview

Experiments play a crucial role in statistical studies, allowing researchers to establish
causal relationships and evaluate the effectiveness of interventions. Experimental design is
a fundamental aspect of scientific inquiry, ensuring that studies are conducted
systematically, with minimized bias and maximized reliability. A well-designed experiment
allows researchers to test hypotheses, measure the effects of different treatments, and
derive actionable insights from data.

In the context of applied data science, one common experimental framework is **A/B testing** ,
widely used in fields like web optimization, marketing, and product development. A/B testing
is a controlled experiment where two (or more) versions of a system (e.g., a webpage, an
email campaign, or an advertisement) are compared to determine which performs better
based on predefined metrics such as conversion rates, engagement, or user satisfaction.

Experiments, whether A/B tests or traditional scientific studies, require careful planning to
ensure valid and meaningful results. This project will give you hands-on experience
designing, executing, and analyzing an experiment, reinforcing key principles of
experimental design and data-driven decision-making.

## Project Objectives

By completing this project, you will:

- Design and conduct an experiment or an A/B Test that aligns with real-world decision-
    making scenarios.
- Collect and analyze data to assess the impact of the experiment.
- Apply statistical methods to evaluate results and determine the significance of findings.
- Communicate insights through a structured report, summarizing your findings.

## Project Expectations

Each group should:

- **Formulate a Research Question** : Identify a problem or hypothesis that can be tested
    experimentally.
- **Design the Experiment or A/B Test** : carefully design the experiment, define the control
    and treatment groups, specify key metrics, and ensure randomness in assignment.


- **Collect and Process Data** : Gather data either from real users (if feasible) or simulated
    environments.
- **Analyze the Data** : Use statistical techniques to compare groups and evaluate the
    significance of differences.
- **Interpret and Report Findings** : Summarize results, discuss limitations, and provide
    actionable conclusions.

## Project Deliverables [Due on April 23 rd at 11:59PM]

1. **Final Report:** A well-structured report including
    - Introduction & Research Question
    - Experimental Design & Methodology
    - Data Collection
    - Statistical Analysis & Results
    - Interpretation & Conclusion
    - Challenges & Limitations
2. **Code Files** : A well-commented Python and/or R script(s) containing the full workflow
    (these files should be submitted in a GitHub repository with proper documentation;
    include a README file with instructions on how to run the code).

## Conducting an A/B Test

If your team chooses to conduct an A/B test, you can use the Shiny web application you
developed in the previous project or build a new one specifically for this experiment. The
application should have two distinct versions, where some elements are modified to test
their impact on user behavior. Examples of possible modifications include:

- **Visual Design Changes** : Altering color schemes, button placement, font styles, or layout

## structures.

- **Feature Modifications** : Adding or removing interactive elements, changing the way

## users navigate through the app, or modifying input fields.

- **Content Adjustment** : Experimenting with different text descriptions, tooltips, or

## instructional messages.

To evaluate the effectiveness of these changes, you must define key performance metrics.
Examples are


- Click-through rates (CTR)
- Time spent on different sections of the app
- Task completion rates (e.g., how many users successfully submit a form)
- Bounce rates or exit rates

To enhance the scope of your analysis, you can integrate **Google Analytics** into your Shiny
app to collect additional user engagement metrics. Here are some useful links on this topic:

- Adding Google Analytics
- Event Tracking with Google Analytics
- R Shiny Google Analytics

Another critical aspect of A/B testing is ensuring that users are randomly assigned to
different versions of the app. Some possible methods include:

- **URL Parameters** : Assigning users to a version based on a query string in the URL (e.g.,
    app.com?group=A vs. app.com?group=B)
- **Cookie-Based Assignment** : Storing the assigned group in a cookie so that users
    consistently see the same version.

Finally, since our class is small, you should take proactive measures to collect enough data
for meaningful analysis. For example,

- Share the app version with fellow students in the class to generate more user
    interactions.
- Expand participation by sharing the app with the public, such as on social media, forums,
    or through friends.

## Evaluation Rubrics

**1. Experimental Design [0 – 10 pt]**
    - Basic [ 3 pt] – Research goal/hypothesis lacks clarity, weak control/treatment setup.
    - Intermediate [ 6 pt] – Clearly defined research goals/hypothesis with reasonable
       design.
    - Advanced [ 10 pt] – Well-structured, justified research goals/hypothesis with strong
       methodology.


**2. Data Collection and Quality [0 – 10 pt]**
    - Basic [ 3 pt] – Uses an already existing dataset without modification or collects limited
       data with gaps in documentation.
    - Intermediate [ 6 pt] – Collects original data but may have some missing
       documentation or minor quality issues.
    - Advanced [ 10 pt] – Collects high-quality, well-organized data with thorough
       documentation and justification for data choices.
**3. Statistical Analysis [0 – 10 pt]**
    - Basic [ 3 pt] – Minimal or incorrect statistical methods applied.
    - Intermediate [ 6 pt] – Appropriate methods used but with some gaps in analysis.
    - Advanced [ 10 pt] – Strong statistical analysis with correct interpretations.
**4. Results and Insights [0 – 10 pt]**
    - Basic [ 3 pt] – Findings lack clarity, weak discussion.
    - Intermediate [ 6 pt] – Clear presentation of results with reasonable interpretations.
    - Advanced [ 10 pt] – Insightful, well-supported conclusions with meaningful
       discussion.
**5. Report Structure and Writing [0 – 10 pt]**
    - Basic [ 3 pt] – Report lacks logical structure; sections are unclear or missing; poor
       formatting.
    - Intermediate [ 6 pt] – Report follows a logical structure but may have minor
       organization issues; adequate formatting.
    - Advanced [ 10 pt] – Report is well-structed, with clear headings, logical flow, and
       smooth transitions; professionally formatted.

## 6. Code and Reproducibility [0 – 10 pt]

- Basic [ 3 pt] – Poorly documented or difficult to reproduce.
- Intermediate [ 6 pt] – Code is functional with moderate documentation.
- Advanced [ 10 pt] – Well-documented, easily reproducible code with explanations.
