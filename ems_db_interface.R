library(RMySQL)

get_artist_name <- function(artist_id){
	
	db <- dbConnect(MySQL(), host = 'localhost', user = 'root', db = 'ems')
	
	
	artist_name <- dbGetQuery(db, 
		paste('SELECT name FROM artists_info WHERE id = ', artist_id))$name
	
	dbDisconnect(db)
	
	return(artist_name)
	
}

get_dataset_name <- function(dataset_id){
	
	db <- dbConnect(MySQL(), host = 'localhost', user = 'root', db = 'ems')
	
	
	dataset_name <- dbGetQuery(db, 
		paste('SELECT name FROM datasets WHERE id = ', dataset_id))$name
	
	dbDisconnect(db)
	
	return(dataset_name)

	
}

get_artists_in_datasets <- function(){
	
	db <- dbConnect(MySQL(), host = 'localhost', user = 'root', db = 'ems')
	
	
	query = 'SELECT DISTINCT albums_artists.artist_id FROM excerpts_datasets 
		INNER JOIN excerpts ON excerpts_datasets.excerpt_id = excerpts.id 
		INNER JOIN albums_artists ON albums_artists.album_id = excerpts.album_id'
	
	artists_ids <- dbGetQuery(db,query)$artist_id	
	dbDisconnect(db)
	
	return(artists_ids)
	
}

get_descriptors <- function(dataset_ids = NULL){
	
	db <- dbConnect(MySQL(), host = 'localhost', user = 'root', db = 'ems')
	
	if(is.null(dataset_ids)){
		all <- dbReadTable(db, 'excerpts_descriptors')
	}
	else{
		
		query <- 'SELECT edesc.* FROM excerpts_descriptors edesc INNER JOIN excerpts_datasets edata ON edesc.excerpt_id = edata.excerpt_id WHERE '
		
		count = 1
		
		for (id in dataset_ids){
			
			query <- paste(query, 'edata.dataset_id = ', id, sep = '')
			if(count < length(dataset_ids)){
				query <- paste(query, ' OR ')
				count <- count + 1
			}
			
		}
		
		all <- dbGetQuery(db, query)
		
	}
	
	desc_with_na <- names(all[, colMeans(is.na(all)) != 0])
	descriptors <- names(all)[2:length(names(all))]
	descriptors <- subset(descriptors, ! descriptors %in% desc_with_na)
	
	rm(all)
	
	dbDisconnect(db)
	
	return(descriptors)
	
	
}

get_descriptor_range <- function(descriptor){
	
	db <- dbConnect(MySQL(), host = 'localhost', user = 'root', db = 'ems')
	
	min_str <- paste('min(', descriptor, ')', sep = '')
	max_str <- paste('max(', descriptor, ')', sep = '')
		
	query <- paste('SELECT ', min_str, ', ', max_str, ' FROM excerpts_descriptors', sep = '')
		
	res <- dbGetQuery(db, query)		
	
	range <- data.frame(min = res[[min_str]], max = res[[max_str]])
	
	dbDisconnect(db)
	

	
	return(range)

	
}

get_dataset <- function(dataset_ids, descriptors = NULL, no_nas = TRUE){
	
	db <- dbConnect(MySQL(), host = 'localhost', user = 'root', db = 'ems')
	
	query <- paste('SELECT albums_artists.*, excerpts_descriptors.* FROM excerpts_descriptors INNER JOIN excerpts ON excerpts_descriptors.excerpt_id  = excerpts.id INNER JOIN albums_artists ON excerpts.album_id = albums_artists.album_id INNER JOIN excerpts_datasets ON excerpts.id = excerpts_datasets.excerpt_id')
	
	if(!is.null(dataset_ids)){
		query <- paste(query, ' WHERE ')
		
		count = 1
		
		for (id in dataset_ids){
			
			query <- paste(query, 'dataset_id = ', id, sep = '')
			if(count < length(dataset_ids)){
				query <- paste(query, ' OR ')
				count <- count + 1
			}
		}	
	}

	dataset <- dbGetQuery(db, query)

	if(is.null(descriptors)){
		
		if(no_nas){
		
			descriptors <- get_descriptors()
		}
		else{
			
			descriptors <- get_descriptors(dataset_ids)
		}
	}

	dataset <- dataset[, c('excerpt_id', 'artist_id', 'album_id', descriptors)]
	dataset <- dataset[order(dataset$excerpt_id),]
	row.names(dataset) <- dataset$excerpt_id
	
	comb <- as.data.frame(combn(unique(dataset$artist_id),2))
	for(i in 1:ncol(comb)){
		if(check_alias(comb[1,i], comb[2,i])){
			dataset[which(dataset$artist_id == comb[1,i]), 'artist_id'] <- comb[2,i]
		}
	}
	
	dbDisconnect(db)
	return(dataset)
	
}

get_path <- function(excerpt_id){
	
	db <- dbConnect(MySQL(), host = 'localhost', user = 'root', db = 'ems')
	
	query <- paste('SELECT path FROM excerpts WHERE id = ' , excerpt_id)

	path <- dbGetQuery(db, query)$path
	
	dbDisconnect(db)
	return(path)
	
	
}

check_alias <- function(artist_1, artist_2){
	
	db <- dbConnect(MySQL(), host = 'localhost', user = 'root', db = 'ems')
	
	query <- paste('SELECT alias_main_id FROM artists_aliases WHERE alias_artist_id = ' , artist_1, ' AND alias_main_id = ', artist_2)


	main <- dbGetQuery(db, query)$alias_main_id
	
	dbDisconnect(db)
	
	if(length(main) > 0){return(TRUE)}
	return(FALSE)
	
}