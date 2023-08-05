#' Generate artificial dataset which applies to segmented linear models
#'
#' @param n sample size simulated
#' @param seed random seed
#' @param gen_type can be 'cut', 'chaos', 'cut&chaos' or 'chaos&cut' except for 'normal'. 'cut' means some effects will be shrinked; 'chaos' means random errors will be much more than normal
#'
#' @return a simulated dataset with [x,y,temperature,humidity]
#' @export
#'
#' @examples
#' temp = data_generator(1000,55,gen_type = 'chaos&cut')
#' plot(temp)
data_generator = function(n = 1000, seed = NULL, gen_type = 'normal'){
  if(!is.null(seed)){
    set.seed(seed)
  }
  p_constrained = 0
  ori_sigma = 20
  if(gen_type == 'cut' | gen_type == 'cut&chaos' | gen_type == 'chaos&cut'){
    p_constrained = runif(1)/2.5
  }
  if(gen_type == 'chaos' | gen_type == 'cut&chaos' | gen_type == 'chaos&cut'){
    ori_sigma = 200
  }
  x = runif(n) * 20
  y_hat = 1000/(1+exp(-4*(x/8*x/8-1)))
  temperature = runif(n)*40 - 10
  humidity = runif(n)*100
  y = y_hat - 5*temperature + humidity + runif(n)*ori_sigma + rnorm(n,sd = ori_sigma)
  cutout = as.logical(rbinom(n,1,p_constrained))

  y[cutout] = y[cutout] * runif(sum(cutout))
  y[y<0] = y[y<0] * 0.01

  return(cbind(x,y,temperature,humidity))
}

#' Cleanse dataset of low_effect samples
#'
#' @param x data x of independent variable
#' @param y data y of effects to be sieved
#' @param coeffs a vector of length 3: compared quantile, limited percentage error, limited direct error
#' @param gap_percentage number of neighbors to be selected
#' @param if_plot whether or not to draw a plot
#'
#' @return cleansed dataset
#' @export
#'
#' @examples
#' temp = data_generator(1000,55,gen_type = 'chaos&cut')
#' temp1 = data_sieve(temp[,1],temp[,2],c(0.7,0.85,500))
data_sieve = function(x, y, coeffs = c(0.7, 0.9, 750),
                      gap_percentage = 0.01, if_plot = TRUE){

  order_x = order(x,decreasing = FALSE)
  n_data = length(x)
  x_gap = ceiling(n_data*gap_percentage)

  #half region of max and min are kept in output
  out_x = x[order_x[1:x_gap]]
  out_y = y[order_x[1:x_gap]]
  out_indicator = order_x[1:x_gap] # who are in the output

  for(i in (x_gap+1):(n_data-x_gap-1)){
    #from low to high, judge if consider as output
    cmp_y = y[order_x[(i-x_gap):(i+x_gap)]]
    cmp_threshold = as.numeric(quantile(cmp_y, probs = coeffs[1]))
    #consider the limited percentage error and limited direct error, substract this
    cmp_threshold = cmp_threshold*coeffs[2] - coeffs[3]

    if(y[order_x[i]] > cmp_threshold){
      out_x = c(out_x, x[order_x[i]])
      out_y = c(out_y, y[order_x[i]])
      out_indicator = c(out_indicator, order_x[i])
    }
  }
  out_x = c(out_x, x[order_x[(n_data-x_gap+1):n_data]])
  out_y = c(out_y, y[order_x[(n_data-x_gap+1):n_data]])
  out_indicator = c(out_indicator, order_x[(n_data-x_gap+1):n_data])

  if(if_plot){
    plot(x, y, pch='*')
    points(out_x, out_y, pch='*', col='red')
  }

  return(list(x = out_x, y = out_y, indicator = out_indicator))
}


