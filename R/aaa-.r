#' @include ggplot-global.R
#' @include ggproto.r
NULL

#' Base ggproto classes for ggplot2
#'
#' If you are creating a new geom, stat, position, or scale in another package,
#' you'll need to extend from `ggplot2::Geom`, `ggplot2::Stat`,
#' `ggplot2::Position`, or `ggplot2::Scale`.
#'
#' @seealso ggproto
#' @keywords internal
#' @name ggplot2-ggproto
NULL

# Fast data.frame constructor
# No checking, recycling etc. unless asked for
new_data_frame <- function(x = list(), n = NULL) {
  if (is.null(n)) {
    n <- if (length(x) == 0) 0 else length(x[[1]])
  }

  class(x) <- "data.frame"

  attr(x, "row.names") <- .set_row_names(n)
  x
}

validate_data_frame <- function(x) {
  if (length(unique(lengths(x))) != 1) stop('All elements in a data.frame must be of equal length', call. = FALSE)
  if (is.null(names(x))) stop('Columns must be named', call. = FALSE)
}

mat_2_df <- function(x, .check = FALSE) {
  c_names <- colnames(x)
  x <- split(x, rep(seq_len(ncol(x))), each = nrow(x))
  names(x) <- c_names
  new_data_frame(x)
}
