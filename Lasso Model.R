options(stringsAsFactors = FALSE)
install.packages("fastDummies")
install.packages("glmnet")
library(readr)
library(tidyverse)
library(lubridate)
library(fastDummies)
library(glmnet)
ds <- read_csv("../Downloads/avocado.csv")


# Switch the order of rows
ds <- ds %>% 
  group_by(type, region) %>% 
  select(X1, year, Date, type, region, everything()) %>% 
  arrange(Date)

# Change `X1` to `ID`
colName <- names(ds)
colName[1] <- "ID"
names(ds) <- colName

# Assign distinct number id to each observation in `ID` column
ds$ID <- seq(nrow(ds))
glimpse(ds)

# Add a `month` column
ds$month <- month(ds$Date)
ds <- ds %>% 
  select(ID, year, month, everything())

# Subset `type` column into `conventional` and `organic`
dsNew <- dummy_cols(ds, select_columns = "type") %>% 
  select(ID, year, month, region, type_conventional, type_organic, 
         everything(), -type)

# Other types
dsNew$other_PLU <- dsNew$`Total Volume` - dsNew$`4046` - dsNew$`4225` - dsNew$`4770`

dsNew <- dsNew %>% 
  select(1:3, Date, everything())

# Categorize `region` into US Areas
uniqueRegion <- unique(dsNew$region)
uniqueRegion <- as.data.frame(uniqueRegion)
uniqueRegion$Area <- NA
uniqueRegion$Area[1] <- "NewEngland"
uniqueRegion$Area[2] <- "Southeast"
uniqueRegion$Area[3] <- "Mideast"
uniqueRegion$Area[4] <- "RockyMountain"
uniqueRegion$Area[5] <- "NewEngland"
uniqueRegion$Area[6] <- "Mideast"
uniqueRegion$Area[7] <- "FarWest"
uniqueRegion$Area[8] <- "Southeast"
uniqueRegion$Area[9] <- "GreatLakes"
uniqueRegion$Area[10] <- "GrateLakes"
uniqueRegion$Area[11] <- "GrateLakes"
uniqueRegion$Area[12] <- "Southwest"
uniqueRegion$Area[13] <- "RockyMountain"
uniqueRegion$Area[14] <- "GrateLakes"
uniqueRegion$Area[15] <- "GrateLakes"
uniqueRegion$Area[16] <- "GrateLakes"
uniqueRegion$Area[17] <- "Mideast"
uniqueRegion$Area[18] <- "NewEngland"
uniqueRegion$Area[19] <- "Southeast"
uniqueRegion$Area[20] <- "GrateLakes"
uniqueRegion$Area[21] <- "Southeast"
uniqueRegion$Area[22] <- "FarWest"
uniqueRegion$Area[23] <- "FarWest"
uniqueRegion$Area[24] <- "Southeast"
uniqueRegion$Area[25] <- "Southeast"
uniqueRegion$Area[26] <- "Southeast"
uniqueRegion$Area[27] <- "Southeast"
uniqueRegion$Area[28] <- "Southeast"
uniqueRegion$Area[29] <- "Mideast"
uniqueRegion$Area[30] <- "NewEngland"
uniqueRegion$Area[31] <- "NewEngland"
uniqueRegion$Area[32] <- "Southeast"
uniqueRegion$Area[33] <- "Mideast"
uniqueRegion$Area[34] <- "Southwest"
uniqueRegion$Area[35] <- "Mideast"
uniqueRegion$Area[36] <- "Plains"
uniqueRegion$Area[37] <- "FarWest"
uniqueRegion$Area[38] <- "Southeast"
uniqueRegion$Area[39] <- "Southeast"
uniqueRegion$Area[40] <- "Southeast"
uniqueRegion$Area[41] <- "FarWest"
uniqueRegion$Area[42] <- "FarWest"
uniqueRegion$Area[43] <- "FarWest"
uniqueRegion$Area[44] <- "FarWest"
uniqueRegion$Area[45] <- "Southeast"
uniqueRegion$Area[46] <- "Southeast"
uniqueRegion$Area[47] <- "Southeast"
uniqueRegion$Area[48] <- "FarWest"
uniqueRegion$Area[49] <- "Plains"
uniqueRegion$Area[50] <- "Mideast"
uniqueRegion$Area[51] <- "Southeast"
uniqueRegion$Area[52] <- "TotalUS"
uniqueRegion$Area[53] <- "FarWest"
uniqueRegion$Area[54] <- "Southwest"
names(uniqueRegion)[1] <- "region"

