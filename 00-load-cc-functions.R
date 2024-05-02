# 00-load-cc-functions.R
# functions used in coral counterfactual analysis
# W. Friedman 2022

# beta_transform(x)
# function to transform pct_hardcoral from 0-100 to 0-1, 
# with a fractional value assigned to 0 so the model runs 
# same fraction subtracted from values equal to 1

beta_transform <- function(x){
  adjust_x = 1e-06
  x1 = x/100
  x1[x1==0] <- adjust_x
  x1[x1==1] <- 1-adjust_x
  return(x1)
}

# print max and min of numeric vectors
maxmin <- function(x){
  x_max = round(max(x, na.rm = T),3)
  x_min = round(min(x, na.rm = T),3)
  cat(x_min,x_max,sep = ", ")
}

# plt_partials(ranger_object, variable_list)
plt_partials <- function(rg_obj, var_set){
  #plot partials
  plt_list <- list()
  
  for(v in var_set){
    plt <- pdp::partial(rg_obj, pred.var = v, 
                        plot = T, rug = T, 
                        plot.engine = "ggplot2")
    plt_list[[v]] <- plt
  }
  
  # create plot figure & save
  plt_title <- paste(var_set, collapse = "_")
  pd_plt <- cowplot::plot_grid(plotlist = plt_list, nrow = 2)
  
  return(pd_plt)
}
