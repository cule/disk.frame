#' @export
#' @import dplyr
select_.disk.frame <- function(.data, ..., .dots){
  .dots <- lazyeval::all_dots(.dots, ...)
  cmd <- lazyeval::lazy(select_(.data, .dots=.dots))
  record(.data, cmd)
}

#' @export
rename_.disk.frame <- function(.data, ..., .dots){
  .dots <- lazyeval::all_dots(.dots, ...)
  cmd <- lazyeval::lazy(rename_(.data, .dots=.dots))
  record(.data, cmd)
  #stop("not implemented rename!")
}

#' @export
filter_.disk.frame <- function(.data, ..., .dots){
  .dots <- lazyeval::all_dots(.dots, ...)
  cmd <- lazyeval::lazy(filter_(.data, .dots=.dots))
  record(.data, cmd)
}

#' @export
mutate_.disk.frame <- function(.data, ..., .dots){
  .dots <- lazyeval::all_dots(.dots, ...)
  cmd <- lazyeval::lazy(mutate_(.data, .dots=.dots))
  record(.data, cmd)
}

#' @export
transmute_.disk.frame <- function(.data, ..., .dots){
  .dots <- lazyeval::all_dots(.dots, ...)
  cmd <- lazyeval::lazy(transmute_(.data, .dots=.dots))
  record(.data, cmd)
}

#' @export
summarise_.disk.frame <- function(.data, ..., .dots){
  .data$.warn <- TRUE
  .dots <- lazyeval::all_dots(.dots, ...)
  cmd <- lazyeval::lazy(summarise_(.data, .dots=.dots))
  record(.data, cmd)
}

#' @export
do_.disk.frame <- function(.data, ..., .dots){
  warning("applying `do` to each chunk of disk.frame; this may not work as expected")
  .dots <- lazyeval::all_dots(.dots, ...)
  cmd <- lazyeval::lazy(do_(.data, .dots=.dots))
  record(.data, cmd)
}

#' @export
inner_join.disk.frame <- function(x, y, by=NULL, copy=FALSE, ..., outdir = NULL, merge_by_chunk_id){
  if("disk.frame" %in% class(y)) {
    #if(all(shardkey(x) == shardkey(y))) {
    ncx = nchunks(x)
    ncy = nchunks(y)
    hard_group_by(x, by, nchunks = max(ncy,ncx))
    hard_group_by(y, by, nchunks = max(ncy,ncx))
    #}
  }
  # note that x is named .data in the lazy evaluation
  .data <- x
  cmd <- lazyeval::lazy(inner_join(.data, y, by, copy, ...))
  record(.data, cmd)
}

#' @export
left_join.disk.frame <- function(x, y, by=NULL, copy=FALSE, ..., merge_by_chunk_id){
  # note that x is named .data in the lazy evaluation
  .data <- x
  cmd <- lazyeval::lazy(left_join(.data, y, by, copy, ...))
  record(.data, cmd)
}

#' @export
semi_join.disk.frame <- function(x, y, by=NULL, copy=FALSE, ..., merge_by_chunk_id){
  # note that x is named .data in the lazy evaluation
  .data <- x
  cmd <- lazyeval::lazy(semi_join(.data, y, by, copy, ...))
  record(.data, cmd)
}

#' @export
anti_join.disk.frame <- function(x, y, by=NULL, copy=FALSE, ..., merge_by_chunk_id){
  # note that x is named .data in the lazy evaluation
  .data <- x
  cmd <- lazyeval::lazy(anti_join(.data, y, by, copy, ...))
  record(.data, cmd)
}

#' 
groups.disk.frame <- function(x){
  shardkey(x)
}

#' Group by designed for disk.frames
#' @import pryr dplyr purrr
#' @export
#' @rdname group_by
group_by.disk.frame <- function(.data, ..., add = FALSE, hard = FALSE, outdir = NULL) {
  # hard group_by requested, need to regroup these into 
  # get a list of variables to group by
  #browser()
  dots <- dplyr:::compat_as_lazy_dots(...)
  shardby = map_chr(dots, ~deparse(.x$expr))
  
  if (hard == TRUE) {
    if(is.null(outdir)) {
      outdir = tempfile("tmp_disk_frame")
    }
    
    .data = hard_group_by(.data, by = shardby, outdir = outdir)
    #browser()
    .data = dplyr::group_by_(.data, .dots = dplyr:::compat_as_lazy_dots(...), add = add)
    return(.data)
  } else if (hard == FALSE) {
    #if(sort(shardkey(.data)) != sort(shardby)) {
    warning("hard is set to FALSE but grouping don't match up between disk.frame and group by vars")
    #}
    return(dplyr::group_by_(.data, .dots = dplyr:::compat_as_lazy_dots(...), add = add))
  } else {
    stop("group_by for disk.frames must set hard to TRUE or FALSE")
  }
}

#' @export
group_by_.disk.frame <- function(.data, ..., .dots, add=FALSE){
  .dots <- lazyeval::all_dots(.dots, ...)
  cmd <- lazyeval::lazy(group_by_(.data, .dots=.dots, add=add))
  record(.data, cmd)
}

#' Take a glimpse
#' @export
glimpse.disk.frame <- function(df, ...) {
  glimpse(head(df, ...), ...)
}

record <- function(.data, cmd){
  attr(.data,"lazyfn") <- c(attr(.data,"lazyfn"), list(cmd))
  .data
}

play <- function(.data, cmds=NULL){
  #browser()
  for (cmd in cmds){
    if (typeof(cmd) == "closure") {
      .data <- cmd(.data)
      #print(.data)
    } else {
      .data <- lazyeval::lazy_eval(cmd, list(.data=.data)) 
    }
  }
  .data
}