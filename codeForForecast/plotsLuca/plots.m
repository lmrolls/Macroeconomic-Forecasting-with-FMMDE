
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Autocorrelation Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 start_y      = 2011;
start_m      = 1;
Jwind = 119;
j0=start_sample-Jwind+1;
j = 697; % february
disp(datestr(dateX(j,:)))
x	     = data(j0:j,:);

namesV   = char('IP','UNRATE','PAYEMS','CPI');
namesV   = cellstr(namesV);

set(0,'DefaultAxesFontName','Times New Roman');
set(0,'DefaultTextFontName','Times New Roman');
set(0,'DefaultAxesFontSize',12);
set(0,'DefaultTextFontSize',35);
vV  = [6,24,32,103];

jt = 0;
for i = vV
    jt = jt +1;
    g1 = figure('Name','Sunspots Series');
    autocorr(x(:,i))
    title('')
    ylabel('')
    print(g1,namesV{jt},'-dpng',  '-vector','-r600')
    close all

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Factor Selection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nfactorsFinal = [];
 nfactorsFinal(:,1)=nfactors(:,1);
nfactorsFinal(:,2)=nfactorsEIG(:,1);
nfactorsFinal(:,3)=nfactorsBAI(:,1);


namesV   = char('Sequential Test','Eigenvalue Ratio','ICp2');
namesV   = cellstr(namesV);
set(0,'DefaultAxesFontName','Times New Roman');
set(0,'DefaultTextFontName','Times New Roman');
set(0,'DefaultAxesFontSize',18);
set(0,'DefaultTextFontSize',35);



length(nfactorsFinal)
nfactorsFinalOriginal = nfactorsFinal;
% Inside factor vectors computed starting from january 2011
% january 2020 109
% march 2020 111
% shock at may 2020 113
% plot up to november 119

nfactorsFinal = nfactorsFinal(1:120,:);
dn            = datetime(2011,1,01) + calmonths(0:119);


%###############################################################%
    datetick('x','YYYY')        % format axes as time
%markerShapes = {'d', 'o', 's', '^', 'v','*','x','.'};

plot(dn,nfactorsFinal(:,2),'--','Color', 'k',  'LineWidth',2.1);
hold on
plot(dn,nfactorsFinal(:,3),'-.','Color', 'k',  'LineWidth',1.0);
hold on
plot(dn,nfactorsFinal(:,1),'-','Color', 'k', 'LineWidth',2.1);
hold on


hold on



hold on



    ylim([0 13])
z=ylabel('Number of estimated factors by method','Interpreter','latex','FontSize',26);
%z.FontSize = 20;
%z.FontName = 'bold';
%set(gca,'XTickLabel',a,'fontsize',14,'FontWeight','bold')
lh = legend('Eigenvalue Ratio','IC$_{p2}$','Sequential Test','Interpreter','latex', 'Location', 'best');
   
lh.FontSize = 20;  %

grid on
set(gcf, 'Position', get(0, 'Screensize'));
exportgraphics(gca,'selectedFactors.pdf');
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



plot(dn,tempTotal{1}(:,1));%(:,1))  % plot some dummy date over the range
hold on
plot(dn,tempTotal{1}(:,2),'--');
plot(dn,tempTotal{1}(:,3),'-.');
datetick('x','YYYY')        % format axes as time
xlim([dn(1) dn(end)])          % fit axes to range of actual data

%title(namesV{i})
%ylabel(namesV{i},'fontsize',14)
ylim([-3 2.4])
legend('Factor$_1$','Factor$_2$','Factor$_3$','best','Interpreter','latex')
