#'@title Adapted Hoeffding Drift Detection Method (HDDM) method
#'@description  is a drift detection method based on the Hoeffding’s inequality. HDDM_A uses the average as estimator.  <doi:10.1109/TKDE.2014.2345382>.
#'@param drift_confidence Confidence to the drift
#'@param warning_confidence Confidence to the warning
#'@param two_side_option Option to monitor error increments and decrements (two-sided) or only increments (one-sided)
#HDDM: Frías-Blanco I, del Campo-Ávila J, Ramos-Jimenez G, et al. Online and non-parametric drift detection methods based on Hoeffding’s bounds. IEEE Transactions on Knowledge and Data Engineering, 2014, 27(3): 810-823.
#HDDM implementation: Scikit-Multiflow, https://github.com/scikit-multiflow/scikit-multiflow/blob/a7e316d/src/skmultiflow/drift_detection/hddm_a.py#L6
#'@return `dfr_hddm` object
#'@examples
#'library(daltoolbox)
#'library(heimdall)
#'
#'# This example uses an error-based drift detector with a synthetic a 
#'# model residual where 1 is an error and 0 is a correct prediction.
#'
#'data(st_drift_examples)
#'data <- st_drift_examples$univariate
#'data$event <- NULL
#'data$prediction <- st_drift_examples$univariate$serie > 4
#'
#'model <- dfr_hddm()
#'
#'detection <- NULL
#'output <- list(obj=model, drift=FALSE)
#'for (i in 1:length(data$prediction)){
#'  output <- update_state(output$obj, data$prediction[i])
#'  if (output$drift){
#'    type <- 'drift'
#'    output$obj <- reset_state(output$obj)
#'  }else{
#'    type <- ''
#'  }
#'  detection <- rbind(detection, data.frame(idx=i, event=output$drift, type=type))
#'}
#'
#'detection[detection$type == 'drift',]
#'@export
dfr_hddm <- function(drift_confidence=0.001, warning_confidence=0.005, two_side_option=TRUE) {
  obj <- error_based()
  
  # State
  state <- list()
  state$n_min <- 0
  state$c_min <- 0
  state$total_n <- 0
  state$total_c <- 0
  state$n_max <- 0
  state$c_max <- 0
  state$n_estimation <- 0
  state$c_estimation <- 0
  
  state$drift_confidence <- drift_confidence
  state$warning_confidence <- warning_confidence
  state$two_side_option <- two_side_option
  
  obj$state <- state
  
  obj$drifted <- FALSE
  
  # Methods
  obj$mean_incr <- function(c_min, n_min, total_c, total_n, confidence){
    if (n_min == total_n){
      return(FALSE)
    }
    m <- ((total_n - n_min) / n_min) * (1.0 / total_n)
    cota <- sqrt(m / (2 * log(2.0 / confidence)))
    return(((total_c / total_n) - (c_min / n_min)) >= cota)
  }
  
  obj$mean_decr <- function(c_max, n_max, total_c, total_n){
    if (n_max == total_n){
      return(FALSE)
    }
    m <- ((total_n - n_max) / n_max) * (1.0 / total_n)
    cota <- sqrt(m / (2 * log(2.0 / state$drift_confidence)))
    return(((c_max / n_max) - (total_c / total_n)) >= cota)
  }
  
  obj$update_estimations <- function(obj){
    state <- obj$state
    if(state$total_n >= state$n_estimation){
      state$c_estimation <- 0
      state$n_estimation <- 0
      
      state$estimation <- state$total_c / state$total_n
      state$delay <- state$total_n
    }
    obj$state <- state
    return(obj)
  }
  
  class(obj) <- append("dfr_hddm", class(obj))
  return(obj)
}

#'@export
update_state.dfr_hddm <- function(obj, value){
  state <- obj$state
  
  state$total_n <- state$total_n + 1
  state$total_c <- state$total_c + value
  if(state$n_min == 0){
    state$n_min = state$total_n
    state$c_min = state$total_c
  }
  if(state$n_max == 0){
    state$n_max = state$total_n
    state$c_max = state$total_c
  }
  
  cota <- sqrt(1.0 / (2 * state$n_min) * log(1.0 / state$drift_confidence))
  cota1 <- sqrt(1.0 / (2 * state$total_n) * log(1.0 / state$drift_confidence))
  
  if((state$c_min / (state$n_min + cota)) >= (state$total_c / (state$total_n + cota1))){
    state$c_min <- state$total_c
    state$n_min <- state$total_n
  }
  
  cota <- sqrt(1.0 / (2 * state$n_max) * log(1.0 / state$drift_confidence))
  if(state$c_max / state$n_max - cota <= state$total_c / state$total_n - cota1){
    state$c_max = state$total_c
    state$n_max = state$total_n
  }
  
  if(obj$mean_incr(state$c_min, state$n_min, state$total_c, state$total_n, state$drift_confidence)){
    state$.n_estimation = state$total_n - state$n_min
    state$c_estimation = state$total_c - state$c_min
    state$n_min = state$n_max = state$total_n = 0
    state$c_min = state$c_max = state$total_c = 0
    state$in_warning_zone <- FALSE
    
    obj$drifted <- TRUE
    
  }else if(obj$mean_incr(state$c_min, state$n_min, state$total_c, state$total_n, state$warning_confidence)){
    state$in_warning_zone <- TRUE
  }else{
    state$in_warning_zone <- TRUE
  }
  if(state$two_side_option & obj$mean_decr(state$c_max, state$n_max, state$total_c, state$total_n)){
    state$n_estimation = state$total_n - state$n_max
    state$c_estimation = state$total_c - state$c_max
    state$n_min = state$n_max = state$total_n = 0
    state$c_min = state$c_max = state$total_c = 0
  }
  
  obj <- obj$update_estimations(obj)

  obj$state <- state
  
  return(list(obj=obj, drift=obj$drifted))
}

#'@export
fit.dfr_hddm <- function(obj, data, ...){
  output <- update_state(obj, data[1])
  for (i in 2:length(data)){
    output <- update_state(output$obj, data[i])
  }
  
  return(output$obj)
}

#'@export
reset_state.dfr_hddm <- function(obj) {
  obj$drifted <- FALSE
  obj$state <- dfr_hddm(
    drift_confidence = obj$state$drift_confidence,
    warning_confidence = obj$state$warning_confidence,
    two_side_option = obj$state$two_side_option
  )$state
  return(obj)  
}