install.packages(haven)
install.packages(dplyr)
install.packages("fitdistrplus")
install.packages("mixdist")
library(haven)
library(dplyr)
library(fitdistrplus)
library(mixdist)
library(readxl)
Hazard_data_original <- read_excel("/Users/jasonxue/Desktop/Hazard_data.xlsx")

trimws(Hazard_data_original,which = c("both"))

# Hazard_data <- Hazard_data_original %>%
#   group_by(Year, `Hazard Event Size`) %>%
#   summarise(total_property_damage = sum(`Property Damage`))

Hazard_data <- Hazard_data_original

Hazard_data_Minor <- Hazard_data[Hazard_data$`Hazard Event Size` == "Minor", ]
Hazard_data_Medium <- Hazard_data[Hazard_data$`Hazard Event Size` == "Medium", ]
Hazard_data_Major <- Hazard_data[Hazard_data$`Hazard Event Size` == "Major", ]

Hazard_data_Minor <- filter(Hazard_data_Minor, `Inflated Property Damage` != 0)
Hazard_data_Medium <- filter(Hazard_data_Medium, `Inflated Property Damage` != 0)
Hazard_data_Major <- filter(Hazard_data_Major, `Inflated Property Damage` != 0)

Major_Dist <- fitdist(Hazard_data_Major$`Inflated Property Damage`,"weibull", method="mle")
gofstat(Major_Dist)
plot(Major_Dist)
print(Major_Dist)

Medium_Dist <- fitdist(Hazard_data_Medium$`Inflated Property Damage`,"lnorm", method="mle")
gofstat(Medium_Dist)
plot(Medium_Dist)
print(Medium_Dist)

Minor_Dist <- fitdist(Hazard_data_Minor$`Inflated Property Damage`,"weibull", method="mle")
gofstat(Minor_Dist)
plot(Minor_Dist)
print(Minor_Dist)

mean_major <- weibullparinv(0.4919198, 42434790)
mean_minor <- weibullparinv(0.7184818, 68885.18)

42434790*gamma(1+1/0.4919198)
68885.18*gamma(1+1/0.7184818)
