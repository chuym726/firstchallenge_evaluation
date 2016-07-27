library(grid)
library(reshape2)
library(ggplot2)
library(gridExtra)
library(scales)

source("parse_raw_result_data.R")
#"\t"

dir.exists <- function(d) {
    de <- file.info(d)$isdir
    ifelse(is.na(de), FALSE, de)
}

gatherdata <- function(file_paths, tools_names)
{
	#print(tools_names)
	#print(file_paths)
	separator <- '\t'
	levels <- c("binning")
	#instance,entropy,"rand index","adjusted rand index"
	column_tool <- c()
	column_entropy <- c()
	column_ri <- c()
	column_ari <- c()
	for (index in 1:length(file_paths))
	{
		#print(file_paths[index])
		column_tool <- append(column_tool, rep(tools_names[index], length(levels)))
		raw_data <- read.table(file_paths[index], sep = separator, header=T, row.names=1)
		column_entropy <- append(column_entropy, tail(raw_data$entropy, n=1))
		column_ri <- append(column_ri, tail(raw_data$rand.index, n=1))
		column_ari <- append(column_ari, tail(raw_data$adjusted.rand.index, n=1))
	}
	data_frame <- data.frame(
		entropy = column_entropy,
		ri = column_ri,
		ari = column_ari)
	#data_frame$level = factor(rep(levels, length(file_paths)), levels=levels)
	data_frame$tools <- factor(column_tool)
	melted <- melt(data_frame, "tools")
	melted$variable <- factor(melted$variable)
	colnames(melted) <- c("tools", "metric", "value")
	levels(melted$metric) <- c("Entropy", "Rand index", "Adjusted rand index")
	return(melted)
}


#names <- 'berserk_feynman,lonely_shockley,lonely_wright,prickly_morse'
#paths <- 'low/berserk_feynman.csv,low/lonely_shockley.csv,low/lonely_wright.csv,low/prickly_morse.csv'
#tools_names <- unlist(strsplit(names, ','))
#file_paths <- unlist(strsplit(paths, ','))
#output_file <- "out.pdf"
#tools_names <- unlist(strsplit(argv[1], ','))
#file_paths <- unlist(strsplit(argv[2], ','))

get_names <- function(file_paths)
{
	names <- c()
	for (index in 1:length(file_paths))
	{
		#print(strsplit(file_paths[index], c('.', '/'))[-2])
		names[index] <- tail(unlist(strsplit(file_paths[index], "[/.]")), n=2)[1]
		#names[index] <- strsplit(file_paths[index], '.')[1]
	}
	names
}



#######################################

get_frames <- function(df_tools_subset)
{
	df_tools_low <- subset(df_tools_subset, dataset=="1st CAMI Challenge Dataset 1 CAMI_low")
	df_tools_medium <- subset(df_tools_subset, dataset=="1st CAMI Challenge Dataset 2 CAMI_medium")
	df_tools_high <- subset(df_tools_subset, dataset=="1st CAMI Challenge Dataset 3 CAMI_high")
	category_order <- c(
		"new_order", "new_family", "new_genus", "new_species", "new_strain", "virus", "unidentified plasmid", "unidentified circular element",
		"unique strain", "common strain", "circular element")
	categories <- as.character(levels(df_tools_subset$category))
	# print(categories)
	data_low <- NULL
	data_medium <- NULL
	data_high <- NULL
	nov_low <- c()
	nov_medium <- c()
	nov_high <- c()
	#print(summary(df_tools_high))
	#exit
	for (l_category in categories)
	{
		#######################################
		df_tools_low_subset <- subset(df_tools_low, category==l_category)
		df_tools_medium_subset <- subset(df_tools_medium, category==l_category)
		df_tools_high_subset <- subset(df_tools_high, category==l_category)
		if (length(df_tools_low_subset$file)>0)
		{
			data_frame <- gatherdata(
				as.vector(df_tools_low_subset$file), as.vector(df_tools_low_subset$anonymous))
			data_frame$category <- factor(rep(l_category, length(data_frame$tools)), levels=category_order)
			#nov_low <- append(nov_low, rep(category, length(data_frame$tools)))
			if (is.null(data_low))
			{
				data_low <- data_frame
			}
			else
			{
				data_low <- rbind(data_low, data_frame)
			}
		}
		if (length(df_tools_medium_subset$file)>0)
		{
			data_frame <- gatherdata(
				as.vector(df_tools_medium_subset$file), as.vector(df_tools_medium_subset$anonymous))
			data_frame$category <- factor(rep(l_category, length(data_frame$tools)), levels=category_order)
			#nov_medium <- append(nov_medium, rep(category, length(data_frame$tools)))
			if (is.null(data_medium))
			{
				data_medium <- data_frame
			}
			else
			{
				data_medium <- rbind(data_medium, data_frame)
			}
		}
		if (length(df_tools_high_subset$file)>0)
		{
			data_frame <- gatherdata(
				as.vector(df_tools_high_subset$file), as.vector(df_tools_high_subset$anonymous))
			data_frame$category <- factor(rep(l_category, length(data_frame$tools)), levels=category_order)
			#nov_high <- append(nov_high, rep(category, length(data_frame$tools)))
			if (is.null(data_high))
			{
				data_high <- data_frame
			}
			else
			{
				data_high <- rbind(data_high, data_frame)
			}
		}
	}
	#data_low$novelty <- factor(nov_low, levels=categories) # 
	#data_medium$novelty <- factor(nov_medium, levels=categories)
	#data_high$novelty <- factor(nov_high, levels=categories)
	return(list(low=data_low, medium=data_medium, high=data_high))
}


