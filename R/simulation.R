simulate <- function(data,
                     day_num,
                     expected_gain = FALSE,
                     expected_loss = FALSE,
                     expected_rate = FALSE,
                     greater_probability = FALSE,
                     high_density = FALSE, ...) {
  data <- data %>%
    cbind(...) %>%
    mutate(rate_a = if ('rate_a' %in% names(.)) rate_a
                    else rbeta(n(), alpha_prior_a, beta_prior_a),
           rate_b = if ('rate_b' %in% names(.)) rate_b
                    else rbeta(n(), alpha_prior_b, beta_prior_b)) %>%
    crossing(day = seq_len(day_num)) %>%
    crossing(group = c('a', 'b')) %>%
    mutate(group = factor(group),
           total_num = rbinom(n(), daily_num, 0.5),
           success_num = rbinom(n(), total_num, if_else(group == 'a', rate_a, rate_b))) %>%
    group_by_at(vars(-day, -total_num, -success_num)) %>%
    arrange(day) %>%
    mutate(total_num = cumsum(total_num),
           success_num = cumsum(success_num)) %>%
    ungroup() %>%
    gather(key, value, total_num, success_num) %>%
    unite(key, key, group, sep = '_') %>%
    spread(key, value)
  if (!isFALSE(expected_gain) ||
      !isFALSE(expected_loss) ||
      !isFALSE(expected_rate) ||
      !isFALSE(greater_probability) ||
      !isFALSE(high_density)) {
    data <- data %>%
      mutate_posterior()
  }
  if (!isFALSE(expected_gain)) {
    data <- data %>%
      mutate(expected_gain = do.call('expected_gain',
                                     extract_two_posterior(data, expected_gain)))
  }
  if (!isFALSE(expected_loss)) {
    data <- data %>%
      mutate(expected_loss = do.call('expected_loss',
                                     extract_two_posterior(data, expected_loss)))
  }
  if (!isFALSE(expected_rate)) {
    data <- data %>%
      mutate_posterior_mean()
  }
  if (!isFALSE(greater_probability)) {
    data <- data %>%
      mutate(greater_probability = do.call('log_greater_probability',
                                           extract_two_posterior(data, greater_probability)),
             greater_probability = exp(greater_probability))
  }
  if (!isFALSE(high_density)) {
    data <- data %>%
      mutate(high_density_a = do.call('high_density',
                                      extract_one_posterior('a', data, high_density)),
             high_density_b = do.call('high_density',
                                      extract_one_posterior('b', data, high_density)))
  }
  data
}

extract_one_posterior <- function(group, data, arguments) {
  arguments <- if (isTRUE(arguments)) list() else arguments
  alpha <- paste('alpha_posterior', group, sep = '_')
  beta <- paste('beta_posterior', group, sep = '_')
  c(list(alpha = data[[alpha]], beta = data[[beta]]), arguments)
}

extract_two_posterior <- function(data, arguments) {
  arguments <- if (isTRUE(arguments)) list() else arguments
  c(list(alpha_a = data$alpha_posterior_a,
         beta_a = data$beta_posterior_a,
         alpha_b = data$alpha_posterior_b,
         beta_b = data$beta_posterior_b),
    arguments)
}

mutate_posterior <- function(data) {
  data %>%
    mutate(alpha_posterior_a = alpha_prior_a + success_num_a,
           alpha_posterior_b = alpha_prior_b + success_num_b,
           beta_posterior_a = beta_prior_a + total_num_a - success_num_a,
           beta_posterior_b = beta_prior_b + total_num_b - success_num_b)
}

mutate_posterior_mean <- function(data) {
  data %>%
    mutate(rate_posterior_a = alpha_posterior_a / (alpha_posterior_a + beta_posterior_a),
           rate_posterior_b = alpha_posterior_b / (alpha_posterior_b + beta_posterior_b))
}
