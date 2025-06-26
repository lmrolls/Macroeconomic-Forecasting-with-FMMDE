function [combinedforecast] = combine(forecasts,varargin)
%
% This function combines individual forecasts to one of more possible combinations.
% The users can implement either the weights that are estimated by another function, predetermined user-selected weights, or averages.
%
% Author: Apostolos Panagiotopoulos
% Published: March, 2021
%
%
% Inputs:
%
%  forecasts:        An n-by-m matrix. The individual forecasts, where n is the number of forecasted datapoints
%                    and m is the number of individual forecasts. n should be greater than 1.
%
%
% Optional Inputs:
%
%  'weights':        An m-by-k table or matrix with the combination weights. m is the weights that coresponed
%                    to the number of individual forecasts. k is the number of weight-set, if the users
%                    want to create more than one combinations. if empty, the function will use one average.
%
%  'trim':           If weights is empty. This option specifies the type of average. The options are:
%                       - 'mean'
%                       - 'median'
%                       - A percentage number. If the users set a number, the function will estimate the trimmed
%                         mean of the individual forecasts to be trimmed by the specified percentage (a scalar between 0 and 100).
%
%  'flag':           If trimmed mean is selected, this is the control for trimming when half the number of outliers (o)
%                    is not an integer. The alternatives are:
%                       - 'round' (default option), round o to the nearest integer (round to a smaller integer if).
%                       - 'floor', Round o down to the next smaller integer.
%                       - 'weighted', If o = i + f, where i is an integer and f is a fraction, compute a weighted
%                         mean with weight (1 – f) for the (i + 1)th and (n – i)th values, and full weight for the values between them.
%
%  'tables':         A true/false Boolean variable. If true, results are presented in a table.
%                    Else, they are presented in a matrix. Default option is true.
%
%  'combnames':      If more than one weight-sets are used, an 1-by-k cell with the names of the weightset.
%
%
% Outputs:
%
%  combinedforecast: An n-by-k table or matrix of the combined forecast.
%
%
%% Input

    parseObj = inputParser;
    parseObj.addRequired('forecasts');
    parseObj.addParameter('weights',[]);
    parseObj.addParameter('trim','mean');
    parseObj.addParameter('flag','round');
    parseObj.addParameter('tables',true);
    parseObj.addParameter('combnames',{});
    
    parseObj.parse(forecasts,varargin{:});
    
    forecasts = parseObj.Results.forecasts;
    weights = parseObj.Results.weights;
    trim = parseObj.Results.trim;
    flag = parseObj.Results.flag;
    tables = parseObj.Results.tables;
    combnames = parseObj.Results.combnames;


%% Combine the forecasts

    if isempty(weights) == false
%% Predetermined weights
        
        if istable(weights) == true
            weights = table2array(weights);
        end % istable(weights) == true
        
        for i = 1:size(weights,2)
            combinedforecast(:,i) = forecasts*weights(:,i);
        end % 1:size(weights,2)
        
    else
%% Averages
        
        if isequal(trim,'mean')
            combinedforecast = mean(forecasts,2);
        elseif isequal(trim,'median')
            combinedforecast = median(forecasts,2);
        else
            combinedforecast = trimmean(forecasts,trim,flag,2);
        end % isequal('trim','mean')
        
    end % isempty(weights) == false

    
%% Creation of forecasting table

    if size(combinedforecast,2) > 1
        if tables
            tbl = table(combinedforecast(:,1));
            forecastnames(1,1) = {['Forecast',num2str(1)]};
            for i = 2:size(combinedforecast,2)
                forecastnames(1,i) = {['Forecast',num2str(i)]};
                tbl = addvars(tbl,combinedforecast(:,i));
            end
            combinedforecast = tbl;
            if isempty(combnames)
                combinedforecast.Properties.VariableNames = forecastnames;
            else
                combinedforecast.Properties.VariableNames = combnames;
            end %isempty(combnames)
        end % tables
    end % size(combinedforecast,2) > 1

end % End of function