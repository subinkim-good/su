install.packages('tidyverse')
library(tidyverse)
update.packages()
install.packages('installr')
library(installr)
updateR()

# 데이터 가져오기 및 탐색용 패키지
install.packages('tidyverse')
library(tidyverse) 

# 엑셀 파일 읽기용 패키지
library(readxl)

# 기술통계용 패키지
library(psych)

# 엑셀에 데이터 쓰기용 패키지
library(writexl)


library(tidymodels)

setwd("C:/Users/master/노동패널")
getwd()

read.csv('labor_220726.csv')
labor <- read.csv('labor_220726.csv')
labor
view(labor)
glimpse(labor)
summary(labor)
describe(labor)


# 결측치 제거
labor_clean <- na.omit(labor)


# 교육수준별로 그룹화
labor_grouped <- group_by(labor, p_edu)

# 교육수준별 평균 임금 (결측치 제거)
summarize(labor_grouped, avg_p_wage = mean(p_wage, na.rm= TRUE)) 

# 교육수준별 평균 근로시간 (결측치 제거)
summarize(labor_grouped, avg_p_hours = mean(p_hours, na.rm= TRUE))

# 1. 교육수준별 평균 임금 및 평균 근로시간
labor %>%
  group_by(p_edu) %>%
  summarize(avg_p_wage = mean(p_wage, na.rm= TRUE),avg_p_hours = mean(p_hours, na.rm= TRUE)) %>%
  arrange(p_edu)

# 2. 성별 평균 임금 및 평균 근로시간
labor %>%
  group_by(p_sex) %>%
  summarize(avg_p_wage = mean(p_wage, na.rm= TRUE),avg_p_hours = mean(p_hours, na.rm= TRUE)) %>%
  arrange(p_sex)

# 3. 지역별 평균 임금 및 평균 근로시간
labor %>%
  group_by(p_region) %>%
  summarize(avg_p_wage = mean(p_wage, na.rm= TRUE),avg_p_hours = mean(p_hours, na.rm= TRUE)) %>%
  arrange(p_region)


# 시각화

ggplot(data = labor, aes(x=p_edu)) +
  geom_bar()

ggplot(data = labor, aes(x=p_edu)) +
  geom_histogram()

ggplot(data = labor, aes(x=p_edu, y=p_hours)) +
  geom_boxplot()

ggplot(data = labor, aes(x=p_edu, y=p_wage)) +
  geom_boxplot()


ggplot(data = labor, aes(x=p_hours, y=p_wage)) +
  geom_point()

ggplot(data = labor, aes(x=p_wage, y=p_hours)) +
  geom_point()

# 일원도수분포표
labor %>%
  count(p_region)

labor %>%
  select(labor, p_region) %>%
  describeBy(group = 'p_region')

