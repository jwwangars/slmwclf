
#' Loss function of L(x) = (1+exp(-k*((x/m)^2)-1))^-1
#'
#' @param x original error
#' @param k a length 2 vector, indicates how sharp the gap is & the position of gap
#'
#' @return loss
#' @export
#'
#' @examples
#' plot(1:10,sim_sigmoid_soft(1:10,c(3,5)))
#' plot(1:100,sim_sigmoid_soft(1:100,c(3,50)))
#' plot(1:100,sim_sigmoid_soft(1:100,c(10,50)))
sim_sigmoid_soft = function(x,k=c(3,100)){
  x = x/k[2]
  return(1/(1+exp(-k[1]*(x*x-1))))
}


#' Loss function of L(x) = I(abs(x)>m), with gap's tangent -> inf
#'
#' @param x original error
#' @param m the position of gap
#'
#' @return loss
#' @export
#'
#' @examples
#' plot(1:100,sim_sigmoid_hard(1:100,30))
sim_sigmoid_hard = function(x,m){
  # this may lead to calculation error since the tangent is infinity
  # consider change to 'sim_sigmoid_soft' instead when it occurs
  return(I(abs(x)>m))
}


#' Loss function of L(x) = I(abs(x)>m)*(abs(x)-m)
#'
#' @param x original error
#' @param m the position of gap
#'
#' @return loss
#' @export
#'
#' @examples
#' plot(1:100,L1_shrink(1:100,30))
L1_shrink = function(x,m){
  return(I(abs(x)>m)*(abs(x)-m))
}

#' Loss function of L(x) = abs(x), same as abs(x)
#'
#' @param x original error
#'
#' @return loss
#' @export
#'
#' @examples
#' plot(1:100,L1(1:100))
L1 = function(x){
  return(abs(x))
}

#' Loss function of L(x) = x^2
#'
#' @param x original error
#'
#' @return loss
#' @export
#'
#' @examples
#' plot(1:100,L2(1:100))
L2 = function(x){
  return(x^2)
}








