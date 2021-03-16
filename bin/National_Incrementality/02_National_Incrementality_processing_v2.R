#1. LIBRARIES ----
library(tidyverse)
library(timetk)
library(lubridate)
library(DataExplorer)
library(janitor)
library(tidymodels)
library(parsnip)
library(modeltime)
library(naniar)
library(earth)


setwd("~/NationalIncrementality")

#2. READ IN DATA ====
tbl <- read_csv("data_fil.csv")%>%clean_names()%>%mutate(date_id = dmy(beg_date))
tbl <- data%>%mutate(date_id = dmy(beg_date))
channel <- read_csv("national_channel.csv")%>%clean_names()
#3. FILETER DOWN STORES  ----

prep_tbl <- tbl%>%
  filter(brand == "CORONA SELTZER")%>%
  group_by(store_cd,brand)%>%
  mutate(seltzer_tzero = min(date_id))%>%
  summarise(seltzer_tzero = min(seltzer_tzero))%>%
  ungroup()%>%
  select(store_cd,seltzer_tzero)
View(prep_tbl)
min(prep_tbl$seltzer_tzero)
hist(prep_tbl$seltzer_tzero,breaks = 'month')


prep_tbl_fil <- prep_tbl%>%
  filter(seltzer_tzero<'2020-03-31')
# with this max date you need in whole dataset is 2020-07-25
#4. JOIN WITH FULL DATA AND CREATE START DATE AND END DATE ----

filtered_tbl <- tbl%>%
  inner_join(prep_tbl_fil)%>%
  filter(date_id < '2020-07-25')%>%
  mutate(date = ymd(date_id), 
         end_date =  ymd(seltzer_tzero),
         start_date =  ymd(seltzer_tzero) %m-% weeks(51))


# *56,991 stores
n_distinct(filtered_tbl$store_cd)

write_csv(filtered_tbl,'filtered_tbl.csv')
rm(c('data','prep_tbl'))
# may not be neccassary now ---doning this in sql
weekly_data<-filtered_tbl%>%
  group_by(store_cd,brand_dsc,master_sku_dsc,end_date,start_date)%>%
  summarise_by_time(
    .date_var = date, 
    .by       = "week",
    sum_eqv_qty    = sum(sum_eqv_qty)
  )%>%
  ungroup()

write_csv(weekly_data,'weekly_data.csv')

#5. SUMMARY ----
weekly_data%>% tk_summary_diagnostics(.date_var = date)

p <- weekly_data%>%group_by(store_cd,channel)%>%
  summarise(count=1)%>%
  ungroup()%>%
  group_by(store_cd,master_sku_dsc)%>%
  summarise(count=sum(count,na.rm=TRUE))%>%
  ungroup()


freq_tbl <- table(p$master_sku_dsc)
View(freq_tbl)


#check for missing values
n_miss(weekly_data)
rm(filtered_tbl)
write_rds(filtered_tbl,"filtered_tbl.rds")

# pad Time 
suppressWarnings({
  StartTime <- Sys.time()
  padded_tbl <-  weekly_data%>%
    group_by(store_cd, brand_dsc,master_sku_dsc,end_date,start_date)%>%
    pad_by_time(
      .date_var  = date, 
      .by        = "week",
      .pad_value = 0
      
    )%>%
    ungroup()
  print(paste0("Elapsed Time: ", Sys.time() - StartTime))
})


#View(padded_tbl)

write_rds(padded_tbl,'padded_tbl.rds')
padded_tbl <- readRDS('padded_tbl.rds')

#6. PROFILE CURRENT DATA ----
channel_tbl <- padded_tbl%>%
  left_join(channel)

View(unique(channel_tbl$channel))
#* Create channel based count of master sku ----
channel_tbl <- channel_tbl%>%
  group_by(store_cd,channel,master_sku_dsc)%>%
  summarise(master_count = 1)%>%
  ungroup()%>%
  group_by(store_cd,channel,master_sku_dsc)%>%
  summarise(master_count = n())

#* get avg order size by master sku and channel
avg_order <- weekly_data%>%
  group_by( channel,store_cd,master_sku_dsc)%>%
  summarize(map(mean,~t.test(. ~ weekly_data$sum_eqv_qty)$p.value))%>%
  ungroup()

test <- head(channel_tbl,20000)
chan <- unique(channel$channel)
master <- test$master_sku_dsc
chan_mean = tibble()

