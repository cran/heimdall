% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dfr_adwin.R
\name{dfr_adwin}
\alias{dfr_adwin}
\title{ADWIN method}
\usage{
dfr_adwin(target_feat = NULL, delta = 2e-05)
}
\arguments{
\item{target_feat}{Feature to be monitored.}

\item{delta}{The significance parameter for the ADWIN algorithm.}
}
\value{
\code{dfr_adwin} object
}
\description{
Adaptive Windowing method for concept drift detection \url{doi:10.1137/1.9781611972771.42}.
}
\examples{
#Use the same example of dfr_cumsum changing the constructor to:
#model <- dfr_adwin(target_feat='serie')
}
