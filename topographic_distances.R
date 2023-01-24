#############################
### Topographic distances ###
#############################

#----------------------------
# Setup #
rm(list = ls(all.names = TRUE)) 
gc()

library("googlesheets4")
gs4_auth(
  email = "fequezad@ucsc.edu",
  path = NULL,
  scopes = "https://www.googleapis.com/auth/spreadsheets",
  cache = gargle::gargle_oauth_cache(),
  use_oob = gargle::gargle_oob_default(),
  token = NULL)

# load packages #

# Required libraries
library(rasterVis)
library(raster)
library(rgl)
library(rgdal)
library(elevatr)
library(topoDistance)
library(foreign)

# sp_df <- shapefile("C:/Users/fequezad/OneDrive/UMass/Dissertation/02 TURFs Chile/TopoDist/srtm_v3_63cae2de2b67356d/srtm_v3_63cae2de2b67356d.shp") 
chile_bound <- rgeoboundaries::geoboundaries("Chile")
elevation <- elevatr::get_elev_raster(locations = chile_bound, z = 4, clip = "bbox", expand = 1)

## Calculate topographic distances from port of jurisdiction and TURFs.
cord_navy <- read.csv(file ="C:/Users/fequezad/OneDrive/UMass/Dissertation/02 TURFs Chile/Data/Coordenadas/Capitanias de puerto/Navy_coordinates.csv")
cord_turf <- read.csv(file ="C:/Users/fequezad/OneDrive/UMass/Dissertation/02 TURFs Chile/Data/Coordenadas/AMERB/AMERB_coordinates_csv_id.csv")
link_navy_turf <- read.csv(file ="C:/Users/fequezad/OneDrive/UMass/Dissertation/02 TURFs Chile/Data/Coordenadas/AMERB/AMERB_id_and_id_navy_j.csv")

## Clean databases
link_navy_turf <- link_navy_turf %>% unique() %>% tidyr::drop_na()
cord_navy_j <- cord_navy %>% 
  dplyr::select(c('xcoord', 'ycoord', 'id_navy')) %>% 
  dplyr::rename(id_navy_j = id_navy) %>% 
  dplyr::rename(xcoord_j = xcoord) %>% 
  dplyr::rename(ycoord_j = ycoord) %>% 
  tidyr::drop_na() 

cord_turf <- cord_turf %>% 
  dplyr::select(c('xcoord', 'ycoord', 'id_area')) %>% 
  unique() %>% 
  tidyr::drop_na() 

df <- cord_turf %>% 
  merge(link_navy_turf, by = "id_area", all.x = TRUE, all.y = TRUE) %>%
  merge(cord_navy_j, by = "id_navy_j", all.x = TRUE, all.y = TRUE) %>% 
  tidyr::drop_na()

# # # Plot elevation
# bbox <- sf::st_bbox(c(xmin = -73.8, ymin = -42.5, xmax = -73, ymax = -41.65))
# elevation_bbox = crop(elevation, bbox)
# chile_bound_bbox = sf::st_crop(chile_bound, bbox)
# cord_navy_sf <- sf::st_as_sf(x = cord_navy_j,
#                coords = c("xcoord_j", "ycoord_j"))
# cord_navy_bbox = sf::st_crop(cord_navy_sf, bbox)
# cord_navy_data <- as.data.frame(sf::as_Spatial(cord_navy_bbox)) %>%
#   dplyr::select('coords.x1', 'coords.x2', id_navy_j) %>%
#   dplyr::rename(id = id_navy_j) %>%
#   dplyr::mutate(type = "Port captainship")
# cord_turf_sf <- sf::st_as_sf(x = cord_turf,
#                              coords = c("xcoord", "ycoord"))
# cord_turf_bbox = sf::st_crop(cord_turf_sf, bbox)
# cord_turf_data <- as.data.frame(sf::as_Spatial(cord_turf_bbox)) %>%
#   dplyr::rename(id = id_area) %>%
#   dplyr::mutate(type = "TURF")
# coord_data = rbind(cord_turf_data, cord_navy_data)
# 
# elevation_data <- as.data.frame(elevation_bbox, xy = TRUE)
# colnames(elevation_data)[3] <- "elevation"
# # remove rows of data frame with one or more NA's,using complete.cases
# # elevation_data <- elevation_data[complete.cases(elevation_data), ]
# 
# 
# library(ggplot2)
# ggplot() +
#   geom_raster(data = elevation_data, aes(x = x, y = y, fill = elevation)) +
#   geom_sf(data = chile_bound_bbox, color = "grey35", fill = NA) +
#   coord_sf() +
#   scale_fill_viridis_c() +
#   geom_point(data = coord_data, aes(x = coords.x1, y = coords.x2, colour = type, shape = type), size = 3) +
#   labs(x = "Longitude", y = "Latitude", fill = "Elevation (meters)",
#        color = "Point coordinate type",  shape = "Point coordinate type")


df_dist <- tibble::tibble(id_area = integer(),
                  td_navyj_km_4 = numeric())

for (j in 1:nrow(df)) {
  gc()
  xy <- matrix(ncol = 2, byrow = TRUE,
               c(df$xcoord[j], df$ycoord[j], 
                 df$xcoord_j[j], df$ycoord_j[j]))
  colnames(xy) <- c("longitude", "latitude")
  tdist <- topoDist(elevation, xy, paths = FALSE)
  
  df_dist <- df_dist %>%
    tibble::add_row(id_area = as.integer(df[j, 2]),
            td_navyj_km_4 = as.numeric(tdist[1,2]/1000))
  rm(xy, tdist)
  perc <- (j/nrow(df))*100
  print(paste("Row = ",j))
  print(paste(perc,"%"))
  write.csv(df_dist,"C:/Users/fequezad/OneDrive/UMass/Dissertation/02 TURFs Chile/TopoDist/data_td4.csv", row.names = FALSE)
}

rm(df_dist, df, j)