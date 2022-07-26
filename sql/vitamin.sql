CREATE DATABASE VITAMIN

USE VITAMIN

-- 1. ERD(Entity-Relationship Diagram)�� Ȱ���� ������ ��Ʈ ����

SELECT A.*
	   ,B.prod_cd
	   ,B.quantity
	   ,B.quantity * C.price AS sales_amt
	   ,C.brand
	   ,C.type
	   ,C.model
	   ,C.price
	   ,D.gender
	   ,D.age
	   ,D.join_date
	   ,E.addr
	   ,E.addr_no

INTO [vitamin_MART]
FROM [vitamin_order]A
LEFT JOIN [vitamin_orderdetail] B ON A.order_no = B.order_no
LEFT JOIN [vitamin_product]C ON B.prod_cd = C.prod_cd
LEFT JOIN [vitamin_member] D ON A.mem_no = D.mem_no
RIGHT JOIN [vitamin_addr] E ON D.addr_no = E.addr_no

-- [vitamin_MART] ���̺��� ��� �÷� ��ȸ
SELECT *
FROM [vitamin_MART]


-- 2. ���Ű� �������� �м�

USE VITAMIN

-- 1) ���ɴ�(ageband) �� �߰��� ���� �ӽ����̺�(#PROFILE_BASE) ����
SELECT *
	   , CASE WHEN age < 20 THEN '20�� �̸�'
			  WHEN age BETWEEN 20 AND 29 THEN '20��'
			  WHEN age BETWEEN 30 AND 39 THEN '30��'
			  WHEN age BETWEEN 40 AND 49 THEN '40��'
			  WHEN age BETWEEN 50 AND 59 THEN '50��'
			  ELSE '60�� �̻�' END AS ageband
INTO #PROFILE_BASE
FROM [vitamin_MART]


-- #PROFILE_BASE ��ȸ
SELECT *
FROM #PROFILE_BASE


-- 2) ���� �� ���ɴ뺰 ������ ����
--- (1) ���� ������ ����
SELECT gender
	   ,COUNT(DISTINCT mem_no) AS tot_mem
  FROM #PROFILE_BASE
 GROUP
	BY gender 

--- (2) ���ɴ뺰 ������ ����
SELECT ageband
	   ,COUNT(DISTINCT mem_no) AS tot_mem
  FROM #PROFILE_BASE
 GROUP
	BY ageband 

--- (3) ���� �� ���ɴ뺰 ������ ����
SELECT gender
	   ,ageband
	   ,COUNT(DISTINCT mem_no) AS tot_mem
  FROM #PROFILE_BASE
 GROUP
	BY gender
	   ,ageband
 ORDER
    BY 1

-- 3) ����, ���ɴ뺰, ������ ������ ����

SELECT gender
	   ,ageband
	   ,COUNT(DISTINCT CASE WHEN YEAR(order_date)=2021 THEN mem_no END) AS tot_mem_2021
	   ,COUNT(DISTINCT CASE WHEN YEAR(order_date)=2022 THEN mem_no END) AS tot_mem_2022
  FROM #PROFILE_BASE
 GROUP
	BY gender
	   ,ageband
 ORDER
    BY 1



	
-- 3. RFM ������ȭ �м�(Recency �ֱټ�, Frequency ���ź�, Monetary ���űݾ�)

USE VITAMIN

-- 1) ���� RFM ���� �ӽ� ���̺� ����

SELECT mem_no 
	   ,SUM(sales_amt) AS tot_amt --(Monetary ���űݾ�)
	   ,COUNT(order_no) AS tot_tr --(Frequency ���ź�)
  INTO #RFM_BASE
  FROM [vitamin_MART]
 WHERE YEAR(order_date) BETWEEN 2021 AND 2022
 GROUP
	BY mem_no

SELECT *
  FROM #RFM_BASE

-- 2) �� ����ȭ

SELECT A.*
       ,B.tot_amt
	   ,B.tot_tr
	   ,CASE WHEN B.tot_amt >= 1000000 AND B.tot_tr >= 3 THEN '1_VVIP'
	         WHEN B.tot_amt >= 500000 AND B.tot_tr >= 2 THEN '2_VIP'
			 WHEN B.tot_amt >= 300000 THEN '3_GOLD'
			 WHEN B.tot_amt >= 100000 THEN '4_SILVER'
			 WHEN B.tot_tr >= 1 THEN '5_BRONZE'
			 ELSE '6_POTENTIAL' END AS segmentation

  INTO #RFM_BASE_SEG
  FROM [vitamin_member] A
  LEFT
  JOIN #RFM_BASE B
    ON A.mem_no = B.mem_no

