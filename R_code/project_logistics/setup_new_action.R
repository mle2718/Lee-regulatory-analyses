# R script to create folders for a project

action<-"Framework9"

# Setup directories for R_code
dir.create(file.path("R_code",action), recursive=TRUE)
dir.create(file.path("R_code",action,"data_extraction_processing"), recursive=TRUE)


# Setup directories for data
dir.create(file.path("data_folder", "external",action),  recursive=TRUE)
dir.create(file.path("data_folder", "main",action),  recursive=TRUE)
dir.create(file.path("data_folder", "internal",action),  recursive=TRUE)
dir.create(file.path("data_folder", "raw",action),  recursive=TRUE)
dir.create(file.path("data_folder", "intermediate",action),  recursive=TRUE)

# Setup directories for stata_code
dir.create(file.path("stata_code", action),  recursive=TRUE)
dir.create(file.path("stata_code", action, "data_extraction_processing"),  recursive=TRUE)
dir.create(file.path("stata_code", action, "analysis"),  recursive=TRUE)

# Setup directories for tables, images, and results
dir.create(file.path("tables", action),  recursive=TRUE)
dir.create(file.path("images", action), recursive=TRUE)
dir.create(file.path("results", action),recursive=TRUE)