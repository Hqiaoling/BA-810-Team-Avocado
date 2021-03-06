options(stringsAsFactors = FALSE)

library(tidyverse)
library(lubridate)
library(fastDummies)
library(ggplot2)
library(ggthemes)
library(gbm)
theme_set(theme_clean())

ds <- read_csv("avocado.csv")  # LOAD THE ORIGINAL KAGGLE AVOCADO FILE
# glimpse(ds)

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
# glimpse(ds)

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
uniqueRegion$Area[10] <- "GreatLakes"
uniqueRegion$Area[11] <- "GreatLakes"
uniqueRegion$Area[12] <- "Southwest"
uniqueRegion$Area[13] <- "RockyMountain"
uniqueRegion$Area[14] <- "GreatLakes"
uniqueRegion$Area[15] <- "GreatLakes"
uniqueRegion$Area[16] <- "GreatLakes"
uniqueRegion$Area[17] <- "Mideast"
uniqueRegion$Area[18] <- "NewEngland"
uniqueRegion$Area[19] <- "Southeast"
uniqueRegion$Area[20] <- "GreatLakes"
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

# View(avo)

avo <- dummy_cols(avo, select_columns = "Area")

# View(avo)

##### Formatting Done #####


### Rename Column Names ##3
colnames(avo)

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
f1 <- as.formula(AveragePrice ~ month + type_conventional + type_organic + TotalVolume + 
                   PLU4046 + PLU4770 + PLU4225 + SmallBags + LargeBags + XLargeBags + 
                   + Area_NewEngland + Area_Southeast
                 + Area_Mideast + Area_RockyMountain
                 + Area_FarWest + Area_GreatLakes
                 + Area_Southwest
                 + Area_Plains + Area_TotalUS)
# 19 predictors

x1_train <- model.matrix(f1,avo_train)[,-1]
x1_test <- model.matrix(f1, avo_test)[, -1]

y1_train <- avo_train$AveragePrice
y1_test <- avo_test$AveragePrice