#* Get PERCENT of total by channel and master sku ----
perc_m_tbl <- channel_tbl%>%
  group_by(channel,store_cd,master_sku_dsc)%>%
  summarise(master_count = 1)%>%
  ungroup()%>%
  group_by(channel,master_sku_dsc)%>%
  summarise(count = sum(master_count))%>%
  ungroup()%>%
  mutate(tot = sum(count),
         per = count/sum(count),
         percent = percent(per,suffix = "%"))

ggplot(perc_m_tbl, aes(per,master_sku_dsc, color = channel))+
  geom_boxplot()
#* Get PERCENT of total by channel and store and sku-----
perc_s_tbl <- channel_tbl%>%
  group_by(channel,store_cd,master_sku_dsc)%>%
  summarise(store_count = 1)%>%
  ungroup()%>%
  group_by(channel)%>%
  summarise(count = sum(store_count))%>%
  ungroup()%>%
  mutate(tot = sum(count),
         per = count/sum(count),
         percent = percent(per,suffix = "%"))


ggplot(perc_s_tbl, aes(per,channel, color = channel))+
  geom_boxplot()+coord_flip()

View(perc_s_tbl)


#* Get PERCENT of total by channel and store -----
perc_c_tbl <- channel_tbl%>%
  group_by(channel,store_cd)%>%
  summarise(store_count = 1)%>%
  ungroup()%>%
  group_by(channel)%>%
  summarise(count = sum(store_count))%>%
  ungroup()%>%
  mutate(tot = sum(count),
         per = count/sum(count),
         percent = percent(per,suffix = "%"))


ggplot(perc_c_tbl, aes(per,channel, color = channel))+
  geom_boxplot()+coord_flip()

View(perc_c_tbl)


for (c in chan) {
  
  data_c <- channel_tbl%>%
    filter(channel==c)%>%
    group_by(store_cd,master_sku_dsc)%>%
    summarise(master_mean = mean(sum_eqv_qty))%>%
    ungroup()%>%
    group_by(master_sku_dsc)%>%
    summarise(m_master = mean(master_mean) )
  
  data_c$channel <- c
  
  chan_mean <- rbind(data_c,chan_mean)
  #assign(paste("Channel",c,sep="_"), data_c)
  
}

View(chan_mean)


map(~ mean(~master_sku_dsc,~channel))%>%
  map(summary)
View(list_of_mean)
#7. RANDOMLY SELECT STORES ----

#* Randomly select by % ----
stores <- channel_tbl%>%
  group_by(channel,store_cd)%>%
  summarise(n=n())%>%
  ungroup()%>%
  select(-n)

sample_per <- stores %>% sample_frac(0.20)
n_distinct(sample_per$store_cd)

#11405 *20%
#14258 *25%
#18818 *33%


ggplot(channel_tbl,aes(master_sku_dsc))+
  geom_bar()+
  facet_wrap(~channel)+
  coord_flip()


final_tbl <- channel_tbl%>%
  inner_join(sample_per)

#8.REPROFILE SAMPLE ----
#* Get PERCENT of total by channel and master sku ----
perc_m_tbl_2 <- final_tbl%>%
  group_by(channel,store_cd,master_sku_dsc)%>%
  summarise(master_count = 1)%>%
  ungroup()%>%
  group_by(channel,master_sku_dsc)%>%
  summarise(s_count = sum(master_count))%>%
  ungroup()%>%
  mutate(s_tot = sum(s_count),
         s_per = s_count/sum(s_count),
         s_percent = percent(s_per,suffix = "%"))

ggplot(perc_m_tbl, aes(per,master_sku_dsc, color = channel))+
  geom_boxplot()
joined_m_tbl <- perc_m_tbl_2%>%
  full_join(perc_m_tbl)%>%
  mutate(lift_per = round(s_per/per-1,digits = 6)*100)


View(joined_m_tbl)


ggplot(joined_m_tbl, aes(lift_per,master_sku_dsc, color = channel))+
  geom_boxplot()



View(final_tbl)
saveRDS(channel_tbl,"channel_tbl.rds")

channel_tbl <- readRDS('channel_tbl.rds')

saveRDS(final_tbl,"final_tbl_sample.rds")

final_tbl_1 <- readRDS('final_tbl_sample.rds')


rm(list = c('final_tbl_1','filtered_tbl','p','s','t','prep_tbl','weekly_data','padded_tbl','tbl'))