#' Segmented linear model main construct function (one variable)
#'
#' @param x Independent variable. For multi-input, the first column is main variable to be segmented
#' @param y Dependent variable
#' @param fixed_psi Segment location(cuts)
#' @param loss_function What loss function to use. L2 in default
#' @param params The parameters in loss function. For L2 loss, NULL in default
#' @param init_val Vector of length(fixed_psi)+2. Default: c(rep(mean(y),length(fixed_psi)),0,0). For the corresponding y_hat at each fixed_psi, and initial & final tangent value
#'
#' @return a list with segmented location, corresponding y_hat, tangents and total loss
#' @export
#'
#' @examples
#' temp = data_generator(1000,55,gen_type = 'chaos&cut')
#' one_model = SLM_construct(temp[,1],temp[,2],fixed_psi = c(2,6,8,10))#single input
#' one_model$x
#' one_model$y
#' AIC(SLM_construct(temp[,c(1,3,4)],temp[,2],fixed_psi = c(2,6,8,10)))#multi input
SLM_construct = function(x, y, fixed_psi,
                         loss_function = L2, params = NULL, init_val = NULL){
  n_fixed_psi = length(fixed_psi)
  x_copy = x
  if(is.null(init_val)){
    init_val = rep(mean(y),n_fixed_psi)
    init_val = c(init_val,0,0)
  }

  multi_input = FALSE
  minor_fit = NULL
  x_others = NULL
  if(dim(as.data.frame(x))[2] > 1){#multi input
    multi_input = TRUE
    x = as.data.frame(x)
    x_others = cbind(y,x)#for minor_fit
    x = x[,1]

    # construct formula in the second stage
    indep_var = dimnames(x_others)[[2]][-2]
    secondary_formula = paste(indep_var[-1],collapse = '+')
    secondary_formula = as.formula(paste(indep_var[1],secondary_formula,sep='~'))
  }

  output = nlminb(init_val,sum_loss, x=x,y=y,
         cuts=fixed_psi,loss=loss_function, params = params)

  if(output$convergence){
    warning('warning: nlminb not converge')
  }

  temp_outcome = list(x = fixed_psi,
                      y = output$par[1:n_fixed_psi],
                      init_tangent = output$par[n_fixed_psi+1],
                      final_tangent = output$par[n_fixed_psi+2],
                      minor_fit = NULL,
                      mainloss = output$objective)

  if(multi_input){
    x_others[,1] = x_others[,1] - predict_model(temp_outcome, newdata = x)
    minor_fit = lm(secondary_formula, data = x_others)
  }

  temp_outcome = list(x = fixed_psi,
                      y = output$par[1:n_fixed_psi],
                      init_tangent = output$par[n_fixed_psi+1],
                      final_tangent = output$par[n_fixed_psi+2],
                      minor_fit = minor_fit,
                      mainloss = output$objective)

  #for compatibility of information criterion method e.g. AIC()
  y_hat = predict_model(temp_outcome, newdata = x_copy)
  n_rank = n_fixed_psi + 2
  if(multi_input){
    n_rank = n_rank + minor_fit$rank
  }
  output = list(x = fixed_psi,
                y = output$par[1:n_fixed_psi],
                init_tangent = output$par[n_fixed_psi+1],
                final_tangent = output$par[n_fixed_psi+2],
                minor_fit = minor_fit,
                mainloss = output$objective,
                residuals = as.numeric(y-y_hat),
                rank = n_rank)
  attributes(output)$class = 'lm'

  return(output)
}


#' Predict with SLM model generated by function 'SLM_construct'
#'
#' @param one_model SLM model generated by function 'SLM_construct'
#' @param newdata new independent variable to be predicted
#'
#' @return predicted values
#' @export
#'
#' @examples
#' temp = data_generator(1000,55,gen_type = 'chaos&cut')
#' model_1 = SLM_construct(temp[,1],temp[,2],fixed_psi = c(2,6,8,10))
#' predict_model(model_1, c(0,1,10,100,0.5,-1333))
#' model_2 = SLM_construct(temp[,c(1,3,4)],temp[,2],fixed_psi = c(2,6,8,10))
#' predict_model(model_2, newdata = temp[1:5,])
predict_model = function(one_model, newdata){
  n_psi = length(one_model$x)

  x_min = min(newdata) - 1
  x_max = max(newdata) + 1
  y_min = one_model$y[1] + one_model$init_tangent*(x_min-one_model$x[1])
  y_max = one_model$y[n_psi] + one_model$final_tangent*(x_max-one_model$x[n_psi])

  x = c(x_min,one_model$x,x_max)
  y = c(y_min,one_model$y,y_max)

  if(is.null(one_model$minor_fit)){# not multi input
    effect = approx(x,y,xout = newdata)$y
  }
  else{
    main_effect = approx(x,y,xout = newdata[,1])$y
    newdata = as.data.frame(newdata)
    minor_effect = predict.lm(one_model$minor_fit, newdata = newdata)
    effect = main_effect + minor_effect
  }


  return(effect)
}