avo <- dsNew %>% 
  left_join(uniqueRegion, by = "region") %>% 
  select(1:5, Area, everything())

View(avo)

avo <- dummy_cols(avo, select_columns = "Area")

View(avo)

##### Formatting Done #####


### Rename Column Names ##3
avoFormat <- avo
colnames(avoFormat)

names(avo)[10] <- "TotalVolume"
names(avo)[14] <- "TotalBags"
names(avo)[15] <- "SmallBags"
names(avo)[16] <- "LargeBags"
names(avo)[17] <- "XLargeBags"
names(avo)[11] <- "PLU4046"
names(avo)[12] <- "PLU4225"
names(avo)[13] <- "PLU4770"

colnames(avo)

### Split the dataset into train and test sets ###
set.seed(1234)
avo_train <- avo %>% filter(as.Date(Date) < "2017-03-01")
avo_train %>%
  filter(year == 2017, month == 2)
avo_test <- avo %>% filter(as.Date(Date) >= "2017-03-01")
avo_test %>%
  filter(year == 2018, month == 3)


###pre model
f1 <- as.formula(AveragePrice ~ type_conventional + type_organic + TotalVolume + 
                   PLU4046 + PLU4770 + PLU4225 + SmallBags + LargeBags + XLargeBags + 
                   + Area_NewEngland + Area_Southeast
                 + Area_Mideast + Area_RockyMountain
                 + Area_FarWest + Area_GreatLakes
                 + Area_GrateLakes + Area_Southwest
                 + Area_Plains + Area_TotalUS)

x1_train <- model.matrix(f1,avo_train)[,-1]
y1_train <- avo_train$AveragePrice
x1_test <- model.matrix(f1, avo_test)[,-1]
y1_test <- avo_test$AveragePrice
date_test <- avo_test$Date

## Run lasso
lmodel <- glmnet(x1_train, y1_train, alpha = 1, nlambda = 100)
lmodel$lambda

## Predict response
y1_train_hat <- predict(lmodel, s = lmodel$lambda, newx = x1_train)
y1_test_hat <- predict(lmodel, s = lmodel$lambda, newx = x1_test)
length(y1_test_hat)
mse_train = vector()
mse_test = vector()

for (i in 1:length(lmodel$lambda)) {
  mse_train[i] <- mean((y1_train - y1_train_hat)[,i]^2)
  mse_test[i] <- mean((y1_test - y1_test_hat)[,i]^2)
}
mse_train
mse_test

lambda_min_mse_train<- lmodel$lambda[which.min(mse_train)]
lambda_min_mse_test <-lmodel$lambda[which.min(mse_test)]
lambda_min_mse_train
lambda_min_mse_test


## plot min lambda to predict
y1_test_min_lambda_hat <- predict(lmodel, s = lambda_min_mse_test, newx = x1_test)
class(y1_test_min_lambda_hat)
## Aggregate all MSEs

dd_mse<-tibble(
  lambda=lmodel$lambda,
  mse=mse_train,
  dataset="Train"
)

dd_mse <-rbind(dd_mse, tibble(
  lambda=lmodel$lambda,
  mse=mse_test,
  dataset = "Test"
))

dd_mse

## check coef
coef(lmodel, s = lambda_min_mse_test)

## plot the y and y_hat

## Aggregate data into one dataframe
library(ggplot2)
p1<-avo_test %>% 
  select(Date, AveragePrice)
p2<-cbind(p1, y1_test_min_lambda_hat)
colnames(p2)

names(p2)[3]<-"AveragePrice_hat"

## Plot the actual average price and the predictive average price
head(p2)
class(p2$Date)
p2 %>% 
  group_by(Date) %>% 
  summarize(
    meanavg=mean(AveragePrice),
    meanavg_hat=mean(AveragePrice_hat)) %>%
  ggplot()+
  geom_line(aes(Date, meanavg),color = "blue")+
  geom_line(aes(Date, meanavg_hat), color = "red")+
  theme_classic()

