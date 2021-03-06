#' Request a flat format file from those as generated by format_*()
#' Flattening the file format allows for substantial speed increases
#' in optimization however limits readability. Using the split functionality
#' between the format_*() functions and this function allows for easier
#' subsetting of datasets.
#'
#' @param data structure list generated by format_*() functions
#' @return returns a flat file format structure of the format_*() input
#' data, this to speed up processing
#' @keywords phenology, model, preprocessing
#' @export

flat_format = function(data = NULL){

  if (is.null(data)){
    stop('please provide a structured list as generated by format_*() functions!')
  }

  # check if the element is flat by default
  if ("transition_dates" %in% names(data)){
    return(data)
  }

  # find the doy ranges as stored in the doy slot
  # of the first site
  doy = data[[1]]$doy

  # bind / calculate the photoperiod (daylength)
  # for all locations with do.call()
  Li = do.call("cbind",lapply(data,function(x)x$Li))

  # concat sitenames into a vector using a do.call()
  site = as.character(do.call("c",lapply(data, function(x){
    if(!is.null(x)){
      rep(x$site, ncol(x$Ti))
    }
  })))

  # concat locations data into a matrix with the first row
  # being the latitude and the second longitude
  location = do.call("cbind",lapply(data,function(x){
    if(!is.null(x)){
      matrix(rep(x$location, ncol(x$Ti)), 2, ncol(x$Ti))
    }
  }))

  # concat all temperature data in one big matrix
  Ti = do.call("cbind",lapply(data,function(x)x$Ti))
  Tmini = do.call("cbind",lapply(data,function(x)x$Tmini))
  Tmaxi = do.call("cbind",lapply(data,function(x)x$Tmaxi))

  # concat all precip data in one big matrix
  Pi = do.call("cbind",lapply(data,function(x)x$Pi))

  # concat all precip data in one big matrix
  VPDi = do.call("cbind",lapply(data,function(x)x$VPDi))

  # long term mean
  ltm = matrix(NA,365,length(site))
  for (i in 1:length(site)){
    ltm[,i] = data[[which(names(data) == site[i])]]$ltm
  }

  # concat all transition dates for validatino into
  # a long vector
  transition_dates = as.vector(do.call("c",lapply(data,function(x)x$transition)))

  # recreate the validation data structure (new format)
  # but with concatted data
  flat_data = list("site" = site,
              "location" = location,
              "doy" = doy,
              "transition_dates" = transition_dates,
              "ltm" = ltm,
              "Ti" = Ti,
              "Tmini" = Tmini,
              "Tmaxi" = Tmaxi,
              "Li" = Li,
              "Pi" = Pi,
              "VPDi" = VPDi,
              "georeferencing" = NULL
              )

  # assign a class for post-processing
  class(flat_data) = class(data)

  # return the formatted, faster data format
  return(flat_data)
}