SELECT *
  FROM #RFM_BASE_SEG

 
-- 3) �� ����ȭ�� �� �� �� ���� ���� �ľ�

SELECT segmentation
	   ,COUNT(mem_no) AS tot_mem
	   ,SUM(tot_amt) AS tot_amt

  FROM #RFM_BASE_SEG
 GROUP
	BY segmentation
 ORDER 
    BY 1


-- 4. ������ȯ�� �� �����ֱ� �м�

-- 1) ������ȯ�� ���� �ӽ� ���̺� ����

USE VITAMIN

-- 2021������ �� 2022 ���ſ��� ���߰��� �����̺� ����
SELECT A.mem_no AS pur_mem_2021
	   ,B.mem_no AS pur_mem_2022
	   ,CASE WHEN B.mem_no IS NOT NULL THEN 'Y' ELSE 'N' END AS retention_yn
  INTO #RETENTION_BASE
  FROM (SELECT DISTINCT mem_no FROM [vitamin_MART] WHERE YEAR(order_date) = 2021) A
  LEFT
  JOIN (SELECT DISTINCT mem_no FROM [vitamin_MART] WHERE YEAR(order_date) = 2022) B
    ON A.mem_no = B.mem_no

SELECT *
  FROM #RETENTION_BASE

-- 2) ������ȯ�� ���ϱ�
SELECT COUNT(pur_mem_2021) AS tot_mem
	   ,COUNT(CASE WHEN retention_yn = 'Y' THEN pur_mem_2021 END) AS retention_mem
  FROM #RETENTION_BASE


-- 3) ȸ�� ���� ������ �����ֱ⿡ �ʿ��� ���� �ӽ� ���̺� ����
SELECT addr_no
	   ,MIN(order_date) AS min_order_date
	   ,MAX(order_date) AS max_order_date
	   ,COUNT(DISTINCT order_no) -1 AS tot_tr_1
  INTO #CYCLE_BASE
  FROM [vitamin_MART]
 GROUP 
    BY addr_no
HAVING COUNT(DISTINCT order_no) >= 2  -- ����Ƚ�� 2ȸ �̻� ���͸�(����Ƚ���� 1ȸ�̸� �и� 0�� �Ǳ⶧��)

SELECT *
  FROM #CYCLE_BASE


-- 4) ȸ������ ������ �����ֱ� ���ϱ�
SELECT *
	   ,DATEDIFF(DAY, min_order_date, max_order_date) AS diff_day
	   ,DATEDIFF(DAY, min_order_date, max_order_date)*1.00 /tot_tr_1 AS cycle
  FROM #CYCLE_BASE
 ORDER
	BY 6 DESC


-- 5. ��ǰ �� ����� �м�

-- 1) �귣�� �� �𵨺� 2021, 2022�� ���űݾ� ���� �ӽ� ���̺� ����

USE VITAMIN

SELECT brand
       ,model
	   ,SUM(CASE WHEN YEAR(order_date) = 2021 THEN sales_amt END) AS tot_amt_2021
	   ,SUM(CASE WHEN YEAR(order_date) = 2022 THEN sales_amt END) AS tot_amt_2022
  INTO #PRODUCT_GROWTH_BASE
  FROM [vitamin_MART]
 GROUP
    BY brand
	   ,model

SELECT *
  FROM #PRODUCT_GROWTH_BASE

-- 2) �귣�庰 ����� �ľ�
SELECT brand
	   ,SUM(tot_amt_2022) / sum(tot_amt_2021) -1*1.00 AS growth
  FROM #PRODUCT_GROWTH_BASE
 GROUP
    BY brand
 ORDER
    BY 2 DESC

-- 3) �� �귣�庰 �� ����� ����
SELECT *
       ,ROW_NUMBER() OVER(PARTITION BY brand ORDER BY growth DESC) AS rnk
  FROM (
       SELECT brand
	          ,model
			  ,SUM(tot_amt_2022) / SUM(tot_amt_2021) -1 AS growth
	     FROM #PRODUCT_GROWTH_BASE
		GROUP
		   BY brand
		      ,model
	    )A


-- 4) �� �귣�庰 ����� TOP2 �𵨸� ���͸�
SELECT *
  FROM (
       SELECT *
			  ,ROW_NUMBER() OVER(PARTITION BY brand ORDER BY growth DESC) AS rnk
		 FROM (
			  SELECT brand
					 ,model
					 ,SUM(tot_amt_2022) / SUM(tot_amt_2021) -1 AS growth
			  FROM #PRODUCT_GROWTH_BASE
			 GROUP
				BY brand
				   ,model
			  )A
	    )B
WHERE rnk <= 2

