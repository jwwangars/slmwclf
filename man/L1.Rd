% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/loss_functions.R
\name{L1}
\alias{L1}
\title{Loss function of L(x) = abs(x), same as abs(x)}
\usage{
L1(x)
}
\arguments{
\item{x}{original error}
}
\value{
loss
}
\description{
Loss function of L(x) = abs(x), same as abs(x)
}
\examples{
plot(1:100,L1(1:100))
}
