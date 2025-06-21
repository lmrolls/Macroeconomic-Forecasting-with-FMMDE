function [weights, cf] = pp(A,F,varargin)
%
% The Point Performance based on an error measure to combine individual
% forecasts. The weights are assigned according to the number of times a 
% technique gives the minimum error measure.  The available accuracy measures are
% Squared Error, Absolute Error, Squared Percentage Error, Absolute Percentage Error, or Absolute
% Relative Error (i.e. the absolute error of each data point over the absolute
% error of the best individual forecast on the same data-point).
%
% Author: Apostolos Panagiotopoulos
% Published: March, 2021
%
%
% Inputs:
%
%   A:               An m-by-1 vector or m-by-n matix. The training sets of the actual observations of the forecasted variables.
%                    n is the number of observed time series, which can be 1.
%
%   F:               An m-by-n matrix. The individual forecasts, where m is the number of forecasted datapoints
%                    and n is the number of individual forecasts.
%                    n should be greater than 1.
%
%
% Optional Inputs:
%
%   'criterion':     The combination criterion. The alternatives are
%                       - 'se' (Squared Errors, the default option)
%                       - 'ae' (Absolute Error)
%                       - 'ape' (Absolute Percentage Error)
%                       - 'spe' (Squared Percentage Errors)
%                       - 'are' (Absolute Relative Error, i.e. the absolute error of each data
%                         point over the absolute error of the best individual
%                         forecast on the same datapoint)
%
%   'forecasts':     an o-by-n matrix of out-of-sample forecasts. o is the
%                    number of out of sample datapoints.
%
%   'tables':  A true/false Boolean variable. If true, results are
%                    presented in a table. Else, they are presented in a
%                    matrix. Default option is true.
%
%   'names':         An option to name the individual forecasts. e.g. if
%                    the forecasts are coming from alternative quantitative models.
%                    The default option is Forecast1, Forecast2 etc.
%
%
% Outputs:
%
%   weights:         An n-by-1 table, which is the estimated combination
%                    weights
%
%
% Optional outputs:
%
%   cf:              An o-by-1 matrix of the out-of-sample combined forecast,
%                    when individual out-of-sample forecasts are used. If there are not
%                    individual out of sample forecasts, cp will be empty.
%
%
%% Input

    parseObj = inputParser;
    parseObj.addRequired('A');
    parseObj.addRequired('F');
    parseObj.addParameter('method','ip');
    parseObj.addParameter('criterion','se');
    parseObj.addParameter('forecasts',[]);
    parseObj.addParameter('tables',true);
    parseObj.addParameter('names',{});
    
    parseObj.parse(A,F,varargin{:});
    
    A = parseObj.Results.A;
    F = parseObj.Results.F;
    criterion = parseObj.Results.criterion;
    forecasts = parseObj.Results.forecasts;
    tables = parseObj.Results.tables;
    names = parseObj.Results.names;
    
    
%% Selection of the minimization criterion and the objective function
    
    % Senection of the combination criterion
    if isequal(criterion,'ae')
        measure = abs(A - F);
    elseif isequal(criterion,'ape')
        measure = abs(A - F)./A;
    elseif isequal(criterion,'are')
        measure = abs(A - F)./min(abs(A - F),[],2);
    elseif isequal(criterion,'spe')
        measure = ((A - f)./A).^2;
    else
        measure = (A - F).^2;
    end % isequal(criterion,'ae')
    
    
%% Obtain the weights

    % Calculation of the weights
    for i = 1:size(F,2)
        w(i,1) = sum(double(kroneckerDelta(sym(measure(:,i)),sym(min(measure,[],2)))));
    end
    weights = w/sum(w,1);
    
    
%% Combine individual forecasts
    if isempty(forecasts) == false
        cf = forecasts*weights;
    end % isempty(forecasts) == false
 
    
%% Creation of weights table
  
    if tables
        
        % Setting forecast names
        if isempty(names)
            for j = 1:size(F,2)
                names(j,1) = {['Forecast',num2str(j)]};
            end % j = 1:size(F,2)
        else
            if size(names,2) > 1
                names = transpose(names);
            end % size(names,2) > 1
        end % isempty(names)
    
        % Creation of the table
        weights = table(weights,'RowNames',names);
    
    end % tables

end % End of function