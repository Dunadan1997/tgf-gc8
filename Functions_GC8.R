# Function to predict using regsubsets
predict.regsubsets <- function(object, newdata , id, ...) {
  form <- as.formula(object$call[[2]])
  mat <- model.matrix(form, newdata)
  coefi <- coef(object, id = id)
  xvars <- names(coefi)
  mat[, xvars] %*% coefi
}

# Function to compute MSE of Ridge or Lasso models
reg_model <- function(reg_type) {
  
  # Create vector to store MSEs
  
  cv_mse <- rep(NA, k)
  
  for (i in 1:k) {
    
    # Split data
    test.idx <- 
      which(folds == i)
    train.idx <- 
      setdiff(1:nrow(x), test.idx)
    
    x.train <- 
      x[train.idx, ]
    y.train <- 
      y[train.idx]
    x.test <- 
      x[test.idx, ]
    y.test <-
      y[test.idx]
    
    # Cross-validated lambda selection
    cv <- 
      cv.glmnet(x.train, y.train, alpha = reg_type)
    bestlam <- 
      cv$lambda.min
    
    # Fit Lasso model with best lambda
    fit <- 
      glmnet(x.train, y.train, alpha = reg_type, lambda = bestlam)
    
    # Predict on outer fold test set
    y.pred <- 
      predict(fit, newx = x.test)
    
    # Compute and store MSE
    cv_mse[i] <-
      mean((y.pred - y.test)^2)
    
    coefs <- coef(fit)
    coef_vector <- as.vector(coefs)
    names(coef_vector) <- rownames(coefs)
    best.vars.shrinkage[1,colnames(best.vars.shrinkage) %in% colnames(as_tibble_row(coef_vector))] <- as_tibble_row(coef_vector)[colnames(as_tibble_row(coef_vector)) %in% colnames(best.vars.shrinkage)]
    
  }
  
  print(cv_mse)
  
}

# Function to plot coefficient path
coef_path_plot <- function(mod_type, lambda_value, impact_vars) {

  model <- 
    glmnet(x_controls, y, alpha = mod_type, penalty.factor = penalty)
  
  beta_mat <- 
    as.matrix(model$beta)
  
  coef_df <- 
    as.data.frame(beta_mat)
  
  lambda_vals <- 
    tibble(lambda = model$lambda, lambda_index = colnames(coef_df))
  
  coef_df$predictor <- 
    rownames(coef_df)
  
  coef_long <- 
    coef_df %>%
    pivot_longer(
      cols = -predictor,
      names_to = "lambda_index",
      values_to = "coefficient"
    ) %>% 
    left_join(
      lambda_vals, 
      by = "lambda_index", 
      keep = FALSE) %>% 
    mutate(
      log_lambda = log(lambda)
    )
  
  selected_vars <- 
    colnames(x_controls[,!startsWith(colnames(x_controls), "donor_name") & colnames(x_controls) != "year_std"])
  
  coef_filtered <- coef_long %>%
    filter(predictor %in% selected_vars)
  
  ggplot() +
    geom_line(
      data = coef_filtered[!coef_filtered[["predictor"]] %in% impact_vars, ],
      aes(x = log_lambda, y = coefficient, group = predictor),
      size = 0.5, color = grey, alpha = 0.25) +
    geom_line(
      data = coef_filtered[coef_filtered[["predictor"]] %in% impact_vars, ], 
      aes(x = log_lambda, y = coefficient, color = predictor, linetype = predictor), 
    ) +
    geom_vline(xintercept = log(lambda_value)) +
    labs(
      x = "log(Lambda)",
      y = "Coefficient"
    ) +
    theme_minimal()
  
}
