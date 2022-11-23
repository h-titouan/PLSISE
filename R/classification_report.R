classification_report <- function(y, ypred){
  
  #Check y and ypred shape
  if(!is.factor(y) |  !is.factor(ypred)){stop("Error : y, ypred or both are not a factor")}
  if(all(levels(y) != levels(ypred))){stop("Error : y and ypred have not the same modalities")}
  
  confusionTable <- table(y, ypred)
  precisionVector <- c()
  recallVector <- c()
  fscoreVector <- c()
  for(i in 1:nrow(confusionTable)){
    precision <- confusionTable[i, i] / sum(confusionTable[, i])
    riccol <- confusionTable[i, i] / sum(confusionTable[i,])
    fscore <- (2 * precision * riccol) / (precision + riccol)
    precisionVector <- append(precisionVector, precision)
    recallVector <- append(recallVector, riccol)
    fscoreVector <- append(fscoreVector, fscore)
  }
  Yweights <- table(y) / length(y)
  globalFscore <- sum(fscoreVector * Yweights, na.rm=T)
  classificationReport <- list("confusionTable" = confusionTable,
                               "Precision" = precisionVector,
                               "Recall" = recallVector,
                               "Fscore" = fscoreVector,
                               "GlobalFscore" = globalFscore)
  return(classificationReport)
}