<div align="center">
    <h2 style="font-size: 44 px;"> 📊 Customer Churn & Retention Analysis </h2><br>
</div>

![Customer Churn & Retention Analysis](<img width="1326" height="744" alt="Screenshot 2026-04-26 185628" src="https://github.com/user-attachments/assets/1a19850f-70fd-4032-8537-34dd7ec518f9" />
)


<p align="center">
  <img src="https://img.shields.io/github/repo-size/srideepgit/Customer-Churn-Retention-Analysis" alt="Repo Size">
  <img src="https://img.shields.io/badge/Project-Customer%20Churn%20%26%20Retention-blue">
  <img src="https://img.shields.io/badge/Tech-SQL%20%7C%20MongoDB%20%7C%20Python%20%7C%20PowerBI-orange">
  <img src="https://img.shields.io/badge/Status-Completed-brightgreen">
</p>

## 🔍 Project Overview
This project analyzes customer churn using data from multiple sources (SQL + MongoDB).  
The goal is to identify key drivers of churn and provide actionable insights for improving customer retention.

<a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ"><img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif"></a>

## 🎯 Objectives
- Understand factors influencing customer churn
- Analyze support tickets and engagement behavior
- Evaluate onboarding funnel drop-offs
- Build an interactive dashboard for business insights

<a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ"><img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif"></a>

## 🗂️ Data Sources

### SQL (PostgreSQL)
- `customers`
- `subscriptions`
- `plans`
- `support_tickets`

### MongoDB
- `user_activity_logs`
- `onboarding_events`
- `nps_survey_responses`

<a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ"><img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif"></a>

## ⚙️ Data Processing

### Key Steps:
- Data cleaning (handling NULLs, duplicates, inconsistencies)
- Schema alignment between SQL and MongoDB
- Feature engineering:
  - `is_churned`
  - `total_tickets`
  - `engagement_proxy`
  - `segment`

<a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ"><img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif"></a>

## 📈 Analysis Performed

### SQL
- Plan-level metrics (active customers, revenue, ticket rate)
- Customer LTV ranking using window functions
- Downgrade behavior analysis
- Time-series churn trends
- Duplicate account detection

### MongoDB
- Session analysis
- Feature usage tracking
- Onboarding funnel analysis
- User engagement insights

### Python
- Data wrangling and merging datasets
- Exploratory data analysis (EDA)
- Hypothesis testing (Mann–Whitney U Test)

<a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ"><img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif"></a>

## 📊 Dashboard (Power BI)

### Key Visuals:
- Churn rate overview
- Support tickets vs churn
- Engagement vs churn
- Customer segmentation
- Top churning industries

### Filters:
- Segment
- Plan Tier

<a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ"><img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif"></a>

## 📌 Key Insights

1. Support ticket volume does not significantly impact churn  
2. Engagement levels are similar for churned and active users  
3. Major drop-offs occur during onboarding stages  

<a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ"><img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif"></a>

## 🧠 Hypothesis Testing

- **Test Used:** Mann–Whitney U Test  
- **Result:** No significant difference in ticket volume between churned and active users  
- **Conclusion:** Churn is likely driven by product experience or onboarding, not support load  

<a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ"><img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif"></a>

## 🛠️ Tools & Technologies

- Python (Pandas, NumPy, SciPy)
- PostgreSQL
- MongoDB
- Power BI
- Google Colab

<a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ"><img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif"></a>

## 🚀 How to Run

1. Load SQL data into PostgreSQL  
2. Import MongoDB collections  
3. Run the Python notebook (`.ipynb`)  
4. Export `final_data.csv`  
5. Load into Power BI to view dashboard  

<a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ"><img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif"></a>

## 📹 Video Walkthrough
[[Drive link](https://drive.google.com/file/d/1lc-tIVncjNOkKpJZrAGLJupmwStwUFfh/view?usp=sharing)]

<a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ"><img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif"></a>

## 📂 Repository Structure

