#' apply_t_test: it uses the statistical t_test to check if the
#' fold-change of half-life (HL) fragments and the fold-change
#' intensity fragments respectively are significant.
#'
#' apply_t_test compares the mean of two neighboring fragments within the same
#' TU to check if the fold-change is significant.
#' Fragments with distance above threshold are not subjected to t-test.
#' Dataframes with less than 3 rows are excluded.
#'
#' The functions used are:
#' 1. fragment_function: checks number of fragments inside TU, less
#' than 2 are excluded otherwise they are gathered for analysis.
#' 2. t_test_function: exclude dataframes with less than 3 rows,
#' makes fold-change and apply t-test, assign fragments names
#' and ratio, add columns with the corresponding p_values.
#'
#' @param inp SummarizedExperiment: the input data frame with correct format.
#' @param threshold integer: threshold.
#' 
#' @return the SummarizedExperiment with the columns regarding statistics:
#' \describe{
#'   \item{ID:}{The bin/probe specific ID}
#'   \item{position:}{The bin/probe specific position}
#'   \item{intensity:}{The relative intensity at time point 0}
#'   \item{half_life:}{The half-life of the bin/probe}
#'   \item{HL_fragment:}{The half-life fragment the bin belongs to}
#'   \item{HL_mean_fragment:}{The mean half-life value of the respective
#'   half-life fragment}
#'   \item{intensity_fragment:}{The intensity fragment the bin belongs to}
#'   \item{intensity_mean_fragment:}{The mean intensity value of the respective
#'   intensity fragment}
#'   \item{TU:}{The overarching transcription unit}
#'   \item{pausing_site:}{}
#'   \item{iTSS_I:}{}
#'   \item{ps_ts_fragment:}{}
#'   \item{event_ps_itss_p_value_Ttest:}{}
#'   \item{p_value_slope:}{}
#'   \item{delay_frg_slope:}{}
#'   \item{velocity_ratio:}{}
#'   \item{event_duration:}{}
#'   \item{event_position:}{}
#'   \item{FC_HL:}{}
#'   \item{FC_fragment_HL:}{}
#'   \item{p_value_HL:}{}
#'   \item{FC_intensity:}{}
#'   \item{FC_fragment_intensity:}{}
#'   \item{p_value_intensity:}{}
#' }
#'
#' @examples
#' data(stats_minimal)
#' apply_t_test(inp = stats_minimal, threshold = 300)
#' 
#' @export

apply_t_test <- function(inp, threshold = 300) {
  rowRanges(inp)$FC_fragment_HL <- NA
  rowRanges(inp)$FC_HL <- NA 
  rowRanges(inp)$p_value_HL <- NA
  rowRanges(inp)$FC_fragment_intensity <- NA
  rowRanges(inp)$FC_intensity <- NA 
  rowRanges(inp)$p_value_intensity <- NA
  uniqueTU <- unique(rowRanges(inp)$TU)
  uniqueTU <- uniqueTU[grep("_NA|_T", uniqueTU, invert = TRUE)]
  for (i in seq_along(uniqueTU)) {
    # select ID, position, HL, HL fragments, intensity and intensity
    # fragments for the corresponding TU
    tu <-
      as.data.frame(rowRanges(inp)[which(rowRanges(inp)$TU %in% uniqueTU[i]), c(
        "ID",
        "position",
        "half_life",
        "TU",
        "HL_fragment",
        "intensity",
        "intensity_fragment",
        "HL_mean_fragment",
        "intensity_mean_fragment"
      )])
    # HL and intensity segments in the TU
    hl_segs <-
      tu[grep(paste0("\\Dc_\\d+", "$"), 
                                     tu$HL_fragment), "HL_fragment"]
    int_segs <- tu[grep(paste0("\\I_\\d+", "$"),
                        tu$intensity_fragment), "intensity_fragment"]
    hl_segs <- fragment_function(hl_segs)
    int_segs <- fragment_function(int_segs)
    # loop into all HL segments and apply t_test between consecutive segments
   tryCatch({
      inp <-
      t_test_function(
        data = inp,
        seg = hl_segs,
        param = "half_life",
        o = "HL",
        tu = tu,
        threshold = threshold
      )
    inp <-
      t_test_function(
        data = inp,
        seg = int_segs,
        param = "intensity",
        o = "intensity",
        tu = tu,
        threshold = threshold
      )
      }, error = function(e) {
    })
  }
  return(inp)
}