#' Draw main predict lines in EXISTING plot with model generated by function 'SLM_construct'
#'
#' @param one_model the model generated by function 'SLM_construct'
#' @param model_col color of line for the drawing
#' @param x_beg lowest x value for drawing, default -100
#' @param x_end largest x value for drawing, default 100
#'
#' @return 0
#' @export
#'
#' @examples
#' temp = data_generator(1000,55,gen_type = 'chaos&cut')
#' model_1 = SLM_construct(temp[,1],temp[,2],fixed_psi = c(2,6,8,10))
#' dev.off()
#' draw_lines_model(model_1,'red')
#' plot(temp[,1],temp[,2])
#' draw_lines_model(model_1,'red')
draw_lines_model = function(one_model, model_col = 'blue',
                            x_beg = -100, x_end = 100){
  x = c(x_beg, one_model$x, x_end)
  one_model$minor_fit = NULL # only draw the main line
  y = predict_model(one_model, c(x_beg,x_end))
  y = c(y[1], one_model$y, y[2])
  err = tryCatch({lines(x,y,col = model_col)},error = function(e){(e)})
  if(typeof(err) == 'list'){
    if(err[[1]] == 'plot.new has not been called yet'){
      message('Draw new line failed. Note that this function adds a new line under an EXISTING plot.')
    }
  }
}






#' Calculate aggregated loss with input loss function
#'
#' @param deltas modeling with segmented line by points of (cuts[i], deltas[i]), plus initial and final tangents
#' @param x independent variable
#' @param y dependent variable
#' @param cuts modeling with segmented line by points of (cuts[i], deltas[i])
#' @param loss loss function
#' @param params Other parameters in loss function. Use 'NULL' if only one input.
#'
#' @return Summation of losses for all samples
#' @export
#'
#' @examples
#' temp = data_generator(1000,55,gen_type = 'chaos&cut')
#' sum_loss(c(10,200,350,0,0),temp[,1],temp[,2],c(5,10,15),sim_sigmoid_soft, c(3,100))
#' nlminb(c(10,200,350,0,0),sum_loss, x=temp[,1],y=temp[,2], cuts=c(5,10,15),params=c(5,100),loss=sim_sigmoid_soft)
sum_loss = function(deltas, x, y, cuts, loss, params = NULL){
  if(is.null(params)){
    loss_func = function(x, temp = NULL){
      # add a blank parameter from original one-input loss function
      return(loss(x))
    }
  }
  else{
    loss_func = loss
  }

  # calculate with linear function $y = y0 + k(x-x0)$ as y_hat
  n_delta = length(deltas) - 2
  term_1 = I(x < cuts[1]) *
    loss_func(y - deltas[1] - deltas[n_delta+1]*(x-cuts[1]),params)
  term_1 = sum(term_1)

  for(i in 2:n_delta){
    indicator = I(x >= cuts[i-1] & x < cuts[i])
    tp_tangent = (deltas[i]-deltas[i-1])/(cuts[i]-cuts[i-1])
    y_hat = deltas[i-1] + tp_tangent*(x-cuts[i-1])
    term_mid = indicator * loss_func(y_hat-y,params)
    term_1 = term_1 + sum(term_mid)
  }

  term_last = I(x >= cuts[n_delta]) *
    loss_func(y - deltas[n_delta] - deltas[n_delta+2]*(x-cuts[n_delta]),params)

  return(term_1 + sum(term_last))
}


#' For a 2-dimension plot, compare the level how the plot dispersed
#'
#' @param x_data data of dimension 1
#' @param y_data data of dimension 2
#' @param nx how many blocks in x-axis
#' @param ny how many blocks in y-axis
#'
#' @return a real number corresponding how much it disperses
#' @export
#'
#' @examples
#' temp = data_generator(1000,55,gen_type = 'chaos&cut')
#' disperse_level(temp[,1],temp[,2]) #3.71
#' temp = data_generator(1000,55,gen_type = 'normal')
#' disperse_level(temp[,1],temp[,2]) #3.10
disperse_level = function(x_data, y_data, nx = 5, ny = 5){
  max_x = max(x_data) + 0.1
  min_x = min(x_data) - 0.1
  max_y = max(y_data) + 0.1
  min_y = min(y_data) - 0.1

  gap_x = (max_x - min_x)/nx
  gap_y = (max_y - min_y)/ny
  loc_x = floor((x_data - min_x)/gap_x)
  loc_y = floor((y_data - min_y)/gap_y) + 1
  loc_xy = loc_x*ny + loc_y

  output = rep(0,nx*ny)
  for(i in 1:(length(x_data))){
    output[loc_xy[i]] = output[loc_xy[i]] + 1
  }

  output = output/length(x_data)
  output[output == 0] = NA
  output = na.omit(output)
  return(sum(-output*log2(output)))
}

