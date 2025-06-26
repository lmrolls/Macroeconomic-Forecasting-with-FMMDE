function [weights, cf] = linprogcomb(A,F,varargin)
%
% Linear programming is applied to combine forecasts. The optimization objectives are:
%   a)  Single objective linear programming that minimizes a 'sum of errors' index. Either the Sum of Absolute Errors,
%       Sum of Absolute Percentage Errors, or Sum of Absolute Relative Errors (absolute errors of the combination over
%       absolute errors of the best individual forecasts of every data-point).
%   b)  Single objective linear programming that minimizes a 'maximum error' index. Either the Maximum Absolute Error,
%       Maximum Absolute Percentage Error, or the Maximum Absolute Relative Error.
%   c)  Weighted goal linear programming (WGP) that minimizes both a 'maximum error' and a 'sum of errors' indices (MinMax-MinSum approach).
%       This is implemented as a Lagrangian relaxation of a pre-emptive linear goal program, where the first objective is the minimization
%       of the maximum error index and the second objective is the minimization of a sum of errors index.
%       The Lagrangian relaxation weight the model gets penalized by violating the MinMax goal can be specified by the user.
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
%   F:               An m-by-n matrix. The individual forecasts, where m is the number of forecasted datapoints and n is the number of individual forecasts.
%                    n should be greater than 1.
%
% Optional Inputs:
%
%   'criterion':     The optimization criterion of the linear program. The alternatives are
%                       - 'sumae' (Minimizing the Sum of Absolute Errors, the default option)
%                       - 'maxae' (Minimizing the Maximum Absolute Error)
%                       - 'maxsumae' (Minimizing the Maximum and the Sum of the Absolute Errors, MinMaxMinSum WGP)
%                       - 'sumape' (Minimizing the Sum of Absolute Percentage Errors)
%                       - 'maxape' (Minimizing Maximum Absolute Percentage Error)
%                       - 'maxsumape' (Minimizing Maximum and Sum of Absolute Percentage Errors, WGP)
%                       - 'sumare' (Minimizing Sum of Absolute Relative Errors)
%                       - 'maxare' (Minimizing Maximum Absolute Relative Error)
%                       - 'maxsumare' (Minimizing Maximum and Sum of Absolute Relative Errors)
%                       If the users want to implement a WGP aproach, they simply have to pick one of the 'maxsum...' criteria..
%
%   'gpweight':      In case of a WGP, this is the lagrangian relaxation weight of the MinMax
%                    optimization criterion. The default value is 1.
%
%   'forecasts':     an o-by-n matrix of out-of-sample forecasts. o is the
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
    parseObj.addParameter('criterion','sumae');
    parseObj.addParameter('gpweight',1);
    parseObj.addParameter('forecasts',[]);
    parseObj.addParameter('tables',true);
    parseObj.addParameter('names',{});
    
    parseObj.parse(A,F,varargin{:});
    
    A = parseObj.Results.A;
    F = parseObj.Results.F;
    criterion = parseObj.Results.criterion;
    gpweight = parseObj.Results.gpweight;
    forecasts = parseObj.Results.forecasts;
    tables = parseObj.Results.tables;
    names = parseObj.Results.names;

    
%% Selection of the minimization criterion and the objective function

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

    
%% Setting up the constraints and solving the linear program

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
    
    
%% Obtain the weights
    
    % Combination weights
    weights = w(1:size(F,2),1);
    
    
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
    
end % Eand of function