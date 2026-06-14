CREATE DATABASE project;
USE project;

/* Question 1: Who are the genuinely loyal customers vs. those who only buy when there is a discount? */

WITH customer_types AS (
    SELECT
        customer_id,
        total_spend,
        previous_purchases,
        loyalty_score_2,
        promo_dependency_score,
        organic_spend_ratio,

        CASE
            WHEN loyalty_score_2 >= 0.70
                 AND promo_dependency_score <= 0.30
                 AND organic_spend_ratio >= 0.70
            THEN 'Genuine Loyal'

            WHEN promo_dependency_score >= 0.60
                 OR organic_spend_ratio <= 0.40
            THEN 'Discount-Driven'

            ELSE 'Hybrid'
        END AS customer_type

    FROM cleaned_data
)

SELECT
    customer_type,
    COUNT(*) AS customers,
    ROUND(AVG(total_spend),2) AS avg_spend,
    ROUND(AVG(previous_purchases),2) AS avg_repeat_purchases,
    ROUND(AVG(loyalty_score_2),2) AS avg_loyalty,
    ROUND(AVG(promo_dependency_score),2) AS avg_promo_dependency
FROM customer_types
GROUP BY customer_type
ORDER BY avg_spend DESC;


/* Q1:
Business Insight:
Genuine Loyal customers account for 57.55% of the customer base (2,223 customers) and exhibit substantially higher loyalty scores (65.16) than Discount-Driven customers (34.44). Although Discount-Driven customers show slightly higher repeat purchases (25.73 vs. 25.06), their complete reliance on promotions indicates that repeat purchasing alone is not a true measure of customer loyalty.

Recommended Action:
Focus retention efforts on Genuine Loyal customers through exclusive benefits, personalized experiences, and loyalty programs, as they generate comparable spending (60.13 vs. 59.12) without requiring discounts. For Discount-Driven customers, replace broad promotions with targeted offers to reduce promotional dependency and improve profit margins.
*/




/* Question 2: What behavioral patterns today predict High Customer Value over time?*/

WITH ranked_customers AS (
    SELECT *,
           NTILE(4) OVER (
               ORDER BY value_score DESC
           ) AS value_quartile
    FROM cleaned_data
)

SELECT
    value_quartile,
    COUNT(*) AS customers,
    ROUND(AVG(previous_purchases),2) AS avg_previous_purchases,
    ROUND(AVG(category_diversity),2) AS avg_category_diversity,
    ROUND(AVG(product_diversity),2) AS avg_product_diversity,
    ROUND(AVG(avg_review_rating),2) AS avg_review_rating,
    ROUND(AVG(loyalty_score_2),2) AS avg_loyalty
FROM ranked_customers
GROUP BY value_quartile
ORDER BY value_quartile;


/* Q2:
Business Insight:
Customers in the highest value quartile exhibit significantly higher previous purchase counts (32.01 vs. 18.38) and stronger loyalty scores (67.16 vs. 37.67) compared to those in the lowest value quartile. In contrast, category diversity and product diversity remained constant across all groups, while review ratings showed minimal variation (3.72–3.78). These findings suggest that repeat purchasing behavior and loyalty are the strongest indicators of future customer value within the current customer base.

Recommended Action:
Prioritize strategies that encourage repeat purchases and strengthen customer loyalty, such as personalized engagement campaigns, loyalty programs, and post-purchase relationship building. Since product diversity and review ratings show limited differentiation, marketing investments should focus on increasing purchase frequency among medium-value customers to accelerate their progression into higher-value segments.
*/




/* Question 3: Which geographies and demographics are commercially underlevered?*/

-- Q3 (Part A): Commercially Underleveraged Geographies
SELECT
    location,
    COUNT(*) AS customers,
    ROUND(AVG(total_spend),2) AS avg_spend,
    ROUND(AVG(loyalty_score_2),2) AS avg_loyalty,
    ROUND(AVG(organic_demand_score),2) AS organic_demand,
    ROUND(
        AVG(loyalty_score_2) *
        AVG(organic_demand_score),
        2
    ) AS market_opportunity_score

FROM cleaned_data
GROUP BY location
HAVING COUNT(*) >= 20
ORDER BY market_opportunity_score DESC;

-- Q3 (Part B): Commercially Underleveraged Demographics
SELECT
    CASE
        WHEN age < 30 THEN '18-29'
        WHEN age BETWEEN 30 AND 45 THEN '30-45'
        ELSE '46+'
    END AS age_group,

    gender,
    COUNT(*) AS customers,
    ROUND(AVG(total_spend),2) AS avg_spend,
    ROUND(AVG(loyalty_score_2),2) AS avg_loyalty,
    ROUND(AVG(organic_demand_score),2) AS avg_organic_demand,
    ROUND(
        AVG(loyalty_score_2) *
        AVG(organic_demand_score),
        2
    ) AS demographic_opportunity_score

FROM cleaned_data

GROUP BY
    age_group,
    gender

HAVING COUNT(*) >= 20

ORDER BY
    demographic_opportunity_score DESC;


