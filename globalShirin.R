
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
  paths = list(projectPath = getwd(),
               modulePath = file.path("modules"),
               cachePath = file.path("cache"),
               scratchPath = tempdir(),
               inputPath = file.path("inputs"),
               outputPath = file.path("outputs", "scfm_ON")
  ),
  modules = c(
    "PredictiveEcology/Biomass_borealDataPrep@development",
    "PredictiveEcology/Biomass_core@development",
    "PredictiveEcology/Biomass_regeneration@development",
    file.path("PredictiveEcology/scfm@rm_SAL/modules/",
              c("scfmLandcoverInit", "scfmRegime", "scfmDriver",
                "scfmIgnition", "scfmEscape", "scfmSpread", "scfmDiagnostics"))
  ),
  params = list(
    .globals = list(.studyAreaName = "scfm_ON",
                    dataYear = 2011,
                    sppEquivCol = "LandR"),
    scfmDriver = list(targetN = 2000, #default is 4000 - more adds time + precision
                      .useParallelFireRegimePolys = TRUE) #requires snow
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
  functions = "R/study_area_fun.R", #Make SURE THIS IS WHERE YOU SAVED THE FUNCTIONS FILE!
  studyArea = studyAreaFun()$studyArea,
  rasterToMatch = studyAreaFun()$rasterToMatch,
  studyAreaLarge = studyAreaFun()$studyArea,
  rasterToMatchLarge = studyAreaFun()$rasterToMatch,
  studyAreaPSP =  studyAreaPSPFun(),
  studyAreaANPP = studyAreaANPPFun(),
  sppEquiv = shirinSppEquivFun(),
  useGit = TRUE
)

outSim <- do.call(SpaDES.core::simInitAndSpades, out)