#9. DECLARE VARIABLES USED IN LOOPS ----
stores = unique(final_tbl$store_cd)
counts = 0
actual_out = tibble()
actual_store = tibble()
nofuture_tbl = tibble()
errorlog = tibble() 
count_omit = 0
count = 0
loopStartTime <- Sys.time()
#10. ACTUAL NUMBERS ----

for ( s in stores) {
  
  data_s <- final_tbl%>%
    filter(store_cd == s)
  counts = counts + 1
  print(paste0("starting store ",s, " num ", counts ))
  
  master = unique(data_s$master_sku_dsc)
  
  for (m in master){
    print(paste0("Starting master_sku ", m))
    data_b <- data_s%>%
      filter(master_sku_dsc == m )
    nrow <- nrow(data_b)
    print(nrow)
    
    
    data_prep <-  data_b%>%
      filter(master_sku_dsc == m & store_cd == s, date >= end_date)%>%
      group_by(brand_dsc, master_sku_dsc, store_cd, date, sum_eqv_qty,start_date,end_date)%>%
      summarise(n())%>%
      ungroup()%>%
      select(brand_dsc,master_sku_dsc,store_cd,date,sum_eqv_qty,start_date, end_date)
    
    data_prep <-  data_prep%>%
      fill(c("brand_dsc","master_sku_dsc","store_cd","start_date","end_date"), .direction = "downup")%>%          
      mutate(sum_eqv_qty = replace_na(sum_eqv_qty,  0))%>%
      rename(value = sum_eqv_qty )%>%
      arrange(date)
    
    data_prep <- data_prep %>%
      group_by(brand_dsc, master_sku_dsc, store_cd, date, start_date,end_date)%>%          
      summarise_by_time(
        .date_var = date, 
        .by       = "week",
        value    = sum(value))%>%
      ungroup()
    if(nrow(data_prep)==0) {
      print(paste0("no Data after end date for ",s))
      nofuture_tbl$store = s
      nofuture_tbl$reason = "No future data"
      errorlog <- rbind(nofuture_tbl,errorlog)
    } else {
      nro <- nrow(data_prep)+52
      data_prep <-  data_prep%>%
        mutate(date_in1 =seq.int(from = 52,to=nro-1, by = 1))%>%
        filter(date_in1 <= 67)
      count = count + 1
      actual_out <- rbind(data_prep,actual_out)
    }
  }
  
  
  print(counts)
  print(paste0("Elapsed Time: ", Sys.time() - loopStartTime))
  
}


write_rds(final_tbl,'final_tbl.rds')
n_distinct(actual_store$store_cd)

#11. FORECAST LOOP----

filtered_tbl_ns <- final_tbl%>%
  filter(master_sku_dsc!="CORONA SELTZER 12PK VAR CAN")

write_rds(filtered_tbl_ns,"filtered_tbl_ns.rds")

filtered_tbl_ns <- readRDS("filtered_tbl_ns.rds")


View(filtered_tbl_ns)

forecast_out = tibble()
output_forecast = tibble()
output = tibble()
total_out = tibble()
final = NULL
stores = unique(filtered_tbl_ns$store_cd)
counts = 0

