% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/multi.R
\name{predict_msln}
\alias{predict_msln}
\title{Predict for a multivariate segmented linear network model}
\usage{
predict_msln(one_model, newdata)
}
\arguments{
\item{one_model}{a model generated from msl_network}

\item{newdata}{new data to be predicted}
}
\value{
predicted value
}
\description{
Predict for a multivariate segmented linear network model
}
\examples{
temp = data_generator(1000,55,gen_type = 'chaos&cut')
y = temp[,2]
one_trial = temp[,-2]
cuts = list(c(-2,4,8,12,21),c(-10,3,16,30),c(0,33,67,100))
tp2_output = msl_network(x = one_trial, y = y, cuts = cuts,
    loss = L1, iter_ctrl = list(iter.max=4, trace = 1))
predict_msln(tp2_output,one_trial)[1:5]
}
