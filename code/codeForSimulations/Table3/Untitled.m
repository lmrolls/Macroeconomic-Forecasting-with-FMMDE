DGP=3;thetaMethod = 1;
while thetaMethod <= 4 % Theta, the signal-to-noise parameter
    out = NaN(nIters, 2);
    
    parfor k = 1:nIters % Monte Carlo replications
        rng_seed_offset = n * 100 + T *1000 + r * 10000 + DGP * 100000 + thetaMethod * 1000000; % Ensure different seed base for each d
        rng(k + rng_seed_offset, 'twister'); % Set unique seed for each simulation iteration
        
        out(k, :) = SimulFun(T, n, k0, r, thetaMethod, DGP, pval, bootIter, cut);
        disp([k, thetaMethod, DGP, r, n, T]);
    end
    disp(['Mean success rate (r = ', num2str(r), ', DGP = ', num2str(DGP), ...
        ', thetaMethod = ', num2str(thetaMethod), '): ', ...
        num2str(mean(out == r))]);
    
    index = (r-2)*3 + DGP;
    
    % Store results based on sample size
    if n == 200 && T == 100
        finalTable.sequentialTest_n200_T100.rvar(index) = r;
        finalTable.sequentialTest_n200_T100.dgp(index) = DGP;
        finalTable.eigenvalueRatio_n200_T100.rvar(index) = r;
        finalTable.eigenvalueRatio_n200_T100.dgp(index) = DGP;
        
        if thetaMethod == 1
            finalTable.sequentialTest_n200_T100.rx05(index) = mean(out(:,1)==r);
            finalTable.eigenvalueRatio_n200_T100.rx05(index) = mean(out(:,2)==r);
        elseif thetaMethod == 2
            finalTable.sequentialTest_n200_T100.rx1(index) = mean(out(:,1)==r);
            finalTable.eigenvalueRatio_n200_T100.rx1(index) = mean(out(:,2)==r);
        elseif thetaMethod == 3
            finalTable.sequentialTest_n200_T100.rx3(index) = mean(out(:,1)==r);
            finalTable.eigenvalueRatio_n200_T100.rx3(index) = mean(out(:,2)==r);
        elseif thetaMethod == 4
            finalTable.sequentialTest_n200_T100.rx5(index) = mean(out(:,1)==r);
            finalTable.eigenvalueRatio_n200_T100.rx5(index) = mean(out(:,2)==r);
        end
    elseif n == 100 && T == 200
        finalTable.sequentialTest_n100_T200.rvar(index) = r;
        finalTable.sequentialTest_n100_T200.dgp(index) = DGP;
        finalTable.eigenvalueRatio_n100_T200.rvar(index) = r;
        finalTable.eigenvalueRatio_n100_T200.dgp(index) = DGP;
        
        if thetaMethod == 1
            finalTable.sequentialTest_n100_T200.rx05(index) = mean(out(:,1)==r);
            finalTable.eigenvalueRatio_n100_T200.rx05(index) = mean(out(:,2)==r);
        elseif thetaMethod == 2
            finalTable.sequentialTest_n100_T200.rx1(index) = mean(out(:,1)==r);
            finalTable.eigenvalueRatio_n100_T200.rx1(index) = mean(out(:,2)==r);
        elseif thetaMethod == 3
            finalTable.sequentialTest_n100_T200.rx3(index) = mean(out(:,1)==r);
            finalTable.eigenvalueRatio_n100_T200.rx3(index) = mean(out(:,2)==r);
        elseif thetaMethod == 4
            finalTable.sequentialTest_n100_T200.rx5(index) = mean(out(:,1)==r);
            finalTable.eigenvalueRatio_n100_T200.rx5(index) = mean(out(:,2)==r);
        end
    end
    save
    thetaMethod = thetaMethod + 1;
end