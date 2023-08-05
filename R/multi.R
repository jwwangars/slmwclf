#' Calculate aggregated loss with input loss function
#'
#' @param deltas modeling with segmented line by points of ({cuts[i,j,k...]}, deltas[i])
#' @param x independent variable
#' @param y dependent variable
#' @param cuts list, modeling with segmented line by points of ({cuts[i,j,k...]}, deltas[i])
#' @param loss loss function
#' @param params Other parameters in loss function. Use 'NULL' if only one input.
#' @return total loss
#' @export
#'
#' @examples
#' temp = data_generator(1000,55,gen_type = 'chaos&cut')
#' y = temp[,2]
#' one_trial = temp[,-2]
#' cuts = list(c(-2,3,5,8,11,15,30),c(-10,0,10,20,30),c(0,33,67,100))
#' deltas = c(rep(500,7*5*4),0.1,0.1)
#' output = nlminb(deltas, multi_sum_loss, x = one_trial, y = y, cuts = cuts,
#'     loss = L2, control = list(iter.max=4, eval.max = 45,
#'     trace = 1, abs.tol = 1e-20), lower = c(rep(-Inf,140),0,0))
#' multi_sum_loss(output$par,one_trial, y, cuts, L2)
multi_sum_loss = function (deltas, x, y, cuts, loss, params = NULL) {
  if (is.null(params)) {
    loss_func = function(x, temp = NULL) {
      return(loss(x))
    }
  }
  else {
    loss_func = loss
  }
  sample_size = dim(x)[1]
  dim_x = length(cuts)

  x_num_points = NULL
  for(i in 1:dim_x){
    x_num_points = c(x_num_points, length(cuts[[i]]))
  }
  base_scale = cumprod(x_num_points)
  base_scale = c(1, base_scale)
  coef_weight = c(1, deltas[(1+base_scale[dim_x+1]):(dim_x-1+base_scale[dim_x+1])])
  coef_weight[coef_weight<0] = 0

  y_hat = NULL
  for(i in 1:sample_size){
    low_loc = NULL
    for(one_dim in 1:dim_x){
      low_loc = c(low_loc, sum(cuts[[one_dim]] < x[i,one_dim]) - 1)
    }
    for(one_dim in 1:dim_x){
      temp_add = c(rep(0,one_dim-1),1,rep(0,dim_x-one_dim))
      low_loc = cbind(low_loc, low_loc+temp_add)#'dim' rows and 2^'dim' columns finally
    }
    delta_loc = 1
    distance = 0
    for(one_dim in 1:dim_x){#input_delta point locations
      delta_loc = delta_loc + base_scale[one_dim]*low_loc[one_dim,]
      distance = distance + coef_weight[one_dim]*
        (cuts[[one_dim]][low_loc[one_dim,]+1] - x[i,one_dim])^2#use Euclid space
    }
    distance = sqrt(distance) # L2 distance
    one_weights = NULL
    for(one_point in 1:(2^dim_x)){
      one_weights = c(one_weights,prod(distance[-one_point]))
    }
    one_weights = one_weights/sum(one_weights)
    y_hat = c(y_hat, sum(one_weights*deltas[delta_loc]))
  }

  return(sum(loss_func(y - y_hat, params)))
}


