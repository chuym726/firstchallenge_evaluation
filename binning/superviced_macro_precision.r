library(grid)
library(reshape2)
library(ggplot2)
require(gridExtra)
library(scales)

#"\t"

gatherdata <- function(file_paths, tools_names)
{
	separator <- ','
	levels <- c("superkingdom", "phylum", "class", "order", "family", "genus", "species")
	# ﻿instance,entropy,"rand index","adjusted rand index"
	column_tool <- c()
	column_precision <- c()
	column_precision_std <- c()
	column_recall <- c()
	column_recall_std <- c()
	column_accuracy <- c()
	column_misclassification_rate <- c()
	for (index in 1:length(file_paths))
	{
		column_tool <- append(column_tool, rep(tools_names[index], length(levels)))
		print(file_paths[index])
		raw_data <- read.table(file_paths[index], sep = separator, header=T, row.names=1)
		column_precision <- append(column_precision, raw_data$precision)
		column_precision_std <- append(column_precision_std, raw_data$precision.std.)
		column_recall <- append(column_recall, raw_data$recall)
		column_recall_std <- append(column_recall_std, raw_data$recall.stdev.)
		column_accuracy <- append(column_accuracy, raw_data$accuracy)
		column_misclassification_rate <- append(column_misclassification_rate, raw_data$misclassification.rate)
	}
	data_frame <- data.frame(
		precision= column_precision,
		recall= column_recall,
		accuracy=column_accuracy,
		misclassification_rate=column_misclassification_rate)
	# data_frame_r <- data.frame(recall=column_recall)
	data_frame_sd <- data.frame(
		precision_sd= column_precision_std,
		recall_sd= column_recall_std)
	# data_frame_rsd <- data.frame(recall_std=column_recall_std)

	data_frame$level = factor(rep(levels, length(file_paths)), levels=levels)
	# data_frame_r$level = factor(rep(levels, length(file_paths)), levels=levels)
	data_frame_sd$level = factor(rep(levels, length(file_paths)), levels=levels)
	# data_frame_rsd$level = factor(rep(levels, length(file_paths)), levels=levels)

	melted <- melt(data_frame, "level")
	# melted_r <- melt(data_frame_r, "level")
	melted_sd <- melt(data_frame_sd, "level")
	# melted_rsd <- melt(data_frame_rsd, "level")
	# colnames(melted) <- c("level", "variable", "precision")
	#melted$recall = melted_r$value
	melted$sd = melted_sd$value
	#melted$recall_sd = melted_rsd$value
	melted$tools <- factor(column_tool)
	melted$variable <- factor(melted$variable)
	colnames(melted) <- c("level", "metric", "percent", "sd", "tools")
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

argv <- commandArgs(TRUE)
root_path <- argv[1]
file_paths <- list(
	"low"=paste(
		root_path, "low/", 
		list.files(path=paste(root_path, "low/", sep="")), sep=""),
	"medium"=paste(
		root_path, "medium/",
		list.files(path=paste(root_path, "medium/", sep="")), sep=""),
	"high"=paste(
		root_path, "high/",
		list.files(path=paste(root_path, "high/", sep="")), sep="")
	)

output_file <- argv[2]

#######################################

data_low <- gatherdata(
	file_paths$low, get_names(file_paths$low))
data_medium <- gatherdata(
	file_paths$medium, get_names(file_paths$medium))
data_high <- gatherdata(
	file_paths$high, get_names(file_paths$high))

dodge <- position_dodge(width = 0.3)
dodge_big <- position_dodge(width = 0.6)
dodge_small <- position_dodge(width = 0.2, height=0)

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

lable_handle <- function(x, ...)
{
	display <- c()
	for(value in x)
	{
		if (is.na(value))
		{
			display <- append(display, "")
			next
		}
		if ((0 <= value) && (value <= 1))
		{
			display <- append(display, sprintf("%.2f", value))
		}
		else
		{
			display <- append(display, "")
		}
	}
	display
}

title_main <- "Macro Precision, Macro Recall and Accuracy"

# The palette with grey:
cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")
# The palette with black:
cbbPalette <- c("#000000", "#F0E442", "#E69F00", "#56B4E9", "#009E73", "#0072B2", "#D55E00", "#CC79A7")
my_colours <- rev(cbbPalette)
my_shapes <- c(20, 18)
my_linetype <- rev(c("dotted", "solid")) # "solid", "dashed", "dotted", "dotdash", "twodash", "1F", "F1"

draw_plot <- function(data, title)
{
	ggplot() +
		geom_ribbon(
			data=subset(data , metric=="precision" | metric=="recall"),
			aes(x = level, y = percent, ymax=percent+sd, ymin=percent-sd, linetype=metric, fill=metric, group=interaction(metric, tools)),
			alpha = 0.2) +

		geom_line(
			data=subset(data , metric=="precision" | metric=="recall"),
			aes(x = level, y = percent, colour=metric, linetype=metric, fill=metric, group=interaction(metric, tools)),
			size = .7,
			) +

		geom_line(
			data=subset(data , metric=="accuracy" | metric=="misclassification_rate"),
			aes(x = level, y = percent, colour=metric, linetype=metric, fill=metric, group=interaction(metric, tools)),
			size = .7,
			) +
		scale_y_continuous(labels = add_percent, breaks=c(0,25,50,75,100)) +
		scale_fill_manual(
			values=my_colours,  
			breaks=c("accuracy", "misclassification_rate", "precision", "recall"), 
			labels=c("Accuracy", "Misclassification", "Macro Precision", "Macro Recall")) +
		scale_colour_manual(
			values=my_colours,  
			breaks=c("accuracy", "misclassification_rate", "precision", "recall"), 
			labels=c("Accuracy", "Misclassification", "Macro Precision", "Macro Recall")) +
		scale_linetype_manual(
			values=c("solid", "dashed", "dotted", "dotdash"),
			breaks=c("accuracy", "misclassification_rate", "precision", "recall"), 
			labels=c("Accuracy", "Misclassification", "Macro Precision", "Macro Recall")) +
		labs(title=title_main, fill="Metric", linetype="Metric", colour="Metric", x=NULL, y=NULL) +
		ggtitle(paste(title, title_main, sep='\n')) +
		#facet_grid(~ tools) +
		facet_wrap(~ tools, as.table = FALSE) +
		theme(axis.text.x = element_text(angle = 45, hjust = 1)) # , vjust = 0.5
}

#print(subset(data_low, variable == "ari"))
pdf(output_file, paper="a4r", width=297, height=210)
draw_plot(data_low, "Low Complexity Dataset\n")
draw_plot(data_medium, "Medium Complexity Dataset\n")
draw_plot(data_high, "High Complexity Dataset\n")
dev.off()
