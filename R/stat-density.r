#' @param bw The smoothing bandwidth to be used.
#'   If numeric, the standard deviation of the smoothing kernel.
#'   If character, a rule to choose the bandwidth, as listed in
#'   [stats::bw.nrd()].
#' @param adjust A multiplicate bandwidth adjustment. This makes it possible
#'    to adjust the bandwidth while still using the a bandwidth estimator.
#'    For example, `adjust = 1/2` means use half of the default bandwidth.
#' @param kernel Kernel. See list of available kernels in [density()].
#' @param n number of equally spaced points at which the density is to be
#'   estimated, should be a power of two, see [density()] for
#'   details
#' @param trim This parameter only matters if you are displaying multiple
#'   densities in one plot. If `FALSE`, the default, each density is
#'   computed on the full range of the data. If `TRUE`, each density
#'   is computed over the range of that group: this typically means the
#'   estimated x values will not line-up, and hence you won't be able to
#'   stack density values.
#' @section Computed variables:
#' \describe{
#'   \item{density}{density estimate}
#'   \item{count}{density * number of points - useful for stacked density
#'      plots}
#'   \item{scaled}{density estimate, scaled to maximum of 1}
#'   \item{ndensity}{alias for `scaled`, to mirror the syntax of
#'    [`stat_bin()`]}
#' }
#' @export
#' @rdname geom_density
stat_density <- function(mapping = NULL, data = NULL,
                         geom = "area", position = "stack",
                         ...,
                         bw = "nrd0",
                         adjust = 1,
                         kernel = "gaussian",
                         n = 512,
                         trim = FALSE,
                         na.rm = FALSE,
                         show.legend = NA,
                         inherit.aes = TRUE) {

  layer(
    data = data,
    mapping = mapping,
    stat = StatDensity,
    geom = geom,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      bw = bw,
      adjust = adjust,
      kernel = kernel,
      n = n,
      trim = trim,
      na.rm = na.rm,
      ...
    )
  )
}

#' @rdname ggplot2-ggproto
#' @format NULL
#' @usage NULL
#' @export
StatDensity <- ggproto("StatDensity", Stat,
  default_aes = aes(x = stat(density), y = stat(density), fill = NA, weight = NULL),

  setup_params = function(data, params) {
    params$main_aes <- "x"
    if (is.null(data$x) && is.null(params$x)) {
      if (is.null(data$y) && is.null(params$y)) {
        stop("stat_bin() requires either an x or y aesthetic.", call. = FALSE)
      } else {
        params$main_aes <- "y"
      }
    }
    params
  },

  compute_group = function(data, scales, bw = "nrd0", adjust = 1, kernel = "gaussian",
                           n = 512, trim = FALSE, na.rm = FALSE, main_aes = "x") {
    if (trim) {
      range <- range(data[[main_aes]], na.rm = TRUE)
    } else {
      range <- scales[[main_aes]]$dimension()
    }

    compute_density(data[[main_aes]], data$weight, from = range[1], to = range[2],
      bw = bw, adjust = adjust, kernel = kernel, n = n, main_aes = main_aes)
  }

)

compute_density <- function(x, w, from, to, bw = "nrd0", adjust = 1,
                            kernel = "gaussian", n = 512, main_aes = "x") {
  nx <- length(x)
  if (is.null(w)) {
    w <- rep(1 / nx, nx)
  } else {
    w <- w / sum(w)
  }

  # if less than 2 points return data frame of NAs and a warning
  if (nx < 2) {
    warning("Groups with fewer than two data points have been dropped.", call. = FALSE)
    density <- new_data_frame(list(
      x = NA_real_,
      density = NA_real_,
      scaled = NA_real_,
      ndensity = NA_real_,
      count = NA_real_,
      n = NA_integer_
    ), n = 1)
    names(density)[1] <- main_aes
    return(density)
  }

  dens <- stats::density(x, weights = w, bw = bw, adjust = adjust,
    kernel = kernel, n = n, from = from, to = to)

  density <- new_data_frame(list(
    x = dens$x,
    density = dens$y,
    scaled =  dens$y / max(dens$y, na.rm = TRUE),
    ndensity = dens$y / max(dens$y, na.rm = TRUE),
    count =   dens$y * nx,
    n = nx,
    main_aes = main_aes
  ), n = length(dens$x))
  names(density)[1] <- main_aes
  return(density)
}
