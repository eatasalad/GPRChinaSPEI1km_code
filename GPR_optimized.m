function [trainedModel, validationRMSE] = GPR_optimized(trainingData)

inputTable = trainingData;
predictorNames = {'lat', 'lon', 'dem', 'slope', 'aspect', 'pre', 'tmp', 'tmx', 'tmn'};
predictors = inputTable(:, predictorNames);
response = inputTable.SPEI;
isCategoricalPredictor = [false, false, false, false, false, false, false, false, false];

% Train a regression model
regressionGP = fitrgp(...
    predictors, ...
    response, ...
    'BasisFunction', 'constant', ...
    'KernelFunction', 'ardrationalquadratic', ...
    'Sigma', 0.05059408790353853, ...
    'Standardize', true);

% Create the result struct with predict function
predictorExtractionFcn = @(t) t(:, predictorNames);
gpPredictFcn = @(x) predict(regressionGP, x);
trainedModel.predictFcn = @(x) gpPredictFcn(predictorExtractionFcn(x));

% Add additional fields to the result struct
trainedModel.RequiredVariables = {'aspect', 'dem', 'lat', 'lon', 'pre', 'slope', 'tmn', 'tmp', 'tmx'};
trainedModel.RegressionGP = regressionGP;
trainedModel.About = 'This struct is a trained model exported from Regression Learner R2022a.';
trainedModel.HowToPredict = sprintf('To make predictions on a new table, T, use: \n  yfit = c.predictFcn(T) \nreplacing ''c'' with the name of the variable that is this struct, e.g. ''trainedModel''. \n \nThe table, T, must contain the variables returned by: \n  c.RequiredVariables \nVariable formats (e.g. matrix/vector, datatype) must match the original training data. \nAdditional variables are ignored. \n \nFor more information, see <a href="matlab:helpview(fullfile(docroot, ''stats'', ''stats.map''), ''appregression_exportmodeltoworkspace'')">How to predict using an exported model</a>.');

% Extract predictors and response
% This code processes the data into the right shape for training the
% model.
inputTable = trainingData;
predictorNames = {'lat', 'lon', 'dem', 'slope', 'aspect', 'pre', 'tmp', 'tmx', 'tmn'};
predictors = inputTable(:, predictorNames);
response = inputTable.SPEI;
isCategoricalPredictor = [false, false, false, false, false, false, false, false, false];

% Perform cross-validation
partitionedModel = crossval(trainedModel.RegressionGP, 'KFold', 10);

% Compute validation predictions
validationPredictions = kfoldPredict(partitionedModel);

% Compute validation RMSE
validationRMSE = sqrt(kfoldLoss(partitionedModel, 'LossFun', 'mse'));
