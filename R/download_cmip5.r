#' Download NASA Earth Exchange Global Daily Downscaled Projections (NEX-GDDP)
#' https://nex.nasa.gov/nex/
#'
#' @param path a path where to save the gridded data
#' @param year year to process (also requests year - 1)
#' @param model CMIP5 model data to download (character vector)
#' @param scenario which RCP scenario to select for (default = "rcp85")
#' @param variable which climate variables to download (tasmin, tasmax, pr)
#' (default = c("tasmin","tasmax","pr"))
#' @return nothing is returned to the R working environment, files are
#' downloaded and stored on disk
#' @keywords phenology, model, data
#' @export
#' @examples
#'
#' # donwload all gridded data for year 2014
#' \dontrun{
#' download_cmip5(year = 2011)
#'}

# create subset of layers to calculate phenology model output on
download_cmip5 = function(path = "~",
                          year = 2016,
                          model = "miroc5",
                          scenario = "rcp85",
                          variable = c("tasmin","tasmax","pr")){

  # get file listing of available data
  files = read.table("https://nex.nasa.gov/static/media/dataset/nex-gddp-nccs-ftp-files.csv",
                     header = TRUE,
                     stringsAsFactors = FALSE)$ftpurl

  # selection
  selection = do.call("c",lapply(files, function(x){
    # grep the files for multiple selection
    # criteria
    if(all(c(grepl(paste(c(year,year - 1), collapse = "|"),x),
             grepl(paste(variable, collapse = "|"),x),
             grepl(scenario, x),
             grepl(toupper(model),x)))){
        return(x)
      }else{
        return(NULL)
    }
    }))

  # trap cases where the slection of files is NULL (no matches)
  # return error
  if(is.null(selection)){
    stop("No files meet the specified criteria, please check the parameters!")
  }

  # download data
  lapply(selection, function(i){

    # set download / filename strings
    file_location = sprintf("%s/%s",path,basename(i))

    # feedback on which file is being downloaded
    cat(paste0("Downloading: ",basename(i)))

    # try to download the data if the file does not
    # exist
    if(!file.exists(file_location)){
      error = try(httr::GET(url = i,
                        httr::authenticate(user='NEXGDDP',
                                           password='',
                                           type = "basic"),
                        httr::write_disk(path=file_location, overwrite = TRUE),
                        httr::progress()),
                  silent = TRUE)

      if (inherits(error, "try-error")){
        file.remove(file_location)
        stop("failed to download the requested data, check your connection")
      }
    } else {
      cat("local file exists, skipping download \n")
    }
  })

  # feedback
  cat("Download complete! \n")
}
