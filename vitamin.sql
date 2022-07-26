CREATE DATABASE VITAMIN

USE VITAMIN

-- 1. ERD(Entity-Relationship Diagram)를 활용한 데이터 마트 구성

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

-- [vitamin_MART] 테이블의 모든 컬럼 조회
SELECT *
FROM [vitamin_MART]


-- 2. 구매고객 프로파일 분석

USE VITAMIN

-- 1) 연령대(ageband) 열 추가한 세션 임시테이블(#PROFILE_BASE) 생성
SELECT *
	   , CASE WHEN age < 20 THEN '20대 미만'
			  WHEN age BETWEEN 20 AND 29 THEN '20대'
			  WHEN age BETWEEN 30 AND 39 THEN '30대'
			  WHEN age BETWEEN 40 AND 49 THEN '40대'
			  WHEN age BETWEEN 50 AND 59 THEN '50대'
			  ELSE '60대 이상' END AS ageband
INTO #PROFILE_BASE
FROM [vitamin_MART]


-- #PROFILE_BASE 조회
SELECT *
FROM #PROFILE_BASE


-- 2) 성별 및 연령대별 구매자 분포
--- (1) 성별 구매자 분포
SELECT gender
	   ,COUNT(DISTINCT mem_no) AS tot_mem
  FROM #PROFILE_BASE
 GROUP
	BY gender 

--- (2) 연령대별 구매자 분포
SELECT ageband
	   ,COUNT(DISTINCT mem_no) AS tot_mem
  FROM #PROFILE_BASE
 GROUP
	BY ageband 

--- (3) 성별 및 연령대별 구매자 분포
SELECT gender
	   ,ageband
	   ,COUNT(DISTINCT mem_no) AS tot_mem
  FROM #PROFILE_BASE
 GROUP
	BY gender
	   ,ageband
 ORDER
    BY 1

-- 3) 성별, 연령대별, 연도별 구매자 분포

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



	
-- 3. RFM 고객세분화 분석(Recency 최근성, Frequency 구매빈도, Monetary 구매금액)

USE VITAMIN

-- 1) 고객별 RFM 세션 임시 테이블 생성

SELECT mem_no 
	   ,SUM(sales_amt) AS tot_amt --(Monetary 구매금액)
	   ,COUNT(order_no) AS tot_tr --(Frequency 구매빈도)
  INTO #RFM_BASE
  FROM [vitamin_MART]
 WHERE YEAR(order_date) BETWEEN 2021 AND 2022
 GROUP
	BY mem_no

SELECT *
  FROM #RFM_BASE

-- 2) 고객 세분화

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

 
-- 3) 고객 세분화별 고객 수 및 매출 비중 파악

SELECT segmentation
	   ,COUNT(mem_no) AS tot_mem
	   ,SUM(tot_amt) AS tot_amt

  FROM #RFM_BASE_SEG
 GROUP
	BY segmentation
 ORDER 
    BY 1


-- 4. 구매전환율 및 구매주기 분석

-- 1) 구매전환율 세션 임시 테이블 생성

USE VITAMIN

-- 2021구매자 중 2022 구매여부 열추가한 가테이블 생성
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

-- 2) 구매전환율 구하기
SELECT COUNT(pur_mem_2021) AS tot_mem
	   ,COUNT(CASE WHEN retention_yn = 'Y' THEN pur_mem_2021 END) AS retention_mem
  FROM #RETENTION_BASE


-- 3) 회원 거주 지역별 구매주기에 필요한 세션 임시 테이블 생성
SELECT addr_no
	   ,MIN(order_date) AS min_order_date
	   ,MAX(order_date) AS max_order_date
	   ,COUNT(DISTINCT order_no) -1 AS tot_tr_1
  INTO #CYCLE_BASE
  FROM [vitamin_MART]
 GROUP 
    BY addr_no
HAVING COUNT(DISTINCT order_no) >= 2  -- 구매횟수 2회 이상 필터링(구매횟수가 1회이면 분모가 0이 되기때문)

SELECT *
  FROM #CYCLE_BASE


-- 4) 회원거주 지역별 구매주기 구하기
SELECT *
	   ,DATEDIFF(DAY, min_order_date, max_order_date) AS diff_day
	   ,DATEDIFF(DAY, min_order_date, max_order_date)*1.00 /tot_tr_1 AS cycle
  FROM #CYCLE_BASE
 ORDER
	BY 6 DESC


-- 5. 제품 및 성장률 분석

-- 1) 브랜드 및 모델별 2021, 2022년 구매금액 세션 임시 테이블 생성

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

-- 2) 브랜드별 성장률 파악
SELECT brand
	   ,SUM(tot_amt_2022) / sum(tot_amt_2021) -1*1.00 AS growth
  FROM #PRODUCT_GROWTH_BASE
 GROUP
    BY brand
 ORDER
    BY 2 DESC

-- 3) 각 브랜드별 모델 성장률 순위
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


-- 4) 각 브랜드별 성장률 TOP2 모델만 필터링
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

