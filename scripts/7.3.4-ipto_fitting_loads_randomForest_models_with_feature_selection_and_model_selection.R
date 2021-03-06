library("randomForest")
library("Boruta")


#start measuring time#####
startTime <- proc.time()[3]

#creating the train and test set splits#################
splitEvalSet = 365
splitTestSet = splitEvalSet + 365
len = dim(final.Data.Set)[1]

#creating the train and test set splits#################
splitEvalSet = 365
splitTestSet = splitEvalSet + 365
len = dim(final.Data.Set)[1]

#trainPart = floor(split * dim(final.Data.Set)[1])
trainSet = final.Data.Set[1:(len - splitTestSet), ]
evaluationSet = final.Data.Set[(len - splitTestSet + 1):(len - splitEvalSet), ]
train.and.evalSet = final.Data.Set[1:(len - splitEvalSet), ]
testSet = final.Data.Set[(len - splitEvalSet + 1):len, ]

####create the train, evaluation and test Set###################################

full.list.of.features = names(final.Data.Set)
full.list.of.features = full.list.of.features[-grep("^Loads|time|weekday|icon|^day.of.week$|^day.of.year$|yesterday.weather.measures.isQuietHour|yesterday.weather.measures.isHoliday|yesterday.weather.measures.isWeekend|yesterday.weather.measures.day.of.week|yesterday.weather.measures.sine.day.of.week|yesterday.weather.measures.cosine.day.of.week|yesterday.weather.measures.day.of.year|yesterday.weather.measures.cosine.day.of.year|yesterday.weather.measures.sine.day.of.year|temperature|windBearing.[0-9]+$", full.list.of.features)]


full.list.of.FeaturesVariables = final.Data.Set[full.list.of.features]


trainSet = trainSet[full.list.of.features]


evaluationSet = evaluationSet[full.list.of.features]


train.and.evalSet = train.and.evalSet[full.list.of.features]


testSet = testSet[full.list.of.features]

#create the lists which store the best parameters######################################

#if (!exists("best.randomForest.parameters.fs")) {

rm(experiments.randomForest.ms)

best.randomForest.parameters.fs = list()
best.randomForest.fit.fs = list()
best.randomForest.prediction.fs = list()
#}