loopStartTime <- Sys.time()
for ( s in stores) {
  
  data_s <- filtered_tbl_ns%>%
    filter(store_cd == s)
  counts = counts +1
  print(paste0("starting store ",s, " num ", counts ))
  
  master = unique(data_s$master_sku_dsc)
  for (m in master){
    # print(paste0("Starting master_sku ", m))
    data_b <- data_s%>%
      filter(master_sku_dsc == m )
    nrow <- nrow(data_b)
    # print(nrow)
    
    suppressMessages({
      if (nrow <= 12){ 
        # print(paste0("dataset for ", s," ", m, " is empty!"))
        next
        
      } else {
        #include all dates
        start_date = unique(data_b$start_date)
        end_date = unique(data_b$end_date)
        
        all_dates <- data.frame((seq.Date(ymd(start_date), ymd(end_date), by="week")))
        
        colnames(all_dates) <- c("date")
        data_prep <-  data_b%>%
          filter(master_sku_dsc == m & store_cd == s)%>%
          group_by(brand_dsc, master_sku_dsc, store_cd, date, sum_eqv_qty,start_date,end_date)%>%
          summarise(n())%>%
          ungroup()%>%
          select(brand_dsc,master_sku_dsc,store_cd,date,sum_eqv_qty,start_date, end_date)
        
        
        data_prep <-  data_prep%>%
          full_join(all_dates)%>%
          fill(c("brand_dsc","master_sku_dsc","store_cd","start_date","end_date"), .direction = "downup")%>%
          mutate(sum_eqv_qty = replace_na(sum_eqv_qty,  0))%>%
          rename(value = sum_eqv_qty )%>%
          arrange(date)
        
        
        
        
      }
      
      
      evaluation_tbl <- data_prep %>%
        group_by(brand_dsc, master_sku_dsc, store_cd, date, start_date,end_date)%>%
        summarise_by_time(
          .date_var = date, 
          .by       = "week",
          value    = sum(value)
        )%>%
        ungroup()%>%
        filter(date >= start_date & date <= end_date)
      
      nr=min(52,nrow(evaluation_tbl))
      nrm=nrow(evaluation_tbl)
      
      evaluation_tbl <-  evaluation_tbl%>%
        mutate(date_in1 = rev(seq.int(from = 1, to = nrm, by = 1)))%>%
        filter(date_in1<=nr)%>%
        mutate(date_in1 = seq.int(from = 1, to = nr, by = 1))
      
      
      
      #Prophet model
      
      splits <- evaluation_tbl %>%
        time_series_split(
          date_var = date,
          assess = "16 week",
          cumulative = TRUE
        )
      
      
      # Model 4: prophet ----
      model_fit_prophet <- prophet_reg(
        seasonality_weekly = TRUE,
        logistic_floor = 0
      ) %>%
        set_engine(engine = "prophet") %>%
        fit(value ~ date, data = training(splits))
      
      
      models_tbl <- modeltime_table(
        
        model_fit_prophet
        
      )
      
      
      #calibrate
      
      calibration_tbl <- models_tbl %>%
        modeltime_calibrate(new_data = testing(splits), quiet = FALSE)
      
      
      
      # calibration_tbl %>%
      #  modeltime_forecast(
      #    new_data    = testing(splits),
      #    actual_data = evaluation_tbl
      #  ) %>%
      # 
      #  plot_modeltime_forecast()
      
      
      # final <- calibration_tbl %>%
      # modeltime_accuracy()
      
      refit_tbl <-  calibration_tbl%>%
        modeltime_refit(evaluation_tbl)
      
      #calibration_tbl%>%modeltime_accuracy()
      #refit_tbl%>%modeltime_accuracy()
      
      future_tbl <- evaluation_tbl %>%
        future_frame(.date_var = date,
                     .length_out = "16 week")%>%
        summarise_by_time(
          .date_var = date, 
          .by       = "week"
        )%>%
        ungroup()
      e = (nrow(future_tbl)+51)
      future_tbl <- future_tbl%>%
        mutate(date_in1 = seq(52,e,by = 1))
      
      
      predict_tbl <- refit_tbl %>% modeltime_forecast(new_data = future_tbl,
                                                      actual_data = evaluation_tbl)
      
      
      
      
      
      
      
      # * Predict ----
      
      # predict_tbl <- calibration_tbl%>%
      #   modeltime_forecast(
      #     new_data = future_tbl,
      #     actual_data = evaluation_tbl
      #   )
      
      predictions <- predict(model_fit_prophet , new_data = future_tbl) %>% as_vector()
      
      
      # conf_interval <- 0.95
      # residuals     <- model_fit_prophet$fit$data$.residuals %>% as_vector()
      # 
      # alpha <- (1-conf_interval) / 2
      # 1 - alpha
      # 
      # qnorm(alpha)
      # qnorm(1-alpha)
      # 
      # abs_margin_error <- abs(qnorm(alpha) * sd(residuals,na.rm = TRUE))
      # 
      # 
      # forecast_tbl <- evaluation_tbl %>%
      #   select(date,value,date_in1) %>%
      #   mutate(value = as.integer(value))%>%
      #   add_column(type = "actual") %>%
      #   bind_rows( 
      #     future_tbl %>% 
      #                select(date, date_in1) %>%
      #         mutate(
      #           value = predictions,
      #           type  = "prediction")
      #       %>%
      #       mutate(
      #         conf_lo = value - abs_margin_error,
      #         conf_hi = value + abs_margin_error
      #       ))
      
      forecast_tbl <- future_tbl %>%
        select(date, date_in1) %>%
        mutate(
          value = predictions,
          type  = "prediction")
      
      #final$master_sku_dsc <- m
      #final$store_src_cd <- s
      
      forecast_tbl$master_sku_dsc <- m
      forecast_tbl$store_src_cd <- s
      
      
      if( nrow(output_forecast) == 0) {
        #output = final
        output_forecast = forecast_tbl
      }
      else {
        #output <-  rbind(final,output) 
        output_forecast <- rbind(forecast_tbl,output_forecast)
      }
    })
  }
  
  
  #print(paste0("DONE WITH store ",s ))
  
  print(paste0("Elapsed Time: ", Sys.time() - loopStartTime))
  #if(counts %in% seq(0, length(stores),100)){
  # write.table(output_forecast, "national_forecast.csv", sep = ",", row.names = FALSE,col.names = !file.exists("national_forecast.csv"), append = T)
  
  # print(paste0("Elapsed Time: ", Sys.time() - loopStartTime))
  # }
  
}


