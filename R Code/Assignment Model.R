# set working directory and import data
setwd ("D:/MacBook/UNSW/ACTL5100")

#Libraries
library(tidyverse) # data manipulation
library(ggplot2) # plotting
library(naniar) # manipulation of missing values
library(caret) # modelling
library(corrplot) # plotting correlation between variables
library(glmnet) # shrinkage and regularisation for linear models
library(lmreg) # for converting categorical to binary
install.packages("fitdistrplus")
library(fitdistrplus) #fitting distribution
library(MASS)
library(survival)
install.packages("fExtremes")
library(fExtremes)#GEV Modelling

#Importing Data
HazardsData <- read.csv("2023-student-research-hazard-event-data.csv",header = TRUE)
FrequencyData <- read.csv("Hazards_Count_Data.csv",header = TRUE)
EmissionsData <- read.csv("2023-student-research-emissions.csv", header = TRUE)
DemographicsData <- read.csv("2023-student-research-eco-dem-data.csv", header = TRUE)
InflationData <- read.csv("2023-student-research-inflation.csv", header = TRUE)

#Binarise Regions
Region <- binaries(HazardsData[, "Region"])
HazardsData <- bind_cols(HazardsData, Region)
HazardsData <- HazardsData %>% 
  rename("Region.1" = "v.1","Region.2" = "v.2","Region.3" = "v.3","Region.4" = "v.4",
         "Region.5" = "v.5","Region.6" = "v.6")

#Property Damage to Numeric
HazardsData$Property.Damage <- as.numeric(gsub(",", "", HazardsData$Property.Damage))
HazardsData$Property.Damage_inf <- as.numeric(gsub(",", "", HazardsData$Property.Damage_inf))
HazardsData$Year <- as.numeric(HazardsData$Year)
#HazardsData$Year <- HazardsData$Year-1960
HazardsData <- HazardsData[HazardsData$Property.Damage >0, ]
#HazardsData <- HazardsData[HazardsData$Property.Damage <= 2000000, ]


######################################## Log-Normal Model for Severity ########################################################


#Inflated Model
hist(HazardsData$Property.Damage_inf)
hist(log(HazardsData$Property.Damage_inf), prob = TRUE,main = 'Histogram of Log Losses',breaks = 10,col = 4)
#lines(density(log(HazardsData$Property.Damage_inf)), col = 2, lwd = 2)
x2_inf <- seq(min(log(HazardsData$Property.Damage_inf)), max(log(HazardsData$Property.Damage_inf)), length = 40)
standardline_inf <- dnorm(x2, 
                mean = mean(log(HazardsData$Property.Damage_inf)),
                sd = sd(log(HazardsData$Property.Damage_inf)))
lines(x2,standardline, col = 2, lwd = 2)

lognorm.glm_inf = glm(log(Property.Damage_inf)  ~ 
                Region.2 + Region.3 + Region.4 + Region.5 +  Region.6 +Year
              , family=gaussian(link="identity"), data=HazardsData)
summary(lognorm.glm_inf)



#Uninflated Model
hist(HazardsData$Property.Damage)
hist(log(HazardsData$Property.Damage), prob = TRUE,main = 'Histogram of Log Losses',breaks = 10,col = 4)
#lines(density(log(HazardsData$Property.Damage)), col = 2, lwd = 2)
x2 <- seq(min(log(HazardsData$Property.Damage)), max(log(HazardsData$Property.Damage)), length = 40)
standardline <- dnorm(x2, 
                      mean = mean(log(HazardsData$Property.Damage)),
                      sd = sd(log(HazardsData$Property.Damage)))
lines(x2,standardline, col = 2, lwd = 2)

lognorm.glm = glm(log(Property.Damage)  ~ 
                    Region.2 + Region.3 + Region.4 + Region.5 +  Region.6 +Year
                  , family=gaussian(link="identity"), data=HazardsData)
summary(lognorm.glm)




#################################### Negative Binomial Model for Frequency ###################################################


FrequencyData$Total_Events = FrequencyData$Minor_Events + FrequencyData$Medium_Events + FrequencyData$Major_Events
negbin.glm.total <- glm.nb(Total_Events ~ Region_1 + Region_2 +Region_3 + Region_4 +
                             Region_5, data = FrequencyData)
summary(negbin.glm.total)



#################################### Model for Discounting ###################################################

InflationData  <- InflationData  %>% 
  mutate_all(na_if,"")

InflationData <- InflationData %>% 
  rename("rf_rate" = "X1.yr.risk.free.rate")
InflationData$rf_rate_change <- as.numeric(gsub("%", "", InflationData$rf_rate_change))/100
InflationData$rf_rate<- as.numeric(gsub("%", "", InflationData$rf_rate))/100
hist(InflationData$rf_rate_change,breaks = 10)
hist(log(InflationData$rf_rate),breaks = 10)


#Modelling For Interest Change
norm.interest_change <- fitdist(InflationData$rf_rate_change, "norm")
summary(norm.interest_change)