for(i in 1:24) {
  
  assign(paste("min.mape.", i-1, sep=""), 1000000)
  
  list.of.features = getSelectedAttributes(final.boruta.list2[[i]], withTentative = F)
  
  
  #create the predictor variables from training
  FeaturesVariables = 
    trainSet[list.of.features]
  
  for (num.of.trees in seq(50, 210, 50)) {
    for(mtry.par in seq(1, max(floor(ncol(FeaturesVariables)/3), 1), 1)) {

      cat("\n\n tuning model: Load.", i-1, " with num.of.trees = ", num.of.trees, " mtry = ", mtry.par,"\n\n")
      
      
      #add the response variable in trainSet
      FeaturesVariables[paste("Loads", i-1, sep=".")] = 
        final.Data.Set[1:dim(trainSet)[1], paste("Loads", i-1, sep=".")]
      
      
      set.seed(123)
      assign(paste("fit.randomForest", i-1, sep="."), 
             randomForest(as.formula(paste("Loads.", i-1, "~.", sep="")), data = FeaturesVariables, ntree = num.of.trees, mtry = mtry.par))
      
      
      FeaturesVariables[paste("Loads", i-1, sep=".")] = NULL
      
      
      
      #create the predictor.df data.frame for predictions####
      FeaturesVariables = 
        trainSet[list.of.features]
      
      
      #create the predictor.df data.frame for predictions####
      predictor.df = data.frame()
      predictor.df = FeaturesVariables[0, ]
      predictor.df = rbind(predictor.df, evaluationSet[names(evaluationSet) %in% names(predictor.df)])
      
      
      evaluationSet[paste("Loads", i-1, sep=".")] = 
        final.Data.Set[(len - splitTestSet + 1):(len - splitEvalSet), paste("Loads", i-1, sep=".")]
      
      
      assign(paste("prediction.randomForest", i-1, sep="."), predict(get(paste("fit.randomForest",i-1,sep=".")), predictor.df))
      
      
      #calculate mape
      temp.mape = 100 * mean(unlist(abs((get("evaluationSet")[paste("Loads", i-1, sep=".")] - get(paste("prediction.randomForest", i-1, sep=".")))/get("evaluationSet")[paste("Loads", i-1, sep=".")])))
      cat("mape = ", temp.mape,"\n\n")
      
      
      temp.mae =  mean(unlist(abs((get("evaluationSet")[paste("Loads", i-1, sep=".")] - get(paste("prediction.randomForest", i-1, sep=".")))/get("evaluationSet")[paste("Loads", i-1, sep=".")])))
      
      
      temp.rmse = sqrt(mean(unlist(abs((get("evaluationSet")[paste("Loads", i-1, sep=".")] - get(paste("prediction.randomForest", i-1, sep=".")))/get("evaluationSet")[paste("Loads", i-1, sep=".")]))^2))
      
      
      temp.mse = mean(unlist(abs((get("evaluationSet")[paste("Loads", i-1, sep=".")] - get(paste("prediction.randomForest", i-1, sep=".")))/get("evaluationSet")[paste("Loads", i-1, sep=".")]))^2)
      
      
      assign(paste("mape.randomForest",i-1,sep="."), temp.mape)
      assign(paste("mae.randomForest",i-1,sep="."), temp.mae)
      assign(paste("rmse.randomForest",i-1,sep="."), temp.rmse)
      assign(paste("mse.randomForest",i-1,sep="."), temp.mse)
      
      
      if( get(paste("min.mape.", i-1, sep="")) > get(paste("mape.randomForest",i-1,sep=".")) ) {
        
        cat("\n\n ***New best paramenters for Load.", i-1, " model***\n")
        cat(get(paste("mape.randomForest",i-1,sep=".")),"\n")
        
        cat("new best num.of.trees: ", num.of.trees,"\n")
        cat("new best mtry: ", mtry.par,"\n")
        
        
        assign(paste("min.mape.", i-1, sep=""), get(paste("mape.randomForest",i-1,sep=".")))
        
        
        best.randomForest.parameters.fs[[paste("best.randomForest.param.", i-1, sep="")]] = c(num.of.trees, mtry.par, get(paste("mape.randomForest",i-1,sep=".")), get(paste("mae.randomForest",i-1,sep=".")), get(paste("rmse.randomForest",i-1,sep=".")), get(paste("mse.randomForest",i-1,sep=".")))
        names(best.randomForest.parameters.fs[[paste("best.randomForest.param.", i-1, sep="")]]) = list("num.of.trees", "mtry", paste("mape.randomForest",i-1,sep="."), paste("mae.randomForest",i-1,sep="."), paste("rmse.randomForest",i-1,sep="."), paste("mse.randomForest",i-1,sep="."))
        
        
        best.randomForest.fit.fs[[paste("fit.randomForest", i-1, sep=".")]] = get(paste("fit.randomForest",i-1, sep="."))
        
        best.randomForest.prediction.fs[[paste("prediction.randomForest",i-1,sep=".")]] = get(paste("prediction.randomForest",i-1, sep="."))
        
        
        
      }
      
      evaluationSet[paste("Loads", i-1, sep=".")] = NULL
      
      cat("elapsed time in minutes: ", (proc.time()[3]-startTime)/60,"\n")
      
      
      ###experiments####
      #saving each tuning experiments####
      if (!exists("experiments.randomForest.ms")) {
        
        experiments.randomForest.ms = data.frame("mape" = NA, "mae" = NA, "mse" = NA, "rmse" = NA, "features" = NA, "dataset" = NA, "num.of.trees" = NA, "mtry" = NA, "algorithm" = NA, "model" = NA, "date" = NA) 
        
        experiments.randomForest.ms$features = list(list.of.features)
        
        if(length(list.of.features) != length(full.list.of.features))
          experiments.randomForest.ms$dataset = "feature selection"
        else
          experiments.randomForest.ms$dataset = "full.list.of.features"
        
        experiments.randomForest.ms$mape = temp.mape
        experiments.randomForest.ms$mae = temp.mae
        experiments.randomForest.ms$mse = temp.mse
        experiments.randomForest.ms$rmse = temp.rmse
        
        experiments.randomForest.ms$num.of.trees = num.of.trees
        experiments.randomForest.ms$mtry = mtry.par
        
        experiments.randomForest.ms$algorithm = "randomForest"
        experiments.randomForest.ms$model = paste("Loads.", i-1, sep="")
        
        experiments.randomForest.ms$date = format(Sys.time(), "%d-%m-%y %H:%M:%S")
        
      } else {
        temp = data.frame("mape" = NA, "mae" = NA, "mse" = NA, "rmse" = NA, "features" = NA, "dataset" = NA, "num.of.trees" = NA, "mtry" = NA, "algorithm" = NA, "model" = NA, "date" = NA)
        
        temp$features = list(list.of.features)
        
        
        if(length(list.of.features) != length(full.list.of.features))
          temp$dataset = "feature selection"
        else
          temp$dataset = "full.list.of.features"
        
        
        temp$mape = temp.mape
        temp$mae = temp.mae
        temp$mse = temp.mse
        temp$rmse = temp.rmse
        
        temp$num.of.trees = num.of.trees
        temp$mtry = mtry.par
        
        temp$algorithm = "randomForest"
        temp$model = paste("Loads.", i-1, sep="")
        
        temp$date = format(Sys.time(), "%d-%m-%y %H:%M:%S")
        
        experiments.randomForest.ms = rbind(experiments.randomForest.ms, temp)
        rm(temp)
      }
      
      
    
    } 
  }
  
} #end of tuning####


