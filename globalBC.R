repos <- c("predictiveecology.r-universe.dev", getOption("repos"))
options(repos = repos)
# install.packages("SpaDES.project")   ## gets Require too

# unlike many modules, scfm is a 'meta'module that consists of 6 core modules:
# scfmLandcoverInit for initializing landcover and fire regime polys of study area
# scfmRegime for characteristics of the fire regimes (e.g. years of NFDB data),
# scfmDriver for calibrating the spread probability
# scfmIgnition, Escape, and Spread for simulatign the 3-stage model
# the parameters for each must be set separately:

out <- SpaDES.project::setupProject(
  updateRprofile = TRUE,
  name = "scfm_example",
  useGit = FALSE,
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
    file.path("PredictiveEcology/scfm@development/modules/",
              c("scfmLandcoverInit", "scfmRegime", "scfmDriver",
                "scfmIgnition", "scfmEscape", "scfmSpread", "scfmDiagnostics"))
  ),
  params = list(
    .globals = list(.studyAreaName = "scfm_example",
                    dataYear = 2011,
                    sppEquivCol = "LandR"),
    scfmDriver = list(targetN = 2000, #default is 4000 - more adds time + precision
                      .useParallelFireRegimePolys = FALSE) #requires snow
  ),
  options = list(spades.allowInitDuringSimInit = TRUE,
                 spades.moduleCodeChecks = FALSE,
                 reproducible.shapefileRead = "terra::vect",
                 spades.recoveryMode = 1
  ),
  times = list(start = 2011, end = 2311),
  sppEquiv = LandR::sppEquivalencies_CA[KNN %in% c("Popu_Tre", "Betu_Pap",
                                                   "Pice_Gla", "Pice_Mar",
                                                    "Pinu_Con", "Pinu_Ban")],
  studyArea = {
    sa = terra::vect("D:/Ian/Data/RIA/RIA_fiveTSA.shp") |>
      terra::aggregate(dissolve = TRUE, by = NULL)
    return(sa)
  },
  studyAreaLarge = {
    sa = terra::buffer(studyArea, 20000)
    return(sa)
  },
  studyAreaReporting = {
    sa = terra::buffer(studyArea, -2000)
    return(sa)
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

pkgload::load_all("D:/Ian/Git/scfmutils") #for driver fixes
outSim <- do.call(SpaDES.core::simInitAndSpades, out)
