#' Assign Utah assessment units to sites
#'
#' This function assigns assessment units to water quality portal type site objects (or data with site information attached). This can be done before or after assigning beneficial uses.
#' @param data Input dataset. Must include latitude & longitude columns.
#' @param lat Name of latitude column. Default matches WQP objects.
#' @param long Name of longitude column. Default matches WQP objects.
#' @importFrom sf st_as_sf
#' @importFrom sf st_set_crs
#' @importFrom sf st_join
#' @examples 
#' # Read a couple of sites (Mantua Reservoir and a tributary)
#' sites=readWQP(type="sites", siteid=c("UTAHDWQ_WQX-4900440","UTAHDWQ_WQX-4900470"))
#' sites_AUs=assignAUs(sites)
#' @return Returns the input data frame with assessment unit information appended.
#' @export
assignAUs=function(data, lat="LatitudeMeasure", long="LongitudeMeasure"){
	poly=wqTools::au_poly
	poly=poly[,c("AU_NAME","ASSESS_ID","AU_DESCRIP","AU_Type")]
	x=data
	x=sf::st_as_sf(x, coords=c(long,lat), crs=4326, remove=F)
	x=sf::st_set_crs(x, sf::st_crs(poly))	
	isect=suppressMessages({suppressWarnings({sf::st_join(x, poly, left=TRUE)})})
	sf::st_geometry(isect)=NULL
	return(isect)
}