dodge <- position_dodge(width = 0.3)
dodge_big <- position_dodge(width = 0.6)
#dodge_small <- position_dodge(width = 0.1, height=0)
#######################################


#############
##
##  PLOTS
##
#############

add_percent <- function(x, ...)
{
	sprintf("%.0f%%", x)
}

#title_main <- "(%s) Entropy, rand index, adjusted rand index"
title_main <- "Entropy, rand index, adjusted rand index"

# The palette with grey:
cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")
# The palette with black:
cbbPalette <- c("#000000", "#F0E442", "#E69F00", "#56B4E9", "#009E73", "#0072B2", "#D55E00", "#CC79A7")
my_colours <- rev(cbbPalette)
my_shapes <- c(20, 18)
my_linetype <- rev(c("dotted", "solid")) # "solid", "dashed", "dotted", "dotdash", "twodash", "1F", "F1"


#pdf("example_macro_prec_recall.pdf", paper="a4r", width=297, height=210)
draw_plot <- function(data, title, method_labels)
{
	method_labeller <- function(variables)
	{
		rvalue <- strtrim(method_labels[variables], 17)
		return(rvalue)
	}
	tmp <- ggplot(subset(data, metric == "Adjusted rand index"), 
		aes(
			x = category, y = value,
			colour=tools, group=interaction(tools, metric)
		)) + #fill=tools, 
		#geom_bar(stat="identity") +
		geom_line(size = .7) +
		#labs(title=title_main, colour="Tool name", x="Level", y=NULL) +
		labs(fill="Anonymous submission", x=NULL, y=NULL) +
		scale_colour_discrete(labels = method_labeller) +
		scale_y_continuous(breaks = c(0, 0.25, 0.5, 0.75, 1), limits=c(0, 1)) +
		facet_wrap( ~ metric, ncol=1, scales="fix") + #, as.table = FALSE, scales="free_y"
		geom_text(aes(label=value), size=4, hjust=0.4, vjust=-0.4, show.legend=F) +
		ggtitle(title) +
		theme(axis.text.x = element_text(angle = 45, hjust = 1), panel.margin = unit(1, "lines")) # , vjust = 0.5
	return(tmp)
}

#######################################

argv <- commandArgs(TRUE)
root_path <- argv[1]
output_file <- argv[2]

df_tools <- get_dataframe_of_tools_at_locations(root_path)
if (length(argv)==2)
{
	df_tools_subset <- subset(df_tools, datatype=="unsupervised_included")
}
if (length(argv)!=2)
{
	df_tools_subset <- subset(df_tools, datatype=="unsupervised_excluded")
}
#######################################

method_labels <- df_tools_subset$method
method_labels <- gsub("[()]", "", method_labels)
names(method_labels) <- df_tools_subset$anonymous

dataframes <- get_frames(df_tools_subset)

#pdf(output_file, paper="a4r", width=297, height=210)
ggplots <- list()
#if (dir.exists(dir_low))
#{
ggplots[[length(ggplots)+1]] <- draw_plot(dataframes$low, "Low Complexity Dataset\n", method_labels)
#}
#if (dir.exists(dir_medium))
#{
ggplots[[length(ggplots)+1]] <- draw_plot(dataframes$medium, "Medium Complexity Dataset\n", method_labels)
#}
#if (dir.exists(dir_high))
#{
ggplots[[length(ggplots)+1]] <- draw_plot(dataframes$high, "High Complexity Dataset\n", method_labels)
#}
#dev.off()
output <- marrangeGrob(ggplots, nrow=1, ncol=1, top=NULL)
ggsave(output_file, output, width=297, height=210, units='mm')#, device="pdf"

