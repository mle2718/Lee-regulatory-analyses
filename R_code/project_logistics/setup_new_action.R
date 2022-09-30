# R script to create folders for a project
library(here)
my_projdir<- here::i_am("R_code/project_logistics/setup_new_action.R")

action<-"SIR2023_2026"
# Setup directories for R_code
dir.create(here(action,"R_code"), recursive=TRUE)
dir.create(here(action,"R_code","data_extraction_processing"), recursive=TRUE)


# Setup directories for data
dir.create(here(action,"data_folder", "external"),  recursive=TRUE)
dir.create(here(action,"data_folder", "main"),  recursive=TRUE)
dir.create(here(action,"data_folder", "internal"),  recursive=TRUE)
dir.create(here(action,"data_folder", "raw"),  recursive=TRUE)
dir.create(here(action,"data_folder", "intermediate"),  recursive=TRUE)

# Setup directories for stata_code
dir.create(here(action,"stata_code"),  recursive=TRUE)
dir.create(here(action,"stata_code", "data_extraction_processing"),  recursive=TRUE)
dir.create(here(action,"stata_code", "analysis"),  recursive=TRUE)

# Setup directories for tables, images, and results
dir.create(here(action,"tables"),  recursive=TRUE)
dir.create(here(action,"images"), recursive=TRUE)
dir.create(here(action,"results"),recursive=TRUE)