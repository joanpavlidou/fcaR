#' @import tictoc
#' @import parallel
.batch_apply <- function(LHS, RHS,
                         rules = c("generalization",
                                   "composition"),
                         batch_size = ncol(LHS),
                         reorder = TRUE) {

  n_implications <- ncol(LHS)

  if (reorder) {

    # Introduce some random order into implications
    ordering <- sample(seq(n_implications),
                       size = n_implications)

    LHS <- LHS[, ordering]
    RHS <- RHS[, ordering]

  }

  # Make batches
  idx <- c(seq(1, n_implications, by = batch_size),
           n_implications + 1)

  # Parallel execution?
  if (requireNamespace("parallel")) {

    cat("Using parallel execution\n")

    my_apply <- function(x, FUN) parallel::mclapply(x, FUN, mc.cores = parallel::detectCores())

    verbose <- TRUE

  } else {

    my_apply <- lapply

    verbose <- TRUE

  }

  # Process each batch
  RES <- my_apply(seq_along(idx[-1]),
                  function(i) {

                    .process_batch(LHS = LHS[, idx[i]:(idx[i + 1] - 1)],
                                   RHS = RHS[, idx[i]:(idx[i + 1] - 1)],
                                   rules = rules,
                                   verbose = verbose)

                  })

  LHS <- lapply(RES, function(r) r$lhs)
  RHS <- lapply(RES, function(r) r$rhs)

  LHS <- do.call(cbind, args = LHS)
  RHS <- do.call(cbind, args = RHS)

  return(list(lhs = LHS, rhs = RHS))

}