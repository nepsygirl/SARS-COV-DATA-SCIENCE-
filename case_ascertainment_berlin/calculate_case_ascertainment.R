############################################
##
## Calculate relative case ascertainment
##
############################################

options(warn=-1)

# install needed packages
dynamic_require <- function(package){
  if(eval(parse(text=paste("require(",package,")"))))
    return(TRUE)
  install.packages(package)
  return (eval(parse(text=paste("require(",package,")"))))
}

#for(p in c("ggplot2", "scales","devtools")) {
for(p in c("ggplot2", "cowplot", "latex2exp", "ginpiper", "dplyr", "scales")) {
  dynamic_require(p)
}

########## Set path to the data tables ####################

# phi estimates
incidence.file <-"/Users/vishnushirishyamsaisundar/Desktop/SARS_COV_2/berlin/results/incidence/incidence_country.csv"#TODO: set incidence file (GInPipe output)

# positive test rate and number of tests
testing.file <-"/Users/vishnushirishyamsaisundar/Desktop/SARS_COV_2/berlin/test_cases_Berlin_2021.csv"#TODO: set testing file
reported_cases.file <- "/Users/vishnushirishyamsaisundar/Desktop/SARS_COV_2/berlin/test_cases_Berlin_2021.csv"
# output directory
outdir <- "/Users/vishnushirishyamsaisundar/Desktop/SARS_COV_2/berlin/case_ascertainment/"#TODO: set output directory to save plots and table


########## Read the data files ####################

# create result dir
dir.create(outdir, showWarnings = F)

# read incidences
incidence.table <- read.table(incidence.file, header = T, sep = ",")

# read tests
test.table <- read.table(testing.file, header = T, sep = ",")

# read case reports
cases.table <- read.table(reported_cases.file, header = T, sep = ",")

incidence.table <- incidence.table[as.Date(incidence.table$date) %in% as.Date(test.table$date),]
test.table <- test.table[as.Date(test.table$date) %in% as.Date(incidence.table$date),]

########## Set the variables ####################


# population size (roughly per year is ok)
pop = 3571000# TODO: look for the population size

# sensitivity and specificity
sens=0.7
spec=0.999

pos_rate <- test.table$positive_rate
n_tested <- test.table$tests

incidence <- incidence.table$smoothMedian

########## Calculate the probabilities ####################

#P(infected|tested)
p_infected_tested <- (pos_rate-(1-spec))/(sens-(1-spec))#TODO

#P(tested)
p_tested <- 1-(1-(1/pop))^n_tested #TODO

#P(infected)
p_infected <-incidence/pop #TODO

#P(tested|infected)
p_tested_infected <-(p_infected_tested*p_tested)/ p_infected#TODO


pti.table <- data.frame(incidence.table, 
                        pop=pop, sens=sens, spec=spec, rpos=pos_rate, n_tested=n_tested,
                        p_infected=p_infected, 
                        p_tested = p_tested, p_infected_tested = p_infected_tested, 
                        p_tested_infected = p_tested_infected)


### FINAL PLOTS

p_t <- ggplot(pti.table)+
  geom_line(aes(x=as.Date(date), y=p_tested), size=1)+
  scale_x_date(date_labels = "%b %y", date_breaks = "1 month")+
  labs(x="", y="P(tested)")+
  ylim(0,NA)+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=0.5))

p_i <- ggplot(pti.table)+
  geom_line(aes(x=as.Date(date), y=p_infected), size=1)+
  scale_x_date(date_labels = "%b %y", date_breaks = "1 month")+
  labs(x="", y="P(infected)")+
  ylim(0,NA)+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=0.5))


p_i_t <- ggplot(pti.table)+
  geom_line(aes(x=as.Date(date), y=p_infected_tested), size=1)+
  scale_x_date(date_labels = "%b %y", date_breaks = "1 month")+
  labs(x="", y="P(infected|tested)")+
  ylim(0,NA)+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=0.5))

p_t_i <- ggplot(pti.table)+
  geom_line(aes(x=as.Date(date), y=p_tested_infected), size=1)+
  scale_x_date(date_labels = "%b %y", date_breaks = "1 month")+
  labs(x="", y=TeX("$P(tested|infected) \\cdot c$"))+
  ylim(0,NA)+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=0.5))


p_tests <- ggplot(test.table) +
  geom_line(aes(x=as.Date(date), y=tests), col="darkgrey", size=1)+
  scale_x_date(date_labels = "%b %y", date_breaks = "1 month")+
  scale_y_continuous(labels = comma_format(big.mark = ".",
                                           decimal.mark = ","), limits = c(0, NA))+
  labs(x="", y="number of tests")+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=0.5))


p_t_i_noDate <- p_t_i+ 
  scale_x_date(date_labels = "%b %y", date_breaks = "1 month")+
  theme(axis.text.x = element_blank())
p_ti_tests <- plot_grid( p_t_i_noDate, p_tests, ncol = 1,  align = "v", rel_heights = c(2,1))

ggsave(paste0(outdir, "/case_ascertainment_tests.pdf"),p_ti_tests ,device = "pdf", width = 8, height = 6)


p_total <- plot_grid(p_t, p_i, p_i_t, p_t_i, ncol = 2)
ggsave(paste0(outdir, "/case_ascertainment_plots.pdf"),p_total ,device = "pdf", width = 12, height = 10)


#log2 scale

log_breaks <- c(0, 2^(seq(1,20, by=2)))
log_labels <- c(0, parse(text=math_format(2^.x)(seq(1,20, by=2))))

p_t_i_noDate_log <- p_t_i_noDate+
  scale_y_continuous(trans = pseudo_log_trans(base = 2, sigma=1),
                     breaks = log_breaks,
                     labels = log_labels)
p_ti_tests_log <- plot_grid( p_t_i_noDate_log, p_tests, ncol = 1,  align = "v", rel_heights = c(2,1))

ggsave(paste0(outdir, "/log_case_ascertainment_tests.pdf"),p_ti_tests_log ,device = "pdf", width = 8, height = 6)


#### Write table
write.table(pti.table, paste0(outdir, "/probability_tables.csv"), col.names = T, row.names = F, sep=",")

