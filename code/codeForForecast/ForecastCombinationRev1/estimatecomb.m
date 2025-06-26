function [weights, cf] = estimatecomb(A,F,varargin)
%
% This function includes six well-known methods to combine individual forecasts. These are:
%
% 1) Inverse Proportion to an error measure. The weights are estimated according
%    to the inverse proportion of an accuracy measure of an individual forecast,
%    divided by the sum of the inverse proportion of the accuracy measure of all the forecasts.
%    The available accuracy measures are either the mean or the variance of
%    Squared Error, Absolute Error, Squared Percentage Error, Absolute Percentage Error, or Absolute
%    Relative Error (i.e. the absolute error of each data point over the absolute
%    error of the best individual forecast on the same data-point).
%
% 2) Inverse Rank. Individual forecasts are ranked according their performance.
%    The model with the lowest error measure is ranked 1, etc.
%
% 3) Point Performance based on an error measure. The weights are assigned according
%    to the number of times a technique gives the minimum error measure.
%    The available accuracy measures are
%    Squared Error, Absolute Error, Absolute Percentage Error, or Absolute
%    Relative Error.
%
% 4) Information Criterion. Either the Akaike Information Criterion or the
%    Bayesian Information Criterion.
%
% 5) Constrained Linear Least Squares (number of series of actual observations should be 1)
%
% 6) Linear Programming (number of series of actual observations should be 1). The optimization objectives are:
%   a)  Single objective linear programming that minimizes a 'sum of errors' index. Either the Sum of Absolute Errors,
%       Sum of Absolute Percentage Errors, or Sum of Absolute Relative Errors.
%   b)  Single objective linear programming that minimizes a 'maximum error' index. Either the Maximum Absolute Error,
%       Maximum Absolute Percentage Error, or the Maximum Absolute Relative Error.
%   c)  Weighted goal linear programming (WGP) that minimizes both a 'maximum error' and a 'sum of errors' indices (MinMax-MinSum approach).
%       This is implemented as a Lagrangian relaxation of a pre-emptive linear goal program, where the first objective is the minimization
%       of the maximum error index and the second objective is the minimization of a sum of errors index.
%       The Lagrangian relaxation weight the model gets penalized by violating the MinMax goal can be specified by the user.
%
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
%                    and n is the number of individual forecasts. n should be greater than 1.
%
%
% Optional Inputs:
%
%   'method':        - 'ip' (inverse proportion, default option)
%                    - 'ir' (inverse rank)
%                    - 'pp' (point performance)
%                    - 'ic' (information criterion)
%                    - 'ls' (constrained linear least squares)
%                    - 'lp' (linear programming)
%
%   'criterion':     The combination criterion.
%                    For 'ip' and 'pp', combination criteria are
%                       - 'se' (Squared Errors, the default option)
%                       - 'ae' (Absolute Errors)
%                       - 'spe' (Squared Percentage Errors)
%                       - 'ape' (Absolute Percentage Errors)
%                       - 'are' (Absolute Relative Errors)
%                    For 'ic', combinaiton criteria are
%                       - 'aic' (Akaike Information Criterion)
%                       - 'bic' (Bayesian Information Criterion, the default option)
%                    For 'lp', combination criteria are
%                       - 'sumae' (Minimizing the Sum of Absolute Errors, the default option)
%                       - 'maxae' (Minimizing the Maximum Absolute Error)
%                       - 'maxsumae' (Minimizing the Maximum and the Sum of the Absolute Errors, MinMaxMinSum WGP)
%                       - 'sumape' (Minimizing the Sum of Absolute Percentage Errors)
%                       - 'maxape' (Minimizing Maximum Absolute Percentage Error)
%                       - 'maxsumape' (Minimizing Maximum and Sum of Absolute Percentage Errors, WGP)
%                       - 'sumare' (Minimizing Sum of Absolute Relative Errors)
%                       - 'maxare' (Minimizing Maximum Absolute Relative Error)
%                       - 'maxsumare' (Minimizing Maximum and Sum of Absolute Relative Errors)
%                       If the users want to implement a WGP approach, they simply have to pick one of the 'maxsum...' criteria.
%
%   'variance':      A true/false Boolean variable for 'ip' only.
%                    If false, the combination weights are estimated according to the
%                    mean of the errors criterion. If the true, the combination weights
%                    are estimated according to the variance of the errors criterion.
%                    Default value is false.
%
%   'gpweight':      In case of a WGP ('lp' only), this is the lagrangian relaxation weight of the MinMax
%                    optimization criterion. The default value is 1.
%
%   'forecasts':     An o-by-n matrix of out-of-sample forecasts. o is the
%                    number of out of sample datapoints.
%
%   'tables':        A true/false Boolean variable. If true, results are
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
    parseObj.addParameter('method','ic');
    parseObj.addParameter('criterion','bic');
    parseObj.addParameter('variance',false);
    parseObj.addParameter('gpweight',1);
    parseObj.addParameter('forecasts',[]);
    parseObj.addParameter('tables',true);
    parseObj.addParameter('names',{});
    
    parseObj.parse(A,F,varargin{:});
    
    A = parseObj.Results.A;
    F = parseObj.Results.F;
    method = parseObj.Results.method;
    criterion = parseObj.Results.criterion;
    variance = parseObj.Results.variance;
    gpweight = parseObj.Results.gpweight;
    forecasts = parseObj.Results.forecasts;
    tables = parseObj.Results.tables;
    names = parseObj.Results.names;
    
        
