#' Build a site map of WQP sites or ECHO facilities
#' 
#' Build a map of sample sites, facilities, or both. Map includes sites, beneficial use and assessment unit polygons, and satellite and topo baselayers.
#' This is designed to work with column names as extracted from WQP or ECHO via udwqTools functions readWQP() and readECHO_fac(). Map will launch in default browser (or R-Studio's browser if using R-Studio).
#' Site and assessment unit features are searchable by idetifier and name via the search button on the left side of the map.
#' The most recently turned on layer is "on top" of the map. Only features on top will show their pop-up on click.
#' @param fac Facility locations queried via readECHO_fac.
#' @param sites Site locations queried via readWQP(type="sites"). May also be a data file with WQP site information merged to it.
#' @param au_poly Optional. Polygon file to be mapped as assessment units. Useful for mapping a subset of specific assessment units. If missing, the default state wide AU polygon is used.
#' @param bu_poly Optional. Polygon file to be mapped as beneficial uses. Useful for mapping a subset of beneficial uses. If missing, the default state wide uses polygon is used.
#' @param ss_poly Optional. Polygon file to be mapped as site specific standards. Useful for mapping a subset of ss polygons. If missing, the default state wide ss polygon is used.
#' @import leaflet
#' @importFrom leaflet.extras addSearchFeatures
#' @importFrom RColorBrewer brewer.pal
#' @importFrom sf st_centroid
#' @importFrom sf st_coordinates
#' @examples
#' # Read sites & facility locations
#' jr_sites=readWQP(type="sites",
#' 	siteid=c("UTAHDWQ_WQX-4994100","UTAHDWQ_WQX-4994120","UTAHDWQ_WQX-4991860",
#' 			 "UTAHDWQ_WQX-4994190","UTAHDWQ_WQX-4994172","UTAHDWQ_WQX-4994090",
#' 			 "UTAHDWQ_WQX-4992890","UTAHDWQ_WQX-4992880","UTAHDWQ_WQX-4992480",
#' 			 "UTAHDWQ_WQX-4992055","UTAHDWQ_WQX-4991940","UTAHDWQ_WQX-4991880"))		 
#' jr_fac=readECHO_fac(p_pid=c("UT0024392","UT0024384","UT0025852","UT0021725"))
#' #Build some maps
#' map1=buildMap(sites=jr_sites, fac=jr_fac) #define new object for use later
#' map1 #call generated map object to launch in browser
#' buildMap(sites=mantua_sites) #just sites, launch w/o generating map object in workspace
#' buildMap(fac=jr_fac) #just facilities
#' buildMap() #Build an empty map w/ just AU, BU, and SS std polys
#' #html maps can be saved via htmlwidgets package saveWidget(map1, file="your/path/map1.html")

