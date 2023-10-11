function [trainedModel, validationRMSE] = GPR_optimized(trainingData)

inputTable = trainingData;
predictorNames = {'lat', 'lon', 'dem', 'slope', 'aspect', 'pre', 'tmp', 'tmx', 'tmn'};
predictors = inputTable(:, predictorNames);
response = inputTable.SPEI;
isCategoricalPredictor = [false, false, false, false, false, false, false, false, false];

regressionGP = fitrgp(...
    predictors, ...
    response, ...
    'BasisFunction', 'constant', ...
    'KernelFunction', 'ardrationalquadratic', ...
    'Sigma', 0.05059408790353853, ...
    'Standardize', true);

predictorExtractionFcn = @(t) t(:, predictorNames);
gpPredictFcn = @(x) predict(regressionGP, x);
trainedModel.predictFcn = @(x) gpPredictFcn(predictorExtractionFcn(x));

trainedModel.RequiredVariables = {'aspect', 'dem', 'lat', 'lon', 'pre', 'slope', 'tmn', 'tmp', 'tmx'};
trainedModel.RegressionGP = regressionGP;
trainedModel.About = 'This struct is a trained model exported from Regression Learner R2022a.';
trainedModel.HowToPredict = sprintf('To make predictions on a new table, T, use: \n  yfit = c.predictFcn(T) \nreplacing ''c'' with the name of the variable that is this struct, e.g. ''trainedModel''. \n \nThe table, T, must contain the variables returned by: \n  c.RequiredVariables \nVariable formats (e.g. matrix/vector, datatype) must match the original training data. \nAdditional variables are ignored. \n \nFor more information, see <a href="matlab:helpview(fullfile(docroot, ''stats'', ''stats.map''), ''appregression_exportmodeltoworkspace'')">How to predict using an exported model</a>.');


inputTable = trainingData;
predictorNames = {'lat', 'lon', 'dem', 'slope', 'aspect', 'pre', 'tmp', 'tmx', 'tmn'};
predictors = inputTable(:, predictorNames);
response = inputTable.SPEI;
isCategoricalPredictor = [false, false, false, false, false, false, false, false, false];

partitionedModel = crossval(trainedModel.RegressionGP, 'KFold', 10);

validationPredictions = kfoldPredict(partitionedModel);

validationRMSE = sqrt(kfoldLoss(partitionedModel, 'LossFun', 'mse'));
