repos <- c("predictiveecology.r-universe.dev", getOption("repos"))
options(repos = repos)
install.packages("SpaDES.project")   ## gets Require too

# unlike many modules, scfm is a 'meta'module that consists of 6 core modules:
# scfmLandcoverInit for initializing landcover and fire regime polys of study area
# scfmRegime for characteristics of the fire regimes (e.g. years of NFDB data),
# scfmDriver for calibrating the spread probability
# scfmIgnition, Escape, and Spread for simulatign the 3-stage model
# the parameters for each must be set separately:

out <- SpaDES.project::setupProject(
  updateRprofile = TRUE,
  name = "scfm_example_essef",
  useGit = FALSE,
  require = c("PredictiveEcology/LandR@development (>= 1.1.1.9001)"),
  paths = list(projectPath = getwd(),
               modulePath = file.path("modules"),
               cachePath = file.path("cache"),
               scratchPath = tempdir(),
               inputPath = file.path("inputs"),
               outputPath = file.path("outputs")
  ),
  modules = c(
    "PredictiveEcology/Biomass_borealDataPrep@development",
    "PredictiveEcology/Biomass_core@development",
    "PredictiveEcology/Biomass_regeneration@development",
    "PredictiveEcology/scfm@essefication"
  ),
  options = list(spades.allowInitDuringSimInit = TRUE,
                 spades.moduleCodeChecks = FALSE,
                 reproducible.shapefileRead = "terra::vect",
                 spades.recoveryMode = 1
  ),
  times = list(start = 2011, end = 2021),
  sppEquiv = LandR::sppEquivalencies_CA[KNN %in% c("Popu_Tre", "Betu_Pap",
                                                   "Pice_Gla", "Pice_Mar",
                                                    "Pinu_Con", "Pinu_Ban")],
  studyArea = {
    targetCRS <- paste("+proj=lcc +lat_1=49 +lat_2=77 +lat_0=0 +lon_0=-95 +x_0=0 +y_0=0",
                       "+datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0")
    sa <- terra::vect(cbind(-1209980, 7586865), crs = targetCRS)
    sa <- LandR::randomStudyArea(center = sa, size = 10000 * 250 * 30000, seed = 1002)
    sa <- sf::st_as_sf(sa)
  },
  studyAreaLarge = {
    sf::st_buffer(studyArea, 20000)
  },
  rasterToMatchLarge = {
    rtml<- terra::rast(terra::ext(studyAreaLarge), res = c(250, 250))
    terra::crs(rtml) <- terra::crs(studyAreaLarge)
    rtml[] <- 1
    rtml <- terra::mask(rtml, studyAreaLarge)
  },
  rasterToMatch = {
    rtm <- terra::crop(rasterToMatchLarge, studyArea)
    rtm <- terra::mask(rtm, studyArea)
  }
)

#this must be done outside of setupProject (temporarily)
#alternatively
out$paths$modulePath <- c(file.path("modules"),
                          file.path("modules/scfm/modules"))
out$modules <- c("scfmLandcoverInit", "scfmRegime", "scfmDriver",
                 "scfmIgnition", "scfmEscape", "scfmSpread",
                 "scfmDiagnostics",
                 "Biomass_core", "Biomass_borealDataPrep", "Biomass_regeneration")
out$params = list(
  .globals = list(.studyAreaName = "scfm_example",
                  dataYear = 2011,
                  sppEquivCol = "LandR"),
  scfmDriver = list(targetN = 3000, #default is 4000 - more adds time + precision
                    .useParallelFireRegimePolys = 4) #requires snow
)

outSim <- do.call(SpaDES.core::simInitAndSpades, out)
