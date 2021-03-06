%preprocessing PAT EEG in fieldtrip

%% load data, triggers and define trials

%first move into correct folder
filename = 'AC25ROS161_PAT' % set the filename without extension (to enable automatic saving afterwards)
cfg = []; %prep
cfg.dataset = strcat(filename,'.cnt');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%% trigger
cfg.trialdef.eventtype = 'trigger';
cfg.trialdef.eventvalue = [(101:112)]; % define trials (begin tone: 101:112)until button press 201
cfg.trialdef.prestim =-1; %don't take the whole one minute
cfg.trialdef.poststim = 15.5;
cfg = ft_definetrial(cfg);

%% preprocessing settings
cfg.channel = [1:28] % don't think I need to exclude this here, but do it anyway
cfg.continuous = 'yes';
cfg.demean    = 'yes';
cfg.detrend = 'yes';
cfg.hpfreq = 1
cfg.lpfreq = 60;
%cfg.reref = 'EXG6'; %rereference to mastoid reference (not needed)
cfg.bsfilter = 'yes' % use the dft filter
cfg.bsfreq = [48 52];
cleandata = ft_preprocessing(cfg);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% OPTIONAL: Resample
cfg_res = [];
cfg_res.resamplefs = 512;
cleandata = ft_resampledata(cfg_res, cleandata);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% OPTIONAL: visual inspection of whole recording
cfg.viewmode  = 'vertical';
ft_databrowser(cfg,cleandata);
%% OPTIONAL: visual inspection of trials
cfg_vis = [];
cfg_vis.method = 'trial';
%cfg_vis.alim = 5e-5;
dummy = ft_rejectvisual(cfg_vis,cleandata);
   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%.
%% OPTIONAL: channel repair if on visual inspection any bad channels are obvious
% try to avoid as much as possible since channel repairs effect ICA efficacy!!
% Get nearest neighbours
cfg_rep                  = [];
cfg_rep.method           = 'template'
cfg_rep.layout           = 'biosemi64.lay';
[neighbours]             = ft_prepare_neighbours(cfg_rep,cleandata)
% Interpolate and put into new data structure
cfg_int                      = [];
cfg_int.badchannel           = {'Lz'}; % add bad channels
cfg_int.layout               = 'biosemi64.lay';
cfg_int.method               = 'nearest'; % set interpolation method
cfg_int.neighbours           = neighbours; % load neighbour layout
cfg_int.neighbourdist        = 0.13; %not too sure about this, its the default setting
artifact_cleandata           = ft_channelrepair(cfg_int,cleandata)

% or, if no channels are to be repaired
artifact_cleandata           = cleandata;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ICA denoising settings
cfg_ica = [];
cfg_ica.method  = 'runica';
cfg_ica.channel = 1:28; %EEG channels only, 64 minus the number of repaired channels (e.g. the fixed channel can not be independent)
datacomp = ft_componentanalysis(cfg_ica, artifact_cleandata);

%%  plot components
cfg_icapl = [];
cfg_icapl.channel = [1:15]; %components to be plotted
cfg_icapl.viewmode = 'component';
cfg_icapl.layout = 'biosemi64.lay';
cfg_icapl.continuous = 'yes';
cfg_icapl.blocksize = 30;
ft_databrowser(cfg_icapl, datacomp);

%% apply ica
%components = inputdlg('Enter components to be removed:','Components');
%components = str2num(cell2mat(components));
%cfg_ica.component = [component]
cfg_ica.component = [3 4 9]; %exact numbers will vary per individual
data_iccleaned = ft_rejectcomponent(cfg_ica, datacomp, artifact_cleandata); %clean and backpropagate clean data to 64-channels

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% OPTIONAL: visual inspection of whole recording
cfg.viewmode  = 'vertical';
ft_databrowser(cfg,data_iccleaned);
%% OPTIONAL: visual inspection of trials
cfg_vis = [];
cfg_vis.method = 'trial';
%cfg_vis.alim = 5e-5;
dummy = ft_rejectvisual(cfg_vis,data_iccleaned);
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Do some clean-up
savename = strcat('pp_',filename,'.mat');
save(savename, 'data_iccleaned');
clearvars
clc