/* Q3:
Business Insight:
The analysis identified significant variations in commercial potential across both geographies and demographic groups. Arizona and Alaska emerged as the strongest geographic opportunities, recording market opportunity scores of 2097.34 and 2049.81, respectively, driven by high loyalty and organic demand. Demographically, females aged 18–29 exhibited the highest opportunity score (2713.52), supported by strong loyalty (66.33) and organic demand (40.91), despite representing a relatively smaller customer segment. These findings suggest that several high-potential markets remain underleveraged and offer substantial opportunities for sustainable growth.
Certain geographies and demographic segments exhibit high loyalty and strong organic demand despite having relatively smaller customer bases, indicating that they are commercially underleveraged. This suggests that the brand has untapped growth opportunities within these segments that have not yet been fully targeted through marketing efforts.

Recommended Action:
The brand should prioritize expansion efforts in high-opportunity states such as Arizona and Alaska while designing targeted acquisition and retention strategies for high-potential demographic segments, particularly females aged 18–29. Personalized campaigns, loyalty initiatives, and localized marketing efforts should be deployed to maximize engagement within these segments. Simultaneously, marketing spend in lower-opportunity markets should be optimized to ensure efficient allocation of resources and improved return on investment.
*/





/* Question 4: How should the brand restructure its promotional strategy to protect margins without losing volume? */

SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(AVG(discount_sensitivity_score),2) AS discount_sensitivity,
    ROUND(AVG(promo_dependency_score),2) AS promo_dependency,
    ROUND(AVG(avg_discount_spend),2) AS avg_discount_spend,
    ROUND(AVG(avg_non_discount_spend),2) AS avg_organic_spend,
    ROUND(
        AVG(avg_non_discount_spend) -
        AVG(avg_discount_spend),
        2
    ) AS margin_protection_potential

FROM cleaned_data
GROUP BY customer_segment
ORDER BY margin_protection_potential DESC;


/* Q4:
Business Insight:
Organic Loyalists represent a highly profitable segment, generating the highest average organic spend (88.79) without any promotional dependency. Regular Customers also contribute healthy organic spending (60.19) while remaining insensitive to discounts. In contrast, Discount Hunters, despite constituting the largest segment (1,640 customers), exhibit complete promotional dependence and a negative margin protection potential (-59.12), indicating that their purchases are largely sustained through discounts rather than genuine brand preference.

Recommended Action:
The brand should reduce blanket discounting and adopt a segmented promotional strategy. Organic Loyalists and Regular Customers should be retained through loyalty benefits, exclusive experiences, and personalized engagement instead of price-based incentives. For Discount Hunters, promotions should transition toward targeted and conditional offers aimed at gradually reducing discount dependency while preserving purchase volume. This approach will help protect margins without significantly impacting customer retention.
*/




/* Question 5: What does the brand's Ideal Customer Profile (ICP) look like, and how can it acquire more of them? */

WITH ideal_customers AS (
    SELECT *
    FROM cleaned_data
    WHERE value_tier = 'Platinum'
)

SELECT
    gender,
    subscription_status,
    preferred_shipping,
    preferred_payment,
    purchase_frequency,

    COUNT(*) AS customer_count,
    ROUND(AVG(total_spend),2) AS avg_total_spend,
    ROUND(AVG(previous_purchases),2) AS avg_previous_purchases,
    ROUND(AVG(loyalty_score_2),2) AS avg_loyalty_score,
    ROUND(AVG(avg_review_rating),2) AS avg_review_rating

FROM ideal_customers

GROUP BY
    gender,
    subscription_status,
    preferred_shipping,
    preferred_payment,
    purchase_frequency

HAVING COUNT(*) >= 5

ORDER BY
    avg_total_spend DESC,
    avg_loyalty_score DESC,
    customer_count DESC;
    

/* Q5:
Business Insight:
The brand's highest-value customer profiles are characterized by high average spending (up to 95.80), strong loyalty scores (up to 87.52), and substantial repeat purchase behavior. Female customers appear prominently among the top-performing profiles, particularly those preferring debit card payments and standard or free shipping options. These findings suggest that ideal customers exhibit a combination of high engagement, consistent purchasing patterns, and positive brand experiences, making them strategically valuable for long-term growth.

Recommended Action:
The brand should leverage the characteristics of its ideal customers to refine acquisition strategies through lookalike audience targeting, personalized digital campaigns, and referral programs. Marketing messages should emphasize convenience, trust, and customer experience, while retention initiatives should reinforce the behaviors associated with high-value segments. By attracting customers with profiles similar to existing top performers, the brand can improve customer lifetime value and acquisition efficiency.
*/


/* Question 6: High Value vs Low Value Customers */