%% Obtain the weights
    

    if isequal(method,'ip')     
%% Inverse proportion
        
        % Setting the criterion
        measure = criteria(criterion,A,F);
            
        % Check the variance
        if variance
            summeasure = var(measure);
            p = 2;
        else
            summeasure = mean(measure);
            p = 1;
        end % variance
    
        % Calculation of weights
        weights = transpose((summeasure.^-p)./sum(summeasure.^-p));
        
      
    elseif isequal(method,'ir')     
%% Inverse rank

        mse = transpose(mean((A-F).^2));
        [~,p] = sort(mse(:,1));
        w = transpose(1:length(mse(:,1)));
        w(p) = w;
        weights = (w.^-1)./sum(w.^-1);


    elseif isequal(method,'pp')
%% Point performance

        % Setting the criterion
        measure = criteria(criterion,A,F);
        
        for i = 1:size(F,2)
            w(i,1) = sum(double(kroneckerDelta(sym(measure(:,i)),sym(min(measure,[],2)))));
        end % i = 1:size(F,2)
        
        % Calculation of the weights
        weights = w./sum(w,1);


    elseif isequal(method,'ic')
%% Information criterion

        % Senection of the combination criterion
        for i = 1:size(F,2)
            b = fitlm(F(:,i),A(:,min(i,size(A,2))));
            if isequal(criterion,'aic')
                q(i,1) = b.ModelCriterion.AIC(1);
            else
                q(i,1) = b.ModelCriterion.BIC(1);
            end % isequal(criterion,'aic')
        end % i = 1:size(F,2)
        
        % Calculation of the weights
        weights = exp(-1./(2*q))./sum(exp(-1./(2*q)));


    elseif isequal(method,'ls')
%% Constraint least square approach
       Aall  = mean(A,2);
       weights = lsqlin(F,Aall,[],[],ones(1,size(F,2)),1,zeros(size(F,2),1));


    elseif isequal(method,'lp')
%% Linear programming    

        Aall = mean(A,2);

        if isequal(criterion,'maxae')
            din = 1;
            f = [zeros(1,size(F,2)), zeros(1,2*size(F,1)), 1];
        elseif isequal(criterion,'maxsumae')
            din = 1;
            f = [zeros(1,size(F,2)), ones(1,2*size(F,1)), gpweight];
        elseif isequal(criterion,'sumape')
            din = Aall;
            f = [zeros(1,size(F,2)), ones(1,2*size(F,1)), 0];
        elseif isequal(criterion,'maxape')
            din = Aall;
            f = [zeros(1,size(F,2)), zeros(1,2*size(F,1)), 1];
        elseif isequal(criterion,'maxsumape')
            din = Aall;
            f = [zeros(1,size(F,2)), ones(1,2*size(F,1)), gpweight];
        elseif isequal(criterion,'sumare')
            din = min(abs(A - F),[],2);
            f = [zeros(1,size(F,2)), ones(1,2*size(F,1)), 0];
        elseif isequal(criterion,'maxare')
            din = min(abs(A - F),[],2);
            f = [zeros(1,size(F,2)), zeros(1,2*size(F,1)), 1];
        elseif isequal(criterion,'maxsumare')
            din = min(abs(A - F),[],2);
            f = [zeros(1,size(F,2)), ones(1,2*size(F,1)), gpweight];
        else
            din = 1;
            f = [zeros(1,size(F,2)), ones(1,2*size(F,1)), 0];
        end % isequal(criterion,'maxae')

        % Setting constraints

        % Equality constraints
        A1 = [F./din, eye(size(F,1)), -eye(size(F,1)), zeros(size(F,1),1)];
        A2 = [ones(1,size(F,2)), zeros(1,2*size(F,1)+1)];
        Aeq = [A1; A2];
        beq = [Aall./din; 1];

        % Inequality constraints
        A3 = [F./din, zeros(size(F,1),2*size(F,1)), -ones(size(F,1),1)];
        A4 = [-F./din, zeros(size(F,1),2*size(F,1)), -ones(size(F,1),1)];
        Ain = [A3; A4];
        bin = [Aall./din; -Aall./din];

        % Lower bound
        lb = zeros(size(Aeq,2),1);

        % Solve the linear program
        w = linprog(f,Ain,bin,Aeq,beq,lb);
    
        % Optaining the combination weights
        weights = w(1:size(F,2),1);


    end % isequal(method,'lp')


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

    end


%% Function 

    function measure = criteria(crit,a,f)

        if isequal(crit,'ae')
            measure = abs(a - f);
        elseif isequal(crit,'ape')
            measure = abs(a - f)./a;
        elseif isequal(crit,'are')
            measure = abs(a - f)./min(abs(a - f),[],2);
        elseif isequal(crit,'spe')
            measure = ((a - f)./a).^2;
        else
            measure = (a - f).^2;
        end % isequal(crit,'ae')  

    end % measure = criteria(crit,a,f)

end % End of function