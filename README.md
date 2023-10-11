# GPRChinaSPEI1km_code

The GPRChinaSPEI1km_code provides the calculation of the Gaussian process regression-based model for producing the high spatial resolution and long-term Standardized precipitation evapotranspiration index (SPEI) datasets using the original coarse resolution SPEI and high resolution climatic and topographic variables.  

Instruction:
1.	GPR_optimized.m is the optimized model using Bayesian optimization. 
2.	GPR_SPEI.m reads the organized SPEI samples in a table format, trains the model for each month, evaluates the model accuracy using testing samples, imports gridded dependent variables and generates the high-resolution SPEI for each month. 
3.	Data: in the Data zip file, the “traintables” folder contains the original SPEI; the “points” folder contains the information of the divided training and testing samples; the “Peng” folder contains the gridded climatic variables; the “UnifyFactorSize” folder contains the topographic and geographic variables with the same grid size. Note that we put the data of January 1901 as an example. 
