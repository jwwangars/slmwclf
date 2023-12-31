% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/skeletons.R
\name{data_generator}
\alias{data_generator}
\title{Generate artificial dataset which applies to segmented linear models}
\usage{
data_generator(n = 1000, seed = NULL, gen_type = "normal")
}
\arguments{
\item{n}{sample size simulated}

\item{seed}{random seed}

\item{gen_type}{can be 'cut', 'chaos', 'cut&chaos' or 'chaos&cut' except for 'normal'. 'cut' means some effects will be shrinked; 'chaos' means random errors will be much more than normal}
}
\value{
a simulated dataset with [x,y,temperature,humidity]
}
\description{
Generate artificial dataset which applies to segmented linear models
}
\examples{
temp = data_generator(1000,55,gen_type = 'chaos&cut')
plot(temp)
}
