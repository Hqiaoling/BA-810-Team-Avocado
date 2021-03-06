library(randomForest)

set.seed (1)
bag.avo =randomForest(f1, data = avo_train, 
                           mtry = 19, importance =TRUE)
bag.avo

yhat.bag = predict (bag.avo, newdata = avo_test)
plot(yhat.bag, avo_test$AveragePrice, main = "Scatter Plot for Bagging",
     xlab = "Prediction price in test set", ylab = "Average price in test set", 
     col = "#bdcc64")
abline (0,1)

mse_bag_test <- mean((yhat.bag - avo_test$AveragePrice)^2)
mse_bag_test
# 0.1350875