#create the new models after tuning and evaluation phase##################
mape.randomForest.fs.ms = list()
mae.randomForest.fs.ms = list()
rmse.randomForest.fs.ms = list()
mse.randomForest.fs.ms = list()
prediction.randomForest.fs.ms = list()
fit.randomForest.fs.ms = list()


for(i in 1:24) {
  
  list.of.features =
    getSelectedAttributes(final.boruta.list2[[i]], withTentative = F)
  
  cat("\n\n training after evaluation model: Load.",i-1," with best num.of.trees = ", best.randomForest.parameters.fs[[paste("best.randomForest.param.", i-1, sep="")]][["num.of.trees"]]," mtry = ", best.randomForest.parameters.fs[[paste("best.randomForest.param.", i-1, sep="")]][["mtry"]], "\n", sep="")
  
  #create the predictor variables from training
  FeaturesVariables =
    train.and.evalSet[list.of.features]
  
  #add the response variable in trainSet
  FeaturesVariables[paste("Loads", i-1, sep=".")] = 
    final.Data.Set[1:dim(train.and.evalSet)[1], paste("Loads", i-1, sep=".")]
 
  
  set.seed(123)
  assign(paste("fit.randomForest", i-1, sep="."), 
         randomForest(as.formula(paste("Loads.", i-1, "~.", sep="")), data = FeaturesVariables, ntree = best.randomForest.parameters.fs[[paste("best.randomForest.param.", i-1, sep="")]][["num.of.trees"]], mtry = best.randomForest.parameters.fs[[paste("best.randomForest.param.", i-1, sep="")]][["mtry"]]))
  
  
  FeaturesVariables[paste("Loads", i-1, sep=".")] = NULL
  
  
  
  #make the prediction from train-eval set#########################
  FeaturesVariables =
    train.and.evalSet[list.of.features]
  
  
  predictor.df = data.frame()
  predictor.df = FeaturesVariables[0, ]
  predictor.df = rbind(predictor.df, testSet[names(testSet) %in% names(predictor.df)])
  
  
  testSet[paste("Loads", i-1, sep=".")] = 
    final.Data.Set[(len - splitEvalSet + 1):len, paste("Loads", i-1, sep=".")]
  
  
  assign(paste("prediction.randomForest", i-1, sep="."), predict(get(paste("fit.randomForest",i-1,sep=".")), predictor.df))
  
  
  #calculate mape
  temp.mape = 100 * mean(unlist(abs((get("testSet")[paste("Loads", i-1, sep=".")] - get(paste("prediction.randomForest", i-1, sep=".")))/get("testSet")[paste("Loads", i-1, sep=".")])))
  cat("mape.", i-1 ," = ", temp.mape,"\n\n", sep = "")
  
  
  temp.mae =  mean(unlist(abs((get("testSet")[paste("Loads", i-1, sep=".")] - get(paste("prediction.randomForest", i-1, sep=".")))/get("testSet")[paste("Loads", i-1, sep=".")])))
  
  
  temp.rmse = sqrt(mean(unlist(abs((get("testSet")[paste("Loads", i-1, sep=".")] - get(paste("prediction.randomForest", i-1, sep=".")))/get("testSet")[paste("Loads", i-1, sep=".")]))^2))
  
  
  temp.mse = mean(unlist(abs((get("testSet")[paste("Loads", i-1, sep=".")] - get(paste("prediction.randomForest", i-1, sep=".")))/get("testSet")[paste("Loads", i-1, sep=".")]))^2)
  
  
  fit.randomForest.fs.ms[[paste("fit.randomForest",i-1,sep=".")]] = get(paste("fit.randomForest",i-1, sep="."))
  
  prediction.randomForest.fs.ms[[paste("prediction.randomForest",i-1,sep=".")]] = get(paste("prediction.randomForest",i-1, sep="."))
  
  mape.randomForest.fs.ms[[paste("mape.randomForest",i-1,sep=".")]] = temp.mape
  mae.randomForest.fs.ms[[paste("mae.randomForest",i-1,sep=".")]] = temp.mae
  mse.randomForest.fs.ms[[paste("mse.randomForest",i-1,sep=".")]] = temp.mse
  rmse.randomForest.fs.ms[[paste("rmse.randomForest",i-1,sep=".")]] = temp.rmse  
  
  
  testSet[paste("Loads", i-1, sep=".")] = NULL
  
} #end of models