#* AFTER FORECAST summary stats ----
n_distinct(output_forecast$store_src_cd)

forecast1_prophet <- output_forecast%>%
  group_by(date_in1,master_sku_dsc, type)%>%
  summarise(value = sum(value)
            #, conf_lo = sum(conf_lo,na.rm = TRUE), conf_hi = sum(conf_hi,na.rm = TRUE)
  )%>%
  ungroup()

#Plot forecasts

output_forecast %>%
  # filter(str_detect(master_sku_dsc,"CORONA LIGHT"))%>%
  pivot_longer(cols = c(value
                        #, conf_lo, conf_hi
  )) %>%
  plot_time_series(date_in1, value, .color_var = name, .smooth = FALSE#, .facet_vars = master_sku_dsc
  )
#* Write out forecast ----
saveRDS(output_forecast,"OUTPUT_FORECAST.rds")


View(output_forecast)

#GROUPING STORE DATA AND CHEKCING RMSE MAE AND RSQ only do when testing model ----
# total_out1 <-    total_out%>%
#   group_by(store_src_cd,master_sku_dsc,.model_desc)%>%
#      summarise(mean_rmse = mean(rmse, na.rm = TRUE),
#             mean_rsq = mean(rsq, na.rm = TRUE),
#             mean_mae = mean(mae, na.rm = TRUE),
#             num = n())%>%
#   ungroup()
# 
# total_out3 <- total_out%>%
#   group_by(.model_desc)%>%
#      summarise(mean_rmse = mean(rmse, na.rm = TRUE),
#                mean_mae = mean(mae,na.rm = TRUE),
#             mean_rsq = mean(rsq, na.rm = TRUE),
#             n = n())%>%
#   ungroup()%>%
#   arrange(mean_rmse)
# 
# total <- total_out%>%
#   left_join(total_out1)%>%
#   left_join(total_out3)
# 
# 
# View(total_out3)
# rm(list= c("total","total_out1", "total_out2"))
#   
# write_csv(total_out3,"total_out3_all.csv")

#12. COMBINE ACTUAL VS FORECAST -----
forecast_out <- read_rds("final_combined_forecast.rds")
actual_store <- read_rds("actual_store_all.rds")
# * get seltzer sales ----
corona_seltz <- actual_store%>%
  filter(brand_dsc == "CORONA SELTZER")%>%
  mutate(type = "actual")%>%
  group_by(store_cd)%>%
  summarise(selt_value = sum(value))

n_distinct(corona_seltz$store_cd) #11405

#* Get actual sales for Corona Seltzer grouped by date_int ----
forecast_1 <- forecast_out%>%select(master_sku_dsc,store_src_cd, value,date_in1, type)%>%
  filter(type =="prediction")%>%
  mutate(value = case_when(value<0~0,
                           TRUE~value))%>%
  group_by(store_src_cd,master_sku_dsc)%>%
  summarise(pred_value = sum(value))%>%
  ungroup()



View(forecast_1)

actual_1 <- actual_store%>%
  filter(brand_dsc != "CORONA SELTZER")%>%
  mutate(type = "actual")%>%
  group_by(store_cd,master_sku_dsc)%>%
  summarise(actual_value = sum(value))%>%
  ungroup()


rm(analysis_tbl)
# .----
#* START HERE Read in Brand and Channel ----
brand <- read_csv("national_brand.csv")%>%clean_names()%>%select(-n)
channel <- read_csv("national_channel.csv")%>%clean_names()%>%rename(store_src_cd = store_cd)