#Modelling for Interest Rate
gamma.interest <- fitdist(InflationData$rf_rate, "gamma")
summary(gamma.interest)

lnorm.interest <- fitdist(InflationData$rf_rate, "lnorm")
summary(lnorm.interest)

weib.interest <- fitdist(InflationData$rf_rate, "weibull")
summary(weib.interest)

logis.interest <- fitdist(InflationData$rf_rate, "logis")
summary(logis.interest)

expo.interest <- fitdist(InflationData$rf_rate, "exp",method="mme")
summary(expo.interest)


################################ Modelling Minor, Medium and Major Events ##############################

#frequency Histograms for Minor, Medium and Major Events
hist(FrequencyData$Minor_Events)
hist(FrequencyData$Medium_Events)
hist(FrequencyData$Major_Events)

plot(FrequencyData$Year,FrequencyData$Minor_Events)
plot(FrequencyData$Year,FrequencyData$Medium_Events)
plot(FrequencyData$Year,FrequencyData$Major_Events)

#Individual Event Type Modelling
negbin.glm.minor <- glm.nb(Minor_Events ~ Region_1 + Region_2 + Region_3 +
                             Region_4 + Region_5 + Year, data = FrequencyData)
summary(negbin.glm.minor)

negbin.glm.medium <- glm.nb(Medium_Events ~ Region_1 + Region_2 + Region_3 +
                              Region_4 + Region_5 + Year, data = FrequencyData)
summary(negbin.glm.medium)

negbin.glm.major <- glm.nb(Major_Events ~ Region_1 + Region_2 + Region_3 +
                             Region_4 + Region_5, data = FrequencyData)
summary(negbin.glm.major)

#Creating Hazards Data Split into Minor, Medium, Major
Minor_Hazard <- HazardsData[HazardsData$Property.Damage<500000,]
Medium_Hazard <- HazardsData[HazardsData$Property.Damage<5000000,]
Medium_Hazard <- Medium_Hazard[Medium_Hazard$Property.Damage>=500000,]
Major_Hazard <- HazardsData[HazardsData$Property.Damage>=5000000,]

#Plotting Histograms
hist(Minor_Hazard$Property.Damage)
hist(Medium_Hazard$Property.Damage)
hist(Major_Hazard$Property.Damage)

#Plotting Log Histograms

hist(log(Minor_Hazard$Property.Damage))
hist(log(Medium_Hazard$Property.Damage))
hist(log(Major_Hazard$Property.Damage))


#Modelling Severities for Each Category ---- Results are poor for Log

#Distribution Fitting
gamma.minor <- fitdist(Minor_Hazard$Property.Damage, "gamma")
summary(gamma.minor)

lnorm.minor <- fitdist(Minor_Hazard$Property.Damage, "lnorm")
summary(lnorm.minor)

weib.minor <- fitdist(Minor_Hazard$Property.Damage, "weibull")
summary(weib.minor)

logis.minor <- fitdist(Minor_Hazard$Property.Damage, "logis")
summary(logis.minor)

expo.minor <- fitdist(Minor_Hazard$Property.Damage, "exp",method="mme")
summary(expo.minor)


gamma.medium <- fitdist(Medium_Hazard$Property.Damage, "gamma")
summary(gamma.medium)

lnorm.medium <- fitdist(Medium_Hazard$Property.Damage, "lnorm")
summary(lnorm.medium)

weib.medium <- fitdist(Medium_Hazard$Property.Damage, "weibull")
summary(weib.medium)

logis.medium <- fitdist(Medium_Hazard$Property.Damage, "logis")
summary(logis.medium)

expo.medium <- fitdist(Medium_Hazard$Property.Damage, "exp",method="mme")
summary(expo.medium)



gamma.major <- fitdist(Major_Hazard$Property.Damage, "gamma")
summary(gamma.major)

lnorm.major <- fitdist(Major_Hazard$Property.Damage, "lnorm")
summary(lnorm.major)

weib.major <- fitdist(Major_Hazard$Property.Damage, "weibull")
summary(weib.major)

logis.major <- fitdist(Minor_Hazard$Property.Damage, "logis")
summary(logis.major)

expo.major <- fitdist(Major_Hazard$Property.Damage, "exp",method="mme")
summary(expo.major)

gev.major <- gevFit(Major_Hazard$Property.Damage)
summary(gev.major)

#Log Normal
lognorm.glm.minor = glm(log(Property.Damage)  ~ 
                    Region.2 + Region.3 + Region.4 + Region.5 +  Region.6 +Year
                  , family=gaussian(link="identity"), data=Minor_Hazard)
summary(lognorm.glm.minor)

lognorm.glm.medium = glm(log(Property.Damage)  ~ 
                          Region.2 + Region.3 + Region.4 + Region.5 +  Region.6 +Year
                        , family=gaussian(link="identity"), data=Medium_Hazard)
summary(lognorm.glm.medium)