#calculate the mean mape####
cat("calculate the mean mape\n")
mean.mape.randomForest.fs.ms = mean(unlist(mape.randomForest.fs.ms))

cat("calculate the mean mae\n")
mean.mae.randomForest.fs.ms = mean(unlist(mae.randomForest.fs.ms))

cat("calculate the mean mse\n")
mean.mse.randomForest.fs.ms = mean(unlist(mse.randomForest.fs.ms))

cat("calculate the mean rmse\n")
mean.rmse.randomForest.fs.ms = mean(unlist(rmse.randomForest.fs.ms))


cat("mean randomForest mape: ", round(mean.mape.randomForest.fs.ms,3), "\n")
cat("mean randomForest mae: ", round(mean.mae.randomForest.fs.ms,5), "\n")
cat("mean randomForest mse: ", round(mean.mse.randomForest.fs.ms,5), "\n")
cat("mean randomForest rmse: ", round(mean.rmse.randomForest.fs.ms,5), "\n")


cat("elapsed time in minutes: ", (proc.time()[3]-startTime)/60,"\n")



rm(list=ls(pattern="fit.randomForest.[0-9]"))
rm(list=ls(pattern="prediction.randomForest.[0-9]"))
rm(list=ls(pattern="mape.randomForest.[0-9]"))
rm(list=ls(pattern="mae.randomForest.[0-9]"))
rm(list=ls(pattern="mse.randomForest.[0-9]"))
rm(list=ls(pattern="rmse.randomForest.[0-9]"))
rm(list=ls(pattern="min.mape."))
rm(list=ls(pattern="temp."))
rm(num.of.trees)
rm(mtry.par)
rm(i)