SELECT
    value_tier,
    ROUND(AVG(total_spend),2) AS avg_spend,
    ROUND(AVG(previous_purchases),2) AS avg_purchases,
    ROUND(AVG(total_transactions),2) AS avg_transactions,
    ROUND(AVG(loyalty_score_2),2) AS avg_loyalty,
    ROUND(AVG(category_diversity),2) AS avg_category_diversity,
    ROUND(AVG(product_diversity),2) AS avg_product_diversity,

    ROUND(
        SUM(
            CASE
                WHEN previous_purchases > 20 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS repeat_rate_percentage

FROM cleaned_data

GROUP BY value_tier

ORDER BY
    CASE value_tier
        WHEN 'Platinum' THEN 1
        WHEN 'Gold' THEN 2
        WHEN 'Silver' THEN 3
        WHEN 'Bronze' THEN 4
    END;


/* Q6:
Business Insight:
Platinum customers emerged as the most valuable segment, recording the highest average spend (88.51), strongest loyalty scores (67.22), and the highest repeat purchase rate (78.77%). In contrast, Bronze customers exhibited substantially lower spending (31.24), weaker loyalty (37.69), and the lowest repeat purchase rate (41.32%). The findings indicate that customer value is primarily driven by purchase frequency and loyalty rather than product or category diversity, which remained constant across all tiers.

Recommended Action:
The brand should implement strategies that encourage Bronze and Silver customers to emulate the behaviors of Platinum customers through personalized recommendations, tier-based loyalty programs, and targeted retention campaigns. Since repeat purchase behavior strongly correlates with customer value, initiatives aimed at increasing purchase frequency should be prioritized to improve customer lifetime value and facilitate progression into higher-value segments.
*/




/* Question 7: Which seasons and categories are associated with lower-tenure customers versus those with high previous purchase counts? */

WITH customer_tenure AS (

    SELECT
        Season,
        category,
        total_spend,
        loyalty_score_2,

        CASE
            WHEN previous_purchases <= 3 THEN 'New'

            WHEN previous_purchases <= 10 THEN 'Growing'

            ELSE 'Established'

        END AS tenure_segment

    FROM cleaned_data

)

SELECT

    Season,
    category,
    tenure_segment,
    COUNT(*) AS customers,
    ROUND(AVG(total_spend),2) AS avg_spend,
    ROUND(AVG(loyalty_score_2),2) AS avg_loyalty

FROM customer_tenure

GROUP BY

    Season,
    category,
    tenure_segment

HAVING COUNT(*) >= 5

ORDER BY

    FIELD(Season,'Spring','Summer','Fall','Winter'),

    category,

    FIELD(tenure_segment,'New','Growing','Established');


/* Q7
Business Insight:
Clothing emerged as the strongest retention category, consistently attracting the highest number of Established customers across all seasons, peaking at 361 customers during Winter. In contrast, categories such as Outerwear and Footwear were more prominent among New and Growing customers, often exhibiting higher average spend and loyalty scores. Notably, New customers purchasing Outerwear during Spring recorded the highest loyalty score (65.68), while Growing customers purchasing Footwear during Fall demonstrated both the highest average spend (74.00) and strong loyalty (62.53). These findings suggest that different categories play distinct roles in the customer lifecycle, serving either as acquisition channels or retention drivers.

Recommended Action:
The brand should position Clothing as a retention-focused category by prioritizing personalized recommendations, loyalty incentives, and cross-selling initiatives for established customers. Categories such as Outerwear and Footwear should be leveraged as acquisition and conversion tools through seasonal campaigns designed to attract New and Growing customers. By aligning category-specific marketing strategies with customer tenure stages, the brand can improve customer progression, strengthen retention, and maximize long-term customer value.
*/




/* Question 8: Which geographies signal organic demand versus discount-driven volume? */

WITH geography_scores AS (

    SELECT

        location,
        COUNT(*) AS customers,
        AVG(organic_spend_ratio) AS organic_ratio,
        AVG(promo_dependency_score) AS promo_dependency,
        AVG(total_spend) AS avg_spend

    FROM cleaned_data

    GROUP BY location
)

SELECT

    location,
    customers,
    ROUND(organic_ratio,2) AS organic_ratio,
    ROUND(promo_dependency,2) AS promo_dependency,
    ROUND(avg_spend,2) AS avg_spend,

    CASE

        WHEN organic_ratio >= 0.70
             AND promo_dependency < 0.30
        THEN 'Organic Growth Market'

        WHEN promo_dependency >= 0.50
        THEN 'Promotion-Dependent Market'

        ELSE 'Balanced Market'

    END AS market_type

FROM geography_scores

ORDER BY avg_spend DESC;


/* Q8:
Business Insight:
The majority of geographies (46 out of 50) were classified as Balanced Markets, indicating a healthy mix of organic demand and promotional influence. Kansas emerged as the strongest Organic Growth Market, exhibiting the highest organic spending ratio (0.76) and the lowest promotional dependency (0.24), suggesting strong brand affinity without heavy reliance on discounts. In contrast, Indiana, Iowa, and Oregon demonstrated the highest promotional dependency (0.57, 0.51, and 0.51, respectively), indicating that purchase volume in these regions is more discount-driven and potentially less sustainable.

Recommended Action:
Increase brand-building and customer acquisition investments in Organic Growth Markets such as Kansas, where strong organic demand provides opportunities for profitable expansion. Balanced Markets should be managed through a combination of loyalty initiatives and selective promotions to maintain engagement. For Promotion-Dependent Markets, transition from broad discounting to targeted offers and personalized campaigns to reduce promotional reliance, improve margins, and encourage more organic purchasing behavior over time.
*/



