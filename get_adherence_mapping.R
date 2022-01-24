###########################################
# Script to get adherence mapping of a study
##########################################
library(bridgeclient)
library(synapser)
library(tidyverse)
source("bridge_helper.R")
synapser::synLogin()

#' log in to bridge using bridgeclient
bridgeclient::bridge_login(
    study = "arc",
    credentials_file = ".bridge_creds")

#' Function to get studies mapping
#' @return bridge study name and their id 
get_studies_mapping <- function(){
    bridgeclient_get_studies() %>%
        .$items %>% 
        purrr::map_dfr(function(x){
            tibble::tibble(
                name = x$name, 
                id = x$id)}) %>%
        dplyr::select(
            study_name = name,
            study_id = id)
}

#' Function to get user enrollments using study id
#' @param data dataframe with study_id
#' @return return bridge enrollment response
get_user_enrollments <- function(data){
    data %>%
        dplyr::mutate(enrollments = purrr::map(
            study_id, bridgeclient::get_all_enrollments))
}

#' Function to get user IDs of enrollment
#' @param data dataframe with enrollment API return
#' @return return mapped user id
get_user_ids <- function(data){
    data %>% 
        dplyr::mutate(user_ids = purrr::map(enrollments, function(enrollment){
            enrollment %>% 
                purrr::map_dfr(function(x){
                    tibble::tibble(user_id = x$participant$identifier)
                })
        })) %>% 
        tidyr::unnest(user_ids, names_repair = "minimal")
}

#' Function to get Bridge Adherence
#' @param data dataframe with study_id and user_id
#' @return Bridge adherence data
get_adherence <- function(data){
    data %>% 
        dplyr::mutate(adherence = purrr::pmap(
            select(., study_id, user_id), bridgeclient_get_adherence))
}

#' Function to get metadata of adherence data
#' e.g: activeOnly, adherencePercent, timestamp, clientTimeZone
#' @param data data with adherence dataframe
#' @return dataframe with adherence metadata
get_adherence_metadata <- function(data){
    data %>% 
        dplyr::mutate(adherence_metadata = purrr::map(
            adherence, 
            function(adherence_df){
                adherence_df %>% 
                    tibble::enframe() %>% 
                    dplyr::filter(name != "dayRangeOfAllStreams",
                                  name != "streams") %>%
                    tidyr::spread(name, value) %>% 
                    dplyr::rowwise() %>%
                    dplyr::mutate_all(unlist) %>% 
                    dplyr::ungroup()})) %>%
        tidyr::unnest(adherence_metadata)
}

#' Function to get adherence streams endpoint
#' @param data data with adherence dataframe
#' @return dataframe with session information from bridge
get_adherence_streams <- function(data){
    #' Helper function to parse stream contents
    #' by day entries and build it as a dataframe
    parse_adherence_streams <- function(lst) {
        lst$streams %>% 
            purrr::map(function(stream_content){
                stream_content$byDayEntries %>%
                    unname() %>%
                    unlist(recursive = FALSE) %>% 
                    tibble::as_tibble_col() %>% 
                    dplyr::mutate(value = purrr::map(value, function(stream_data){
                        stream_data %>%
                            unlist(recursive = TRUE) %>%
                            tibble::as_tibble_row(.name_repair = "minimal")
                    })) %>%
                    tidyr::unnest(
                        value, keep_empty = TRUE, 
                        names_repair = "minimal")}) %>% 
            purrr::reduce(plyr::rbind.fill)
    }
    
    tryCatch({
        data %>% 
            dplyr::mutate(streams = purrr::map(adherence, parse_adherence_streams)) %>% 
            tidyr::unnest(streams, names_sep = "_")
    }, error = function(e){
        data %>% 
            dplyr::mutate(streams = NA_character_)
    })
}


adherence_mapping <- get_studies_mapping() %>%
    get_user_enrollments() %>% 
    get_user_ids() %>%
    get_adherence() %>% 
    get_adherence_metadata() %>% 
    get_adherence_streams() %>% 
    dplyr::select(-type, -enrollments, -adherence) 