#' @export
buildMap=function(fac, sites, au_poly, bu_poly, ss_poly){
	
	if(missing(au_poly)){get(data("au_poly", envir = environment()))}
	if(missing(bu_poly)){get(data("bu_poly", envir = environment()))}
	if(missing(ss_poly)){get(data("ss_poly", envir = environment()))}
	au_centroids=suppressWarnings(sf::st_centroid(au_poly))
	au_centroids=cbind(au_centroids,sf::st_coordinates(au_centroids))
	
	if(missing(fac) & missing(sites)){
		print("Building map w/o sites or facilities...")
		#Build empty map
		
		map=leaflet::leaflet(au_poly)
			map=leaflet::addProviderTiles(map, "Esri.WorldTopoMap", group = "Topo")
			map=leaflet::addProviderTiles(map,"Esri.WorldImagery", group = "Satellite")
			map=leaflet::addCircles(map, lat=au_centroids$Y, lng=au_centroids$X, group="au_names", label=au_centroids$AU_NAME, stroke=F, fill=F,
				popup = paste0(
					"AU ID: ", au_centroids$ASSESS_ID,
					"<br> AU Name: ", au_centroids$AU_NAME,
					"<br> AU Type: ", au_centroids$AU_Type))
			map=leaflet::addCircles(map, lat=au_centroids$Y, lng=au_centroids$X, group="au_ids", label=au_centroids$ASSESS_ID, stroke=F, fill=F,
				popup = paste0(
					"AU name: ", au_centroids$AU_NAME,
					"<br> AU ID: ", au_centroids$ASSESS_ID,
					"<br> AU type: ", au_centroids$AU_Type))
			map=addPolygons(map, data=bu_poly,group="Beneficial uses",smoothFactor=4,fillOpacity = 0.1,weight=3,color="green",
				popup=paste0(
					"Description: ", bu_poly$R317Descrp,
					"<br> Uses: ", bu_poly$bu_class)
				)
			map=addPolygons(map, data=au_poly,group="Assessment units",smoothFactor=4,fillOpacity = 0.1,weight=3,color="orange",
				popup=paste0(
					"AU name: ", au_poly$AU_NAME,
					"<br> AU ID: ", au_poly$ASSESS_ID,
					"<br> AU type: ", au_poly$AU_Type)
				)
			map=addPolygons(map, data=ss_poly,group="Site-specific standards",smoothFactor=4,fillOpacity = 0.1,weight=3,color="blue",
				popup=paste0("SS std: ", ss_poly$SiteSpecif)
				)
			map=leaflet::addLayersControl(map,
				position ="topleft",
				baseGroups = c("Topo","Satellite"),overlayGroups = c("Assessment units","Beneficial uses", "Site-specific standards"),
				options = leaflet::layersControlOptions(collapsed = FALSE, autoZIndex=FALSE))
			map=hideGroup(map, "Assessment units")
			map=hideGroup(map, "Site-specific standards")
			map=hideGroup(map, "Beneficial uses")
			#map=addControl(map, "<P><B>Search</B>", position='topleft')
			map=leaflet.extras::addSearchFeatures(map,
				targetGroups = c('au_ids','au_names'),
				options = leaflet.extras::searchFeaturesOptions(
				zoom=12, openPopup = TRUE, firstTipSubmit = TRUE,
				autoCollapse = TRUE, hideMarkerOnCollapse = TRUE ))
			map=leaflet::addMeasure(map, position="bottomleft")

	}else{
		if(!missing(sites)){
			site_coords=sites[,c("MonitoringLocationIdentifier","MonitoringLocationName","MonitoringLocationTypeName","LatitudeMeasure","LongitudeMeasure")]
			names(site_coords)[names(site_coords)=="MonitoringLocationIdentifier"]="locationID"
			names(site_coords)[names(site_coords)=="MonitoringLocationName"]="locationName"
			names(site_coords)[names(site_coords)=="MonitoringLocationTypeName"]="locationType"
			site_coords=sf::st_as_sf(site_coords, coords=c("LongitudeMeasure","LatitudeMeasure"), crs=4326, remove=F)
		}
		if(!missing(fac)){
			fac_coords=do.call(rbind.data.frame,fac$geometry$coordinates)
			names(fac_coords)=c("dec_long","dec_lat")
			fac_coords=data.frame(fac$properties[,c("SourceID","CWPName","CWPFacilityTypeIndicator")], (fac_coords))
			names(fac_coords)[names(fac_coords)=="SourceID"]="locationID"
			names(fac_coords)[names(fac_coords)=="CWPName"]="locationName"
			names(fac_coords)[names(fac_coords)=="CWPFacilityTypeIndicator"]="locationType"
			names(fac_coords)[names(fac_coords)=="dec_long"]="LongitudeMeasure"
			names(fac_coords)[names(fac_coords)=="dec_lat"]="LatitudeMeasure"
			fac_coords=sf::st_as_sf(fac_coords, coords=c("LongitudeMeasure","LatitudeMeasure"), crs=4326, remove=F)
		}
	
		if(exists('site_coords')){
			if(exists('fac_coords')){
				locs=rbind(site_coords,fac_coords)
				}else{locs=site_coords}
		}else{
			locs=fac_coords
			}
	
	
		#Color palette for points
		
		pal <- colorRampPalette(RColorBrewer::brewer.pal(11, "Spectral"))
		pal=leaflet::colorFactor(pal(length(unique(locs$locationType))), domain = locs$locationType)
		
		#Build map
		
		map=leaflet::leaflet(locs)
			map=leaflet::addProviderTiles(map, "Esri.WorldTopoMap", group = "Topo")
			map=leaflet::addProviderTiles(map,"Esri.WorldImagery", group = "Satellite")
			map=leaflet::addCircleMarkers(map, lat=locs$LatitudeMeasure, lng=locs$LongitudeMeasure, group="Sites", color = pal(locs$locationType), opacity=0.8,
				popup = paste0(
					"Location ID: ", locs$locationID,
					"<br> Name: ", locs$locationName,
					"<br> Type: ", locs$locationType,
					"<br> Lat: ", locs$LatitudeMeasure,
					"<br> Long: ", locs$LongitudeMeasure))
			map=leaflet::addCircles(map, lat=au_centroids$Y, lng=au_centroids$X, group="au_names", label=au_centroids$AU_NAME, stroke=F, fill=F,
				popup = paste0(
					"AU ID: ", au_centroids$ASSESS_ID,
					"<br> AU Name: ", au_centroids$AU_NAME,
					"<br> AU Type: ", au_centroids$AU_Type))
			map=leaflet::addCircles(map, lat=au_centroids$Y, lng=au_centroids$X, group="au_ids", label=au_centroids$ASSESS_ID, stroke=F, fill=F,
				popup = paste0(
					"AU name: ", au_centroids$AU_NAME,
					"<br> AU ID: ", au_centroids$ASSESS_ID,
					"<br> AU type: ", au_centroids$AU_Type))
			map=leaflet::addCircles(map, lat=locs$LatitudeMeasure, lng=locs$LongitudeMeasure, group="locationID", label=locs$locationID, stroke=F, fill=F,
				popup = paste0(
					"Location ID: ", locs$locationID,
					"<br> Name: ", locs$locationName,
					"<br> Type: ", locs$locationType,
					"<br> Lat: ", locs$LatitudeMeasure,
					"<br> Long: ", locs$LongitudeMeasure))
			map=leaflet::addCircles(map, lat=locs$LatitudeMeasure, lng=locs$LongitudeMeasure, group="locationName", label=locs$locationName, stroke=F, fill=F,
				popup = paste0(
					"Location ID: ", locs$locationID,
					"<br> Name: ", locs$locationName,
					"<br> Type: ", locs$locationType,
					"<br> Lat: ", locs$LatitudeMeasure,
					"<br> Long: ", locs$LongitudeMeasure))
			map=leaflet::addLabelOnlyMarkers(map, group="Labels", lat=locs$LatitudeMeasure, lng=locs$LongitudeMeasure,
				label=locs$locationID,labelOptions = leaflet::labelOptions(noHide = T, textsize = "15px"),
				clusterOptions=leaflet::markerClusterOptions(spiderfyOnMaxZoom=T))
			map=addPolygons(map, data=bu_poly,group="Beneficial uses",smoothFactor=4,fillOpacity = 0.1,weight=3,color="green",
				popup=paste0(
					"Description: ", bu_poly$R317Descrp,
					"<br> Uses: ", bu_poly$bu_class)
				)
			map=addPolygons(map, data=au_poly,group="Assessment units",smoothFactor=4,fillOpacity = 0.1,weight=3,color="orange",
				popup=paste0(
					"AU name: ", au_poly$AU_NAME,
					"<br> AU ID: ", au_poly$ASSESS_ID,
					"<br> AU type: ", au_poly$AU_Type)
				)
			map=addPolygons(map, data=ss_poly,group="Site-specific standards",smoothFactor=4,fillOpacity = 0.1,weight=3,color="blue",
				popup=paste0("SS std: ", ss_poly$SiteSpecif)
				)
			map=leaflet::addLayersControl(map,
				position ="topleft",
				baseGroups = c("Topo","Satellite"),overlayGroups = c("Sites","Labels","Assessment units","Beneficial uses", "Site-specific standards"),
				options = leaflet::layersControlOptions(collapsed = FALSE, autoZIndex=FALSE))
			map=leaflet::addLegend(map, position = 'topright',
				colors = unique(pal(locs$locationType)), 
				labels = unique(locs$locationType))
			map=hideGroup(map, "Assessment units")
			map=hideGroup(map, "Site-specific standards")
			map=hideGroup(map, "Beneficial uses")
			#map=addControl(map, "<P><B>Search</B>", position='topleft')
			map=addSearchFeatures(map,
				targetGroups = c('au_ids','au_names','locationID','locationName'),
				options = leaflet.extras::searchFeaturesOptions(
				zoom=12, openPopup = TRUE, firstTipSubmit = TRUE,
				autoCollapse = TRUE, hideMarkerOnCollapse = TRUE ))
			map=leaflet::addMeasure(map, position="bottomleft")
	}
	
return(map)

}

