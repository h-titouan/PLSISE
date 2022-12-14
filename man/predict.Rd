% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/predict.R
\name{predict}
\alias{predict}
\title{Predict from PLSISE}
\usage{
predict(PLSDA, newdata, type = "class")
}
\arguments{
\item{PLSDA}{an object of class PLSDA : a fitted with PLS-DA
method (fit) model.}

\item{newdata}{A data frame in which to look for variables with
which to predict.}

\item{type}{type of prediction : "class" for predicted class,
"posterior" for probabilities or "value" for values of predictions#'}
}
\value{
Y predictions for newdata as required in type parameter
}
\description{
Predict class, probabilities or values of X data based on a fitted PLS-DA model
}
