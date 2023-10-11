clear,clc

%import topographic and geographic variables 

mydir = 'I:\SPEIdownscale\Data\UnifyFactorSize\';

[dem,R] = readgeoraster(char([mydir 'dem.tif'])) ;
[slope,~] = readgeoraster(char([mydir 'slope.tif'])) ;
[lat,~] = readgeoraster(char([mydir 'imgLat.tif'])) ;
[lon,~] = readgeoraster(char([mydir 'imgLon.tif'])) ;
[aspect,~] = readgeoraster(char([mydir 'aspect.tif'])) ;

% 读取坐标参数
info=geotiffinfo(char([mydir 'dem.tif']));


% double/single
dem = single(dem);
lat=single(lat);
lon=single(lon);
slope = single(slope);
aspect = single(aspect);
% get the size of data
[m, n] = size(dem);
[m1, n1] = size(lat);
[m2, n2]= size(lon);
[m3,n3] = size(slope);
[m4,n4] = size(aspect);
% turn into column vector
dem = reshape(dem, m*n, 1);
lat = reshape(lat, m1*n1, 1);
lon = reshape(lon, m2*n2, 1);
slope = reshape(slope,m3*n3,1);
aspect = reshape(aspect, m4*n4,1);

%%
tic
scale = 1; %
inputPath =[ 'I:\SPEIdownscale\Data\2traintables\SPEI_' num2str(scale) '\'];

fileList = dir([inputPath, '*.csv']);  
fileNumber = length(fileList); 

point_train = shaperead('I:\SPEIdownscale\Data\points\Allpoints_CN_train70.shp');
point_test = shaperead('I:\SPEIdownscale\Data\points\Allpoints_CN_test30.shp');

point_train = struct2table(point_train);
point_train.Idx = join(string(table2array(point_train(:,(6:8)))),"-");

train_idx = point_train.Idx;

point_test = struct2table(point_test);
point_test.Idx =  join(string(table2array(point_test(:,(6:8)))),"-");

test_idx = point_test.Idx;

cd('I:\SPEIdownscale\Code\TrainModels')

outputPath = 'I:\SPEIdownscale\';

% mkdir('I:\SPEIdownscale\ProduceRaster\SPEI_1')
% mkdir('I:\SPEIdownscale\ProduceRaster\SPEI_3')
% mkdir('I:\SPEIdownscale\ProduceRaster\SPEI_6')
% mkdir('I:\SPEIdownscale\ProduceRaster\SPEI_9')
% mkdir('I:\SPEIdownscale\ProduceRaster\SPEI_12')

for k=1:1440

    year= 1901+fix((k-1)/12);
    month = mod(k-1,12)+1;

    mydata = readtable([inputPath,'SPEI_', num2str(scale),'_', num2str(year),'_',num2str(month),'.csv']);

    mydata(isnan(mydata.SPEI),:) = [] ;

    mydata.SPEI = mydata.SPEI*10;

    %sum(isnan(mydata.SPEI))

    mydata.Idx = join(string(table2array(mydata(:,(3:5)))),"-");

    Idx_train = ismember(mydata.Idx,train_idx);
    mydata_train = mydata(Idx_train,:);
    mydata_train = removevars(mydata_train,"Idx");

    Idx_test = ismember(mydata.Idx,test_idx);
    mydata_test = mydata(Idx_test,:);
    mydata_test = removevars(mydata_test,"Idx");

    % train models
    tic
    [trainedModel, validationRMSE] = GPR_optimized(mydata_train);
    toc

%————————————————————————————————————————————————————————————testing data————————————————————————————————————————————————————————————————
%   prediction accuray
    predictData = trainedModel.predictFcn(mydata_test);

    trueAndPredictData = table(mydata_test.lon,mydata_test.lat,mydata_test.SPEI,predictData);

    trueAndPredictData.Properties.VariableNames = {'lon','lat','observed','predicted'};

  
    writetable(trueAndPredictData,char([outputPath  'OptimizedAcc_test\True_Predict\SPEI_' num2str(scale) '\TruePredict_' num2str(year) '_' num2str(month) '.csv'])); % 写出

    
    true = trueAndPredictData.observed;
    predict = trueAndPredictData.predicted;

     % MAE, R2, rmse
     MAE = mean(abs(true-predict),"omitnan");
     [r2,rmse] = rsquare(true,predict);

     r2_time = [year,month,r2];
     r2_time = array2table(r2_time);
     r2_time.Properties.VariableNames = {'year','month','R2'};

     rmse_time = [year,month,rmse];
     rmse_time = array2table(rmse_time);
     rmse_time.Properties.VariableNames = {'year','month','RMSE'};

     mae_time = [year,month,MAE];
     mae_time = array2table(mae_time);
     mae_time.Properties.VariableNames = {'year','month','MAE'};


     writetable(r2_time,[outputPath  'OptimizedAcc_test\SPEI_' num2str(scale)  '\R2_'   num2str(year) '_' num2str(month) '.csv']);
     writetable(rmse_time,[outputPath 'OptimizedAcc_test\SPEI_' num2str(scale) '\RMSE_' num2str(year) '_' num2str(month) '.csv']);
     writetable(mae_time,[outputPath  'OptimizedAcc_test\SPEI_' num2str(scale) '\MAE_'   num2str(year) '_' num2str(month) '.csv']);

% ————————————————————————————————————————————————————————————Raster prediction——————————————————————————————————————————————————————————————————————
    % import climatic rasters
    [pre,~] = readgeoraster(char([ 'I:\SPEIdownscale\Data\Peng\pre_tiff\Pre_' num2str(year) '_' num2str(month) '.tif']));
    [tmp,~] = readgeoraster(char([ 'I:\SPEIdownscale\Data\Peng\tmp_tiff\tmp_' num2str(year) '_' num2str(month) '.tif']));
    [tmx,~] = readgeoraster(char([ 'I:\SPEIdownscale\Data\Peng\tmx_tiff\tmx_' num2str(year) '_' num2str(month) '.tif']));
    [tmn,~] = readgeoraster(char([ 'I:\SPEIdownscale\Data\Peng\tmn_tiff\tmn_' num2str(year) '_' num2str(month) '.tif']));
    
    pre = single(pre/10);
    tmp = single(tmp/10);
    tmx = single(tmx/10);
    tmn = single(tmn/10);

    [m5,n5] = size(pre);
    [m6,n6] = size(tmp);
    [m7,n7] = size(tmx);
    [m8,n8] = size(tmn);

    % column variables
    pre = reshape(pre,m5*n5,1);
    tmp = reshape(tmp,m6*n6,1);
    tmx = reshape(tmx,m7*n7,1);
    tmn = reshape(tmn,m8*n8,1);

    data = [lat,lon,dem,slope,aspect,pre,tmp,tmx,tmn];

   
    VariableNames = {'lat','lon','dem','slope','aspect','pre','tmp','tmx','tmn'};
    rasterTable = array2table(data, 'VariableNames', VariableNames);

    % Predict
    tic
    predictData = trainedModel.predictFcn(rasterTable);
    toc

    rasterMatrix = reshape(predictData, m, n);
 

    % show images
    %rasterMap=imagesc(rasterMatrix);

    % export data
    geotiffwrite(char([outputPath 'OptimizedProduceRaster\SPEI_' num2str(scale) '\SPEI_' num2str(scale) '_' num2str(year) '_' num2str(month) '.tif']),...
        rasterMatrix, R,'GeoKeyDirectoryTag', info.GeoTIFFTags.GeoKeyDirectoryTag);

end


toc