#* read back in forecast out if starting from here -----
forecast_out <- readRDS("final_combined_forecast.rds")
actual_store <- readRDS("actual_store_all.rds")%>%rename(store_src_cd = store_cd)

forecast_out_comp <- forecast_out%>%left_join(brand)%>%left_join(channel)

#### aggregate to week by store/mastersku ----
forecast_prophet <- forecast_out_comp%>%
  group_by(store_src_cd,date_in1,master_sku_dsc, type, channel,brand_dsc,dma)%>%
  summarise(value = sum(value),n = n())%>%
  ungroup()

#check values by date_int by channel
forecast_prophet%>%group_by(channel,date_in1)%>%summarise(value=sum(value),n=n())%>%ungroup()

#Get actual sales for Corona Seltzer
#*  grouped by date_int ---- #set all negative numbers to 0
forecast_1 <- forecast_prophet%>%select(store_src_cd,master_sku_dsc, value,date_in1, channel,dma)%>%
  mutate(value = case_when(value<0~0,
                           TRUE~value))%>%
  group_by(store_src_cd,master_sku_dsc,date_in1, channel,dma)%>%
  summarise(pred_value = sum(value))%>%
  ungroup()


# Coefficients   ----

#   * get seltzer sales ----

corona_seltz <- actual_store%>%
  left_join(channel)%>%
  filter(brand_dsc == "CORONA SELTZER")%>%
  mutate(type = "actual")%>%
  group_by(store_src_cd,date_in1, channel,dma)%>%
  summarise(selt_value = sum(value))%>%
  ungroup()
View(actual_store)

actual_1 <- actual_store%>%
  left_join(brand)%>%
  left_join(channel)

actual_comp <- actual_1%>%
  filter(brand_dsc != "CORONA SELTZER")%>%
  mutate(type = "actual")%>%
  left_join(channel)%>%
  group_by(store_src_cd,master_sku_dsc,date_in1,channel,dma)%>%
  summarise(actual_value = sum(value))%>%
  ungroup()

actual_comp1 <- actual_comp%>%
  inner_join(forecast_1,by = c("store_src_cd", "channel","dma", "date_in1","master_sku_dsc"))%>%
  inner_join(corona_seltz,by = c("store_src_cd", "channel","dma", "date_in1"))%>%
  mutate(diff = pred_value - actual_value)%>%
  mutate(per_diff = actual_value/diff)

write_rds(actual_comp1,"actual_comp_nat.rds")
# * Process actual vs forecast ----
actual_comp2 <- readRDS("actual_comp_nat.rds")

store = unique(actual_comp1$store_src_cd)
loopStartTime <- Sys.time()
count = 0
output_forecast = tibble()
coeff_out = tibble()
#store = store[0:100]
for ( s in store) {
  count = count+1
  print(count)
  data_s <- actual_comp1%>%
    filter(store_src_cd == s)
  master = unique(data_s$master_sku_dsc)
  seltz = data_s%>%group_by(store_src_cd)%>%summarise(seltz = sum(selt_value))%>%ungroup()%>%pull()
  if(seltz == 0){ next }
  
  for (m in master) {
    
    data_b <- data_s%>%
      filter(master_sku_dsc==m)
    
    if(nrow(data_b)>0){
      fit <- lm(diff~selt_value,data = data_b)
      fit <- summary(fit)$coefficients
      fit <-  as.data.frame(fit)
      df <- fit%>%
        mutate( type = rownames_to_column(fit))%>%
        filter(type == "selt_value" )%>%
        select(Estimate)
      suppressMessages({ 
        coeff_output <- data_b%>%
          group_by(store_src_cd,master_sku_dsc,dma,channel)%>%
          summarise(actual_value = sum(actual_value), pred_value = sum(pred_value), selt_value = sum(selt_value))
      })
      
      coeff_output$coefficient <- df%>%as.double()
      
      if(nrow(output_forecast)>0){
        output_forecast <- rbind(coeff_output,output_forecast)
        
      }else{
        output_forecast = coeff_output
      }
      
      
    }else {
      next
    }
    
    
    
    
  }
  
  
  print(paste0("Total Elapsed Time: ", Sys.time() - loopStartTime))
}


write_csv(output_forecast,"coeff_out_all.csv")
View(output_forecast)