
<!-- README.md is generated from README.Rmd. Please edit that file -->

# slmwclf

<!-- badges: start -->
<!-- badges: end -->

Segmented linear model with changeable loss function.

The goal of slmwclf is to fit for segmented linear model, where not
constrained by L2 loss function (as how package ‘segmented’ does).

Here is a list of situations where this package may be useful:

1.  You are confined by a indicator, and different customer applies
    different explanation of this indicator;
2.  Some samples are deviated under a rough criterion, to whom a
    specially-designed loss may help to resolve;
3.  One main feature explains most of the effect, and other features
    count limited weights;
4.  Randomly try different loss functions.

## Installation

Package *slmwclf* is in <https://github.com/jwwangars/slmwclf>.

## Example

### Basic operation

This is a basic example which shows you how to solve a common problem:

``` r
library(slmwclf)
temp = data_generator(1000,55,gen_type = 'chaos&cut')#simulated data
model_1 = SLM_construct(temp[,1],temp[,2],
                        fixed_psi = c(2,6,8,10), loss_function = L2)
print(model_1)
#> $x
#> [1]  2  6  8 10
#> 
#> $y
#> [1] 147.1483 216.1691 424.1525 978.4060
#> 
#> $init_tangent
#> [1] 8.410823
#> 
#> $final_tangent
#> [1] -0.9017844
#> 
#> $loss
#> [1] 79439559
predict_model(model_1, c(0,1,10,100,0.5,-1333))
#> [1]    130.3266    138.7374    978.4060    897.2454    134.5320 -11081.3004
#' plot(temp[,1],temp[,2]) # if you need a plot
#' draw_lines_model(model_1,'red')
```

### Loss functions

This package contains the following loss functions: L1, L1_shrink, L2,
sim_sigmoid_soft. Note that sim_sigmoid_hard is also a loss function,
however sometimes it interrupts iteration, please use sim_sigmoid_soft
instead.

You can check loss function as:

``` r
sim_sigmoid_soft(1:10,c(3,5))
#>  [1] 0.05315114 0.07446795 0.12786157 0.25350602 0.50000000 0.78918171
#>  [7] 0.94684886 0.99080629 0.99879492 0.99987661
```

Creating your own loss function within ‘SLM_construct’:

Suppose the loss function has super-parameter as **a,b,c**, or we say
**L(x\|a,b,c)**. Then the new loss function should have 2 input
parameters, the first is the independent variable, which here is the
error **x**, the second one is ALL of the super-parameter.

For this particular example, it comes as:

**L(x) = function(x,c(a,b,c)){other codes … }**

Just as how *sim_sigmoid_soft* does.

You can use only one input if there is no super-parameter. Like **L(x) =
function(x){…}**.

### Other functions

Two other functions in this package do the data-cleansing and calculate
the disperse-level:

``` r
temp1 = data_sieve(temp[,1],temp[,2],c(0.7,0.85,500),if_plot = FALSE)
disperse_level(temp[,1],temp[,2])#3.71
#> [1] 3.710436
disperse_level(temp1$x,temp1$y)#3.51
#> [1] 3.515456
```
