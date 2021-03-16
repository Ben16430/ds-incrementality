
library(tidyverse)
library(janitor)
# set wd
setwd("C:/Users/BPAPP/OneDrive - Constellation Brands/Incrementality")

#read in data
coeff_out_w <- read_csv("data/coeff_out_all_w.csv")

View(coeff_out_w)

brand <- read_csv("data/national_brand.csv")%>%clean_names()%>%select(-n)
channel <- read_csv("data/national_channel.csv")%>%clean_names()%>%select(-n)%>%rename(store_src_cd = store_cd)


coeff_tbl <- coeff_out_w%>%left_join(brand)%>%left_join(channel)
coeff_tbl <- coeff_out_w

# Median Coeff by Brand DSC ----
coeff_tbl_brand <- coeff_tbl%>%
  group_by(channel,brand_dsc)%>%
  summarise(n=n_distinct(store_src_cd),med_coefficient_w = round(median(coefficient_w,na.rm = TRUE),digits = 4),med_coefficient = round(median(coefficient,na.rm = TRUE),digits = 4))
View(coeff_tbl_brand)

write_csv(coeff_tbl_brand,"coeff_brand.csv")

# Median Coeff by Master Sku ----

coeff_tbl_mastersku <- coeff_tbl%>%
  group_by(channel,master_sku_dsc)%>%
  summarise(n=n_distinct(store_src_cd),med_coefficient_w = round(median(coefficient_w,na.rm = TRUE),digits = 4),med_coefficient = round(median(coefficient,na.rm = TRUE),digits = 4))
View(coeff_tbl_mastersku)

write_csv(coeff_tbl_mastersku,"coeff_master_channel.csv")

# Median Coeff by Channel ----

coeff_tbl_channel <- coeff_tbl%>%
  group_by(channel)%>%
  summarise(count=n_distinct(store_src_cd),med_coefficient_w = round(median(coefficient_w,na.rm = TRUE),digits = 4),med_coefficient = round(median(coefficient,na.rm = TRUE),digits = 4))
View(coeff_tbl_channel)

write_csv(coeff_tbl_channel,"coeff_channel.csv")

# Median Coeff by DMA ----

coeff_tbl_dma <- coeff_tbl%>%
  group_by(dma,channel,master_sku_dsc)%>%
  summarise(count=n_distinct(store_src_cd),total_volume = sum(actual_value),med_coefficient_w = round(median(coefficient_w,na.rm = TRUE),digits = 4),med_coefficient = round(median(coefficient,na.rm = TRUE),digits = 4))
View(coeff_tbl_dma)

write_csv(coeff_tbl_dma,"coeff_final.csv")


# Median Coeff by state ----

coeff_tbl_state <- coeff_tbl%>%
  group_by(state)%>%
  summarise(count=n_distinct(store_src_cd),med_coefficient_w = median(coefficient_w,na.rm = TRUE),med_coefficient = median(coefficient,na.rm = TRUE))
View(coeff_tbl_state)

test <- coeff_tbl_state%>%group_by(state)%>%summarize(n=n())
View(test)
write_csv(coeff_tbl_state,"coeff_state.csv")

#Corona Extra
ggplot(coeff_tbl,aes(master_sku_dsc,coefficient))+
  geom_boxplot(varwidth = TRUE, outlier.colour = "red")+
  coord_flip()
#Corona Premier
ggplot(coeff_tbl,aes(brand_dsc,coefficient))+
  geom_boxplot(varwidth = TRUE, outlier.colour = "red")

ggplot(coeff_tbl,aes(dma_dsc,coefficient))+
  geom_boxplot(varwidth = TRUE, outlier.colour = "red")

ggplot(coeff_out2,aes(master_sku_dsc,coefficient))+
  geom_boxplot(varwidth = TRUE, outlier.colour = "red")+
  coord_flip()


coeff_tbl <- coeff_out1124_200%>%na.omit()
coeff_tbl <- coeff_out1124_200%>%na.omit()


coeff_tbl1<- coeff_tbl%>%group_by(brand_dsc)%>%summarize(med_coeff = median(coefficient,na.rm = TRUE))

#%>%
#  group_by(brand_dsc)%>%summarise(med_coeff = median(coefficient))

#DMA

ggplot(coeff_tbl1,aes(brand_dsc,coefficient))+
  geom_boxplot(varwidth = TRUE, outlier.colour = "red")+
  coord_flip()



filter(doesNotExist(s))


ggplot(coeff_tbl1,aes(channel_dsc,coefficient))+
  geom_boxplot(varwidth = TRUE, outlier.colour = "red")+
  coord_flip()


#master sku
x = coeff_tbl1%>%
  group_by(channel,master_sku_dsc)%>%
  summarise(median_coefficient = mean(coefficient,na.rm = TRUE))%>%
  ungroup()
View(x)

ggplot(coeff_tbl1,aes(master_sku_dsc,coefficient))+
  geom_boxplot(varwidth = TRUE, outlier.colour = "red")+
  coord_flip()

#channel

x = coeff_tbl1%>%
  group_by(channel_dsc)%>%
  summarise(median_coefficient = mean(coefficient,na.rm = TRUE))%>%
  ungroup()
View(x)


#Brand

x = coeff_tbl1%>%
  group_by(brand_dsc)%>%
  summarise(median_coefficient = median(coefficient,na.rm = TRUE))%>%
  ungroup()
View(x)

#DMA
ggplot(coeff_tbl1,aes(dma_dsc,coefficient))+
  geom_boxplot(varwidth = TRUE, outlier.colour = "red")+
  coord_flip()
x = coeff_tbl1%>%
  group_by(dma_dsc)%>%
  summarise(median_coefficient = median(coefficient,na.rm = TRUE))%>%
  ungroup()
View(x)


write_csv(x,"master_sku.csv")
