##########################################################
###Post Process final predictions------------------------
#########################################################


library("lubridate")


time = 
  darkSky.N.Loads.Combined$time[which(darkSky.N.Loads.Combined$time == testSet$time[1]):nrow(darkSky.N.Loads.Combined)]

loads = darkSky.N.Loads.Combined$Loads[which(darkSky.N.Loads.Combined$time == testSet$time[1]):nrow(darkSky.N.Loads.Combined)]



df = data.frame("time" = time, "loads" = loads, "prediction.ensembling" = pred.ensembling.fs.ms)
pred.ensembling.df = df


x <- seq(
  as.Date(as.POSIXct(min(pred.ensembling.df$time), tz= "Europe/Athens"), tz= "Europe/Athens"), 
  as.Date(as.POSIXct(max(pred.ensembling.df$time), tz= "Europe/Athens"), tz= "Europe/Athens"),
  by="1 day")


OctoberToBeAdded = x[wday(x,label = TRUE) == "Sun" & day(x) >= 25 & month(x) == 10]
MarchToBeRemoved = x[wday(x,label = TRUE) == "Sun" & day(x) >= 25 & month(x) == 3]


for(i in 1:length(OctoberToBeAdded)) {
  
  remove = which(pred.ensembling.df$time == paste(MarchToBeRemoved[i], "04:00:00"))[2]
  
  pred.ensembling.df = pred.ensembling.df[-remove,]
}


addAfterIndexList = c()
addExtraLoadList = c()
for(i in 1:length(OctoberToBeAdded)) {
  
  
  temp = data.frame(matrix(NA, nrow=1, ncol=length(pred.ensembling.df)))
  colnames(temp)= colnames(pred.ensembling.df)
  temp$time = as.POSIXct(paste(OctoberToBeAdded[i], "03:00:00"))
  #temp$DATE[1] = MarchToBeAdded[i]
  #class(temp$DATE) = class(darkSky.N.Loads.Combined$DATE)
  
  
  addAfterIndex = which(as.character(pred.ensembling.df$time) == paste(OctoberToBeAdded[i], "03:00:00"))
  addAfterIndexList = c(addAfterIndexList, addAfterIndex)
  addExtraLoadList = c(addExtraLoadList, which(as.character(myLoads$time) == paste(OctoberToBeAdded[i], "03:00:00"))[2])
  
  
  pred.ensembling.df = rbind(
    pred.ensembling.df[1:addAfterIndex, ], 
    temp, 
    pred.ensembling.df[(addAfterIndex+1):nrow(pred.ensembling.df), ])
}

addAfterIndexList = addAfterIndexList + 1
for(i in 1:length(addAfterIndexList)) {
  
  pred.ensembling.df[addAfterIndexList[i], 3] =
    mean(c(pred.ensembling.df[(addAfterIndexList[i] + 1), 3],
           pred.ensembling.df[(addAfterIndexList[i] - 1), 3]))
  
  
  pred.ensembling.df[addAfterIndexList[i], 2] = myLoads[addExtraLoadList[i], 4]
}

pred.ensembling.df$ooem.predictions = ooem_predictions$ooem_predictions

mape.postprocessed = 100 * mean(abs((pred.ensembling.df$loads - pred.ensembling.df$prediction.ensembling)/pred.ensembling.df$loads))

mape.ooem = 100 * mean(abs((pred.ensembling.df$loads - pred.ensembling.df$ooem.predictions)/pred.ensembling.df$loads))


cat("mape postprocessed:", mape.postprocessed,"\n")
cat("mape mape.ooem:", mape.ooem,"\n")
cat("mape performance: ", round(100 * (mape.ooem - mape.postprocessed)/ mape.ooem, 3), "%", sep="")


rm(time, loads, df, x, OctoberToBeAdded, MarchToBeRemoved, temp, addAfterIndex, addAfterIndexList, addExtraLoadList, i, remove)