lognorm.glm.major = glm(log(Property.Damage)  ~ 
                          Region.2 + Region.3 + Region.4 + Region.5 +  Region.1
                        , family=gaussian(link="identity"), data=Major_Hazard)
summary(lognorm.glm.major)

#Gamma
gamma.glm.minor = glm(Property.Damage  ~ 
                          Region.2 + Region.3 + Region.4 + Region.5 +  Region.6 +Year
                        , family=Gamma(link = "log"), data=Minor_Hazard)
summary(gamma.glm.minor)

gamma.glm.medium = glm(Property.Damage  ~ 
                           Region.2 + Region.3 + Region.4 + Region.5 +  Region.1 +Year
                         , family=Gamma(link="log"), data=Medium_Hazard)
summary(gamma.glm.medium)

gamma.glm.major = glm(Property.Damage  ~ 
                          Region.2 + Region.3 + Region.4 + Region.5 +  Region.6
                        , family=Gamma(link="inverse"), data=Major_Hazard)
summary(gamma.glm.major)

#Inverse Gaussian
invgaus.glm.minor = glm(Property.Damage  ~ 
                        Region.2 + Region.3 + Region.4 + Region.5 +  Region.6 +Year
                      , family=inverse.gaussian	(link = "1/mu^2"), data=Minor_Hazard)
summary(invgaus.glm.minor)

invgaus.glm.medium = glm(Property.Damage  ~ 
                         Region.2 + Region.3 + Region.4 + Region.5 +  Region.1 +Year
                       , family=inverse.gaussian	(link = "1/mu^2"), data=Medium_Hazard)
summary(invgaus.glm.medium)

invgaus.glm.major = glm(Property.Damage  ~ 
                        Region.2 + Region.3 + Region.4 + Region.5 +  Region.6 +Year
                      , family=inverse.gaussian	(link = "1/mu^2"), data=Major_Hazard)

summary(invgaus.glm.major)


#Weibull 
weibull.glm.major = survreg(Surv(Property.Damage)  ~ 
                          Region.1 + Region.3 + Region.4 + Region.5 +  Region.6 
                        , dist = "weibull", data=Major_Hazard)

summary(weibull.glm.major)


#CoxPH

coxph.glm.major = coxph(formula = Surv(Property.Damage)  ~ 
                              Region.1 + Region.3 + Region.4 + Region.5 +  Region.6 +Year
                            , data=Major_Hazard)

summary(coxph.glm.major)

###################################################Excess Code#######################################################


#Total Damage Fitting
plotdist(HazardsData$Property.Damage, histo = TRUE, demp = TRUE)
lnorm.total<- fitdist(HazardsData$Property.Damage, "lnorm",method="mme") 
summary(lnorm.total)
nbinom.total<- fitdist(HazardsData$Property.Damage, "nbinom",method="mme") 
summary(nbinom.total)

#Flood Damage Fitting
FloodsData <- HazardsData[HazardsData$Event== "Flooding", ]
plotdist(FloodsData$Property.Damage, histo = TRUE, demp = TRUE)
lnorm.floods<- fitdist(FloodsData$Property.Damage, "lnorm",method="mme") 
summary(lnorm.floods)
nbinom.floods<- fitdist(FloodsData$Property.Damage, "nbinom",method="mme") 
summary(nbinom.floods)

#Storm Damage Fitting
StormData <- HazardsData[HazardsData$Event== "Storm", ]
plotdist(StormData$Property.Damage, histo = TRUE, demp = TRUE)
lnorm.storm<- fitdist(StormData$Property.Damage, "lnorm",method="mme") 
summary(lnorm.storm)
nbinom.storm<- fitdist(StormData$Property.Damage, "nbinom",method="mme") 
summary(nbinom.storm)
gamma.storm<- fitdist(StormData$Property.Damage, "gamma",method="mme") 
summary(gamma.storm)




HazardsData  <- HazardsData  %>% 
  mutate_all(na_if,"")

# as numeric
cols_num <- c("Quarter","Year", 'Duration', 'Fatalities', 'Injuries', 'Property.Damage')
HazardsData[,cols_num] <- replace(HazardsData[,cols_num],
                                is.na(HazardsData[,cols_num]), "")
HazardsData[,cols_num] <- lapply(HazardsData[,cols_num],function(x) as.factor(ifelse(x=="Y",1,0)))

EventsPlot<-ggplot(data=HazardsData, aes(x=Hazard.Event, y=len)) +
  geom_bar()
barplot(HazardsData$Hazard.Event)
hist(HazardsData$Property.Damage)
hist(log(HazardsData$Property.Damage), breaks = 30)

summary(HazardsData)
log.glm = glm(Property.Damage  ~ Year +
                    Duration + 
                    Fatalities +
                    Injuries
          , family=gaussian(link="log"), data=HazardsData)

summary(HazardsData)
log.glm = glm(Property.Damage  ~ 
                Duration
              , family=gaussian(link="log"), data=HazardsData)
