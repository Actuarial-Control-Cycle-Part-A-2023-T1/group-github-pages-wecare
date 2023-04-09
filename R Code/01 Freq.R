install.packages(haven)
install.packages(dplyr)
install.packages("fitdistrplus")
library(haven)
library(dplyr)
library(fitdistrplus)

library(readxl)
Hazard_data_original <- read_excel("/Users/jasonxue/Desktop/Hazard_data.xlsx")

trimws(Hazard_data_original,which = c("both"))

Hazard_data_original["count"] <- 1

Hazard_data <- Hazard_data_original %>%
  group_by(Year, `Hazard Event Size`) %>%
  summarise(sum(count))

Year <- (1960:2020)
zero_event <- data.frame(Year)

Hazard_data_Minor <- Hazard_data[Hazard_data$`Hazard Event Size` == "Minor", ]
Hazard_data_Minor <- left_join(zero_event, Hazard_data_Minor)
Hazard_data_Minor[is.na(Hazard_data_Minor)] <- 0

Hazard_data_Medium <- Hazard_data[Hazard_data$`Hazard Event Size` == "Medium", ]
Hazard_data_Medium <- left_join(zero_event, Hazard_data_Medium)
Hazard_data_Medium[is.na(Hazard_data_Medium)] <- 0

Hazard_data_Major <- Hazard_data[Hazard_data$`Hazard Event Size` == "Major", ]
Hazard_data_Major <- left_join(zero_event, Hazard_data_Major)
Hazard_data_Major[is.na(Hazard_data_Major)] <- 0

Minor_Dist <- fitdist(Hazard_data_Minor$`sum(count)`,"nbinom", method="mle")
# gofstat(Minor_Dist)
plot(Minor_Dist)
print(Minor_Dist)

Medium_Dist <- fitdist(Hazard_data_Medium$`sum(count)`,"nbinom", method="mle")
# gofstat(Medium_Dist)
plot(Medium_Dist)
print(Medium_Dist)

Major_Dist <- fitdist(Hazard_data_Major$`sum(count)`,"nbinom", method="mle")
# gofstat(Major_Dist)
plot(Major_Dist)
print(Major_Dist)
