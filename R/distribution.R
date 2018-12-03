TOLERANCE <- 1e-8

effect_density_function <- function(alpha_a, beta_a,
                                    alpha_b, beta_b,
                                    convolution = c(0, 1),
                                    tolerance = TOLERANCE) {
  density_a <- function(x) dbeta(-x, alpha_a, beta_a)
  density_b <- function(x) dbeta(x, alpha_b, beta_b)
  evaluate <- function(y, x) density_b(y) * density_a(x - y)
  function(x) integrate(evaluate, convolution[1], convolution[2], x,
                        abs.tol = tolerance)$value
}

effect_distribution_function <- function(..., tolerance = TOLERANCE) {
  evaluate <- Vectorize(effect_density_function(..., tolerance = tolerance))
  function(x) integrate(evaluate, -1, x, abs.tol = tolerance)$value
}

effect_inverse_function <- function(..., inversion = c(-1, 1), tolerance = TOLERANCE) {
  distribution <- effect_distribution_function(..., tolerance = tolerance)
  evaluate <- function(x, p) distribution(x) - p
  function(p) uniroot(evaluate, inversion, p, tol = tolerance)$root
}