#' Generate a model of multivariate segmented linear network
#'
#' @param x independent variables
#' @param y dependent variable
#' @param cuts list, modeling with segmented line by points of ({cuts[i,j,k...]}, deltas[i])
#' @param init_deltas default to be mean(y)
#' @param iter_ctrl as 'control' in function 'nlminb'
#' @param loss loss function
#' @param params loss function
#' @param lower lower bound of deltas, default -Inf for values and 0.5 for metric
#'
#' @return a model of multivariate segmented linear network
#' @export
#'
#' @examples
#' temp = data_generator(1000,55,gen_type = 'chaos&cut')
#' y = temp[,2]
#' one_trial = temp[,-2]
#' cuts = list(c(-2,4,8,12,21),c(-10,3,16,30),c(0,33,67,100))
#' output = msl_network(x = one_trial, y = y, cuts = cuts,
#'     loss = L1, iter_ctrl = list(iter.max=4, trace = 1))
msl_network = function(x, y, cuts,
                       init_deltas = NULL, iter_ctrl = NULL,
                       loss = L2, params = NULL, lower = NULL){
  dim_x = length(cuts)
  x_num_points = NULL
  for(i in 1:dim_x){
    x_num_points = c(x_num_points, length(cuts[[i]]))
  }

  if(is.null(init_deltas)){
    init_deltas = as.numeric(c(rep(mean(y),prod(x_num_points)), rep(0.5,dim_x-1)))
  }
  if(is.null(lower)){
    lower = as.numeric(c(rep(-Inf,prod(x_num_points)), rep(0,dim_x-1)))
  }
  if(is.null(iter_ctrl)){
    iter_ctrl = list(iter.max = 120, eval.max = 200, trace = 40)
  }

  temp_outcome = nlminb(init_deltas, multi_sum_loss, x = x, y = y, cuts = cuts,
                        loss = loss, control = iter_ctrl, lower = lower)
  message(temp_outcome$message)

  temp_output = list(deltas = temp_outcome$par,
                     dim_x = dim_x,
                     cuts = cuts)
  y_hat = predict_msln(temp_output, x)

  output = list(deltas = temp_outcome$par,
                dim_x = dim_x,
                cuts = cuts,
                fitted_values = y_hat,
                residuals = as.numeric(y-y_hat),
                rank = length(init_deltas),
                loss = temp_outcome$objective,
                convergence_status = temp_outcome$convergence,
                iterations = temp_outcome$iterations)
  attributes(output)$class = 'lm'
  return(output)
}





#' Predict for a multivariate segmented linear network model
#'
#' @param one_model a model generated from msl_network
#' @param newdata new data to be predicted
#'
#' @return predicted value
#' @export
#'
#' @examples
#' temp = data_generator(1000,55,gen_type = 'chaos&cut')
#' y = temp[,2]
#' one_trial = temp[,-2]
#' cuts = list(c(-2,4,8,12,21),c(-10,3,16,30),c(0,33,67,100))
#' tp2_output = msl_network(x = one_trial, y = y, cuts = cuts,
#'     loss = L1, iter_ctrl = list(iter.max=4, trace = 1))
#' predict_msln(tp2_output,one_trial)[1:5]
predict_msln = function(one_model, newdata){
  sample_size = dim(newdata)[1]
  cuts = one_model$cuts
  deltas = one_model$deltas
  dim_x = length(cuts)

  x_num_points = NULL
  for(i in 1:dim_x){
    x_num_points = c(x_num_points, length(cuts[[i]]))
  }
  base_scale = cumprod(x_num_points)
  base_scale = c(1, base_scale)
  coef_weight = c(1, deltas[(1+base_scale[dim_x+1]):(dim_x-1+base_scale[dim_x+1])])
  coef_weight[coef_weight<0] = 0

  y_hat = NULL
  for(i in 1:sample_size){
    low_loc = NULL
    for(one_dim in 1:dim_x){
      low_loc = c(low_loc, sum(cuts[[one_dim]] < newdata[i,one_dim]) - 1)
    }
    #for points out of boundary:
    low_loc[low_loc<0] = 0
    low_loc[low_loc>x_num_points-1] = x_num_points[low_loc>x_num_points-1] - 1

    for(one_dim in 1:dim_x){
      temp_add = c(rep(0,one_dim-1),1,rep(0,dim_x-one_dim))
      low_loc = cbind(low_loc, low_loc+temp_add)#'dim' rows and 2^'dim' columns finally
    }
    delta_loc = 1
    distance = 0
    for(one_dim in 1:dim_x){#input_delta point locations
      delta_loc = delta_loc + base_scale[one_dim]*low_loc[one_dim,]
      distance = distance + coef_weight[one_dim]*
        (cuts[[one_dim]][low_loc[one_dim,]+1] - newdata[i,one_dim])^2#use Euclid space
    }
    distance = sqrt(distance) # L2 distance
    one_weights = NULL
    for(one_point in 1:(2^dim_x)){
      one_weights = c(one_weights,prod(distance[-one_point]))
    }
    one_weights = one_weights/sum(one_weights)
    y_hat = c(y_hat, sum(one_weights*deltas[delta_loc]))
  }

  return(as.numeric(y_hat))
}



