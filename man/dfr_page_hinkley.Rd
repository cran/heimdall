% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dfr_page_hinkley.R
\name{dfr_page_hinkley}
\alias{dfr_page_hinkley}
\title{Adapted Page Hinkley method}
\usage{
dfr_page_hinkley(
  target_feat = NULL,
  min_instances = 30,
  delta = 0.005,
  threshold = 50,
  alpha = 1 - 1e-04
)
}
\arguments{
\item{target_feat}{Feature to be monitored.}

\item{min_instances}{The minimum number of instances before detecting change}

\item{delta}{The delta factor for the Page Hinkley test}

\item{threshold}{The change detection threshold (lambda)}

\item{alpha}{The forgetting factor, used to weight the observed value and the mean}
}
\value{
\code{dfr_page_hinkley} object
}
\description{
Change-point detection method works by computing the observed values and their mean up to the current moment \url{doi:10.2307/2333009}.
}
\examples{
library(daltoolbox)
library(heimdall)

# This example assumes a model residual where 1 is an error and 0 is a correct prediction.

data(st_drift_examples)
data <- st_drift_examples$univariate
data$event <- NULL
data$prediction <- st_drift_examples$univariate$serie > 4


model <- dfr_page_hinkley(target_feat='serie')

detection <- c()
output <- list(obj=model, drift=FALSE)
for (i in 1:length(data$serie)){
 output <- update_state(output$obj, data$serie[i])
 if (output$drift){
   type <- 'drift'
   output$obj <- reset_state(output$obj)
 }else{
   type <- ''
 }
 detection <- rbind(detection, list(idx=i, event=output$drift, type=type))
}

detection <- as.data.frame(detection)
detection[detection$type == 'drift',]
}
