set.seed(1234)

freq_major <- rnbinom(n=1000000,size=0.9511905, mu=3.0653668)
freq_medium <- rnbinom(n=1000000,size=3.712376, mu=6.787227)
freq_minor <- rnbinom(n=1000000,size=1.473771, mu=45.325902)

major_95<-sort(freq_major, TRUE)[1000000*0.05]
medium_95<-sort(freq_medium, TRUE)[1000000*0.05]
minor_95<-sort(freq_minor, TRUE)[1000000*0.05]

major_95
medium_95
minor_95

hist(freq_major)

damage_major <- rweibull(n=1000000,shape=0.4919198 ,scale=42434790)
damage_medium <- rlnorm(n=1000000,meanlog=14.0567422 ,sdlog=0.6068971)
damage_minor <- rweibull(n=1000000,shape=0.7184818 ,scale=68885.18)

major_95<-sort(damage_major, TRUE)[1000000*0.05]
medium_95<-sort(damage_medium, TRUE)[1000000*0.05]
minor_95<-sort(damage_minor, TRUE)[1000000*0.05]

major_95
medium_95
minor_95

hist(damage_major)