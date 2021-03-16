
#1.LIBRARIES ----
library(tidyverse)
library(forcats)
library(janitor)
library(Hmisc)
library(tools)
#2.READ IN DATA ----
data <- read_csv("RawData_all_1.csv")%>%clean_names()%>%rename(master_sku_cd=master_sku_cd_1)
brand <- read_csv("national_brand.csv")%>%clean_names()
channel <- data%>%group_by(store_cd,dist_cd,dma,state,channel)%>%
  summarise(n=n())%>%
  ungroup()%>%
  select(-n)
write_csv(channel,"national_channel.csv")
#3.PROFILE ----
# too big to run this now
#describe(data, size="normalsize")

n_distinct(data$store_cd)

#4.PLOT ----
#* master sku ----
data <- data%>%left_join(brand)
data_master <- data%>%
  group_by(master_sku_dsc,store_cd)%>%
  summarise(count_master = 1)%>%
  ungroup()%>%
  group_by(master_sku_dsc)%>%
  summarise(count_master = sum(count_master,na.rm=TRUE))%>%
  arrange(desc(count_master))%>%
  mutate(master_sku_dsc = fct_reorder(master_sku_dsc,
                                      count_master))


ggplot(data_master, aes(master_sku_dsc,count_master, label = count_master))+
  geom_bar(stat='identity')+
  coord_flip()





#* brand dsc ----
data_brand <- data%>%
  group_by(brand,store_cd)%>%
  summarise(count_brand = n())%>%
  ungroup()%>%
  arrange(desc(count_brand))%>%
  mutate(brand = fct_reorder(brand,
                             count_brand))

ggplot(data_brand, aes(brand,count_brand, label = count_brand))+
  geom_bar(stat='identity')+
  coord_flip()

#* channel ----
ggplot(data)+
  geom_bar(aes(channel))+
  coord_flip()

data_channel <- data%>%group_by(channel)%>%summarise(n=n())
View(data_channel)

#* dma ----
data_dma <- data%>%
  group_by(dma)%>%
  summarise(count_dma = n())%>%
  ungroup()%>%
  arrange(desc(count_dma))%>%
  filter(count_dma >= 100000)%>%
  mutate(dma = fct_reorder(dma,
                           count_dma),
         count_dma = count_dma/1000)



ggplot(data_dma, aes(dma,count_dma, label = count_dma))+
  geom_bar(stat='identity')+
  coord_flip()

n_distinct(data_dma$dma)
#with out filter 209 DMAs
#with filter > 100,000 98 DMAs

#PLOT STATE
data_state <- data%>%
  group_by(state)%>%
  summarise(count_state = n())%>%
  ungroup()%>%
  arrange(desc(count_state))%>%
  #filter(count_state >= 1000)%>%
  mutate(state = fct_reorder(state,
                             count_state),
         count_state = count_state/1000)


ggplot(data_state, aes(state,count_state, label = count_state))+
  geom_bar(stat='identity')+
  coord_flip()




data_fil <- data%>%
  inner_join(data_master)%>%
  inner_join(data_brand)%>%
  inner_join(data_state)%>%
  inner_join(data_dma)
View(data_fil)  

# _____________----
#5.WRITE  FILTERED DATA ----
write_csv(data_fil)
