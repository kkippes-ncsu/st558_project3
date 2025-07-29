###### Author: Kayla Kippes
###### Date: 7/29/2025
###### Purpose: Building an API for final project

# Load packages
library(plumber)
library(tidymodels)
library(readr)

## read in the data
diabetes_data <- read.csv("diabetes_binary_health_indicators_BRFSS2015.csv")

## factor all necessary variables used for modeling and select ones wanted
diabetes_modeling <- diabetes_data |>
  mutate(Diabetes = factor(Diabetes_binary,
                           levels=c("0","1"),
                           labels=c("No_Diabetes","Prediabetes_or_Diabetes")),
         HighBP = factor(HighBP,
                         levels=c("0","1"),
                         labels=c("No_High BP","High_BP")),
         HighChol = factor(HighChol,
                           levels=c("0","1"),
                           labels=c("No_High_Cholesterol","High_Cholesterol")),
         Smoker = factor(Smoker,
                         levels=c("1","0"),
                         labels=c("Smoker","Not_Smoker")),
         Stroke = factor(Stroke,
                         levels=c("1","0"),
                         labels=c("Had_Stroke","No_Stroke")),
         Heart_Disease_or_Attack = factor(HeartDiseaseorAttack,
                                          levels=c("1","0"),
                                          labels=c("Heart_Disease","No_Heart_Disease")),
         Heavy_Alcohol_Consumption = factor(HvyAlcoholConsump,
                                            levels=c("1","0"),
                                            labels=c("Heavy_Alcohol",
                                                     "No_Heavy_Alcohol")),
         General_Health = factor(GenHlth,
                                 levels=c("1","2","3","4","5"),
                                 labels=c("Excellent","Very_Good","Good","Fair","Poor")),
         Sex = factor(Sex,
                      levels=c("0","1"),
                      labels=c("Female","Male")),
         Age = factor(Age,
                      levels=c("1","2","3","4","5","6","7",
                               "8","9","10","11","12","13"),
                      labels=c("18-24","25-29","30-34","35-39","40-44",
                               "45-49","50-54","55-59","60-64","65-69",
                               "70-74","75-79","80+")),
         Income = factor(Income,
                         levels=c("1","2","3","4","5","6","7","8"),
                         labels=c("<$10,000",
                                  "$10,000-$15,000",
                                  "$15,000-$20,000",
                                  "$20,000-$25,000",
                                  "$25,000-$35,000",
                                  "$35,000-$50,000",
                                  "$50,000-$75,000",
                                  "$75,000+")),
  ) |>
  select(Diabetes, HighBP, HighChol, BMI, Smoker, Stroke, Heart_Disease_or_Attack,
         Heavy_Alcohol_Consumption, General_Health, Sex, Age, Income)

## model components (based on best model)
bm_recipe <- recipe(Diabetes ~ BMI + Age + HighChol + General_Health, data = diabetes_modeling) |>
  step_normalize(BMI) |>
  step_dummy(Age, HighChol, General_Health)

## model spec
bm_spec <- rand_forest(mtry = 7) |>
  set_engine("ranger") |>
  set_mode("classification")

## workflow
rf_workflow <- workflow() |>
  add_recipe(bm_recipe) |>
  add_model(bm_spec)

## fit the final model
rf_model <- rf_workflow |> fit(data = diabetes_modeling)

#* @apiTitle API for Diabetes Prediction
#* @apiDescription 
#* Use in order to predict if a person has diabetes or not by using a Random Forest model.
#* 
#* **Inputs include:**
#* 
#* - `Age`: Age group (categorical)  
#*   Values: "18-24", "25-29", "30-34", "35-39", "40-44",  
#*   "45-49", "50-54", "55-59", "60-64", "65-69", "70-74", "75-79", "80+"
#* 
#* - `General_Health`: Health Rating (categorical)
#*   Values: "Excellent","Very_Good", "Good", "Fair", "Poor"
#* 
#* - `HighChol`: High Cholesterol or not (categorical)  
#*   Values: "No_High_Cholesterol", "High_Cholesterol"
#* 
#* - `BMI`: Body Mass Index (numeric)
#* 
#* Make a prediction
#* @param Age
#* @param BMI:numeric
#* @param HighChol
#* @param General_Health
#* @get /predict_diabetes
function(Age = "60-64", 
         BMI = 28, 
         HighChol = "No_High_Cholesterol", 
         General_Health = "Very_Good"){
  
  
  input_data <- tibble(
    Age = factor(Age),
    BMI = as.numeric(BMI),
    HighChol = factor(HighChol),
    General_Health = factor(General_Health)
  )
  
  prediction <- predict(rf_model, input_data)
  return(prediction)
}

# Example API calls:
# Might need to replace the localhost with relevant address
# 1. Predict with default values
# curl "http://127.0.0.1:31945/predict_diabetes"

# 2. Predict with full input — common values
# curl "http://127.0.0.1:31945/predict_diabetes?Age=18-24&BMI=50&HighChol=No_High_Cholesterol&General_Health=Very_Good"

# 3. Predict with a younger age and lower income
# curl "http://127.0.0.1:31945/predict_diabetes?Age=70-74&BMI=20&HighChol=High_Cholesterol&General_Health=Fair"

#* @get /info
#* @json
function() {
  list(
    name = "Kayla Kippes",
    link = "https://kkippes-ncsu.github.io/st558_project3/"
  )
}