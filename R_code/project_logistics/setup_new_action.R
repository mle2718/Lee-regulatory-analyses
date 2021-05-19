# R script to create folders for a project

action<-"FW9_Rebuild_AM"

# Setup directories for R_code
dir.create(file.path(action,"R_code"), recursive=TRUE)
dir.create(file.path(action,"R_code","data_extraction_processing"), recursive=TRUE)


# Setup directories for data
dir.create(file.path(action,"data_folder", "external"),  recursive=TRUE)
dir.create(file.path(action,"data_folder", "main"),  recursive=TRUE)
dir.create(file.path(action,"data_folder", "internal"),  recursive=TRUE)
dir.create(file.path(action,"data_folder", "raw"),  recursive=TRUE)
dir.create(file.path(action,"data_folder", "intermediate"),  recursive=TRUE)

# Setup directories for stata_code
dir.create(file.path(action,"stata_code"),  recursive=TRUE)
dir.create(file.path(action,"stata_code", "data_extraction_processing"),  recursive=TRUE)
dir.create(file.path(action,"stata_code", "analysis"),  recursive=TRUE)

# Setup directories for tables, images, and results
dir.create(file.path(action,"tables"),  recursive=TRUE)
dir.create(file.path(action,"images"), recursive=TRUE)
dir.create(file.path(action,"results"),recursive=TRUE)