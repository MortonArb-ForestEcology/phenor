#' Preprocessing of PEP725 data, merges separate files into tidy
#' data, with each observation a line, each column a different
#' parameter value.
#'
#' @param path a path to the PEP725 data (either a directory containing tar.gz
#' files or a single tar.gz file)
#' @return concatted data of all data in the path as a tidy data frame
#' including all normal parameters, and the species name and country code
#' as derived from the file name
#' @keywords phenology, model, preprocessing
#' @export
#' @examples
#'
#' \dontrun{
#' tidy_pep_data = merge_pep725()
#'}

merge_pep725 = function(path = "~"){

  # set encoding to circumvent messy encoding in database
  Sys.setlocale("LC_ALL", "C")

  # get tmp directory
  tmpdir = tempdir()

  # if a path to a directory is given, list all tar.gz files
  # if not, assume the linked file is a tar.gz PEP725 file
  # (no formal checks for this are in place)
  if (dir.exists(path)){
    archive_files = list.files(path, "^PEP725.*\\.tar\\.gz$", full.names = TRUE)
  } else {
    archive_files = path
  }

  # return data from a do call, binding the different
  # data sets by row
  do.call("rbind",lapply(archive_files, function(file){

    # check the contents of the tar.gz file
    # and only select true data files (discard README and descriptor)
    pep_files = untar(file, list=TRUE)
    pep_files = pep_files[!grepl("^.*PEP725_BBCH.csv$|PEP725_README.txt", pep_files)]

    # extract only the true data files and station info files
    # drop the BBCH and README data (but don't delete it - delist)
    data_file = pep_files[!grepl("stations",pep_files)]
    station_file = pep_files[grepl("stations",pep_files)]

    # unzip only the selected files into the output path
    # use path.expand to deal with the fact that untar
    # does not work with relative paths
    untar(file,
          files = pep_files,
          exdir = path.expand(tmpdir))

    # read in observation data from a particular gziped file
    observation_data = utils::read.csv2(sprintf("%s/%s",tmpdir,data_file),
                                        sep = ";",
                                        stringsAsFactors = FALSE)
    observation_data$country = substr(data_file,8,9)
    observation_data$species = sub("_"," ",substr(data_file,11,nchar(data_file)-4))

    station_locations = utils::read.csv2(sprintf("%s/%s",tmpdir,station_file),
                                         sep = ";",
                                         stringsAsFactors = FALSE,
                                         skip = 1,
                                         header = FALSE)

    # discard any columns > 6 (errors in NAME field)
    if(ncol(station_locations) > 6){
      station_locations = station_locations[,-c(7:ncol(station_locations))]
    }

    # manually assign column names to avoid errors with malformed data
    colnames(station_locations) = c("PEP_ID",
                                    "National_ID",
                                    "LON",
                                    "LAT",
                                    "ALT",
                                    "NAME")
    # convert to numeric
    station_locations$LON = as.numeric(station_locations$LON)
    station_locations$LAT = as.numeric(station_locations$LAT)

    # do a left merge to combine the observational data and the
    # station location meta-data returning basically the original
    # database structure (as a tidy file)
    pep_data = merge(observation_data, station_locations, by = "PEP_ID")
    names(pep_data) = tolower(names(pep_data))

    # cleanup extracted data for good measure
    # and return the combined data frame
    file.remove(paste(tmpdir,pep_files,sep = "/"))
    return(pep_data)
  }))
}
