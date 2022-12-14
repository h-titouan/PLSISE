#' Fit from PLSISE
#'
#' @description Fit the PLS-DA Classification to data, it can be used to carry
#'  classification on a target variable with 2 or more modalities
#'
#' @param formula an object of class "formula", symbolic description of the
#'   model to be fitted.
#'
#' @param data a data frame containing the variables in the model.
#'   
#' @param ncomp an integer: the number of components to keep in the model.
#'
#' @returns an object of class PLSDA with the fitted model and it Attributes.
#'
#' @export
#'
fit <- function(formula, data, ncomp = 2){
  
  #Check formula
  if(!inherits(formula,"formula")){stop("Error : formula specified is not a formula object")}
  
  #Check data
  if(!is.data.frame(data)){stop("Error : data specified is not a dataframe object")}
  
  #Check ncomp
  if(length(ncomp) != 1){stop("Error : ncomp specified is not an integer")}
  if(!is.numeric(ncomp)){stop("Error : ncomp specified is not an integer")}
  if(as.integer(ncomp) != ncomp){stop("Error : ncomp specified is not an integer")}

  #Get y and X names of columns
  yname <- toString(formula[[2]])
  Xnames <- attributes(terms(formula, data=data))$term.labels
  
  #Check var names
  if(!yname%in%colnames(data)){stop("Error : Y variable of specified formula is not in data")}
  if(!all(Xnames%in%colnames(data))){stop("Error : one (or more) X variable of specified formula is not in data")}
  
  #Check ncomp vs nXcol
  if(ncomp > length(Xnames)){stop("Error : ncomp must be lesser than number of X variables")}

  #Get y and X data
  y <- data[, yname]
  X <- data.frame(data[, Xnames])
  
  #Check X vars
  if(!all(sapply(X, is.numeric))){stop("Error : one (or more) X variable is not numeric")}
  
  #Check y var
  if(!is.factor(y)){stop("Error : Y variable is not factor")}

  #Observation descriptor
  n <- nrow(X)
  p <- ncol(X)
  q <- nlevels(y)

  #Transform y to dummies
  y <- get_dummies(y)

  #Get mean, sd and center scale data
  x.cs <- center_scale(X)
  Xk <- as.matrix(x.cs$Xk)
  X_mean <- x.cs$mean
  X_sd <- x.cs$sd

  y.cs <- center_scale(y)
  yk <- as.matrix(y.cs$Xk)
  y_mean <- y.cs$mean
  y_sd <- y.cs$sd
  
  #Name of component
  comp <- paste0("Comp.", 1:ncomp)

  #Initialisation
  U <- matrix(0, p, ncomp)#Weights of X
  V <- matrix(0, q, ncomp)#Weights of y
  Xi <- matrix(0, n, ncomp)#Scores of X
  Om <- matrix(0, n, ncomp)#Scores of y
  Ga <- matrix(0, p, ncomp)#Loadings of X
  De <- matrix(0, q, ncomp)#Loadings of y

  Sy <- matrix(y[,1])

  for(k in 1:ncomp){

    Wx_old <- 100

    for(i in 1:500){

      n_iter <- i

      Wx <- t(Xk) %*% Sy / sum(Sy^2)
      Wx <- Wx / sqrt(sum(Wx^2))
      Sx <- Xk %*% Wx
      Wy <- t(yk) %*% Sx / sum(Sx^2)
      Sy <- yk %*% Wy / sum(Wy^2)
      Wx_diff <- Wx - Wx_old

      if(sum(Wx_diff^2) < 1e-10 | q == 1){break}
      Wx_old <- Wx
    }

    if(n_iter == 500){print("Max number of iteration reached")}

    Sx <- Xk %*% Wx
    Sy <- yk %*% Wy / sum(Wy^2)
    Lx <- t(Xk) %*% Sx / sum(Sx^2)
    Xk <- Xk - Sx %*% t(Lx)
    Ly <- t(yk) %*% Sx / sum(Sx^2)
    yk <- yk - Sx %*% t(Ly)

    #Save values for conponent k
    U[,k] <- Wx
    V[,k] <- Wy
    Xi[,k] <- Sx
    Om[,k] <- Sy
    Ga[,k] <- Lx
    De[,k] <- Ly
  }

  A <- (t(Ga) %*% U)
  RotatX <- U %*% (solve(t(A) %*% A) %*% t(A))

  coef <- RotatX %*% t(De)
  coef <- coef * y_sd
  intercept <- y_mean
  
  #Tables names
  rownames(U) <- colnames(X)
  colnames(U) <- comp
  rownames(V) <- colnames(y)
  colnames(V) <- comp
  colnames(Xi) <- comp
  colnames(Om) <- comp
  rownames(Ga) <- colnames(X)
  colnames(Ga) <- comp
  rownames(De) <- colnames(y)
  colnames(De) <- comp
  rownames(coef) <- colnames(X)
  colnames(coef) <- colnames(y)
    
  #class S3 PLSA
  instance <- list("X" = X,
                   "y" = y,
                   "intercept" = intercept,
                   "ScoresX" = Xi,
                   "ScoresY" = Om,
                   "WeightsX" = U,
                   "WeightsY" = V,
                   "LoadingsX" = Ga,
                   "LoadingsY" = De,
                   "N_iter" = n_iter,
                   "coef" = coef,
                   "ynames" = colnames(y),
                   "Xnames" = Xnames,
                   "N_comp" = ncomp,
                   "Comps" = comp
                   )
  class(instance) <- "PLSDA"

  return(instance)
}

#' print.PLSDA from PLSISE
#'
#' @description
#' Print PLSDA object
#'
#' @param PLSDA a PLSDA object to print
#'
#' @export
#'
print.PLSDA <- function(PLSDA){
  #classification table
  classification <- rbind(PLSDA$intercept, PLSDA$coef)
  
  LoadingsY <- PLSDA$LoadingsY
  
  #Print
  cat("Coefficients : \n")
  print(classification)
  cat("\nLoadings Y : \n")
  print(LoadingsY)
}

#' summary.PLSDA from PLSISE
#'
#' @description
#' Summary of PLSDA object
#'
#' @param PLSDA a PLSDA object to print summary
#'
#' @export
#'
summary.PLSDA <- function(PLSDA){
  #classification table
  classification <- rbind(PLSDA$intercept, PLSDA$coef)
  Y <- as.factor(colnames(PLSDA$y)[apply(PLSDA$y, 1, which.max)])
  Ypred <- predict(PLSDA, PLSDA$X)
  classReport <- classification_report(Y, Ypred)
  cat("Coefficients : \n")
  print(classification)
  cat("\nConfusion table : \n")
  print(classReport$ConfusionTable)
  cat("\nF1 Score : \n")
  print(classReport$GlobalFscore)
}
