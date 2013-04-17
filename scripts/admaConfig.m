function [ options ] = admaConfig()

  %% Add related folders
  addpath(fileparts(fileparts(mfilename('fullpath'))));
  addpath([fileparts(fileparts(mfilename('fullpath'))) '/adma']);
  addpath([fileparts(fileparts(mfilename('fullpath'))) '/helper']);
  %addpath('~/Documents/Diplomarbeit/MATLAB/Frameworks/epstk/m');
  addpath( '~/Documents/Diplomarbeit/MATLAB/Frameworks/databases/3ChanDMA/');



  %% SETTINGS
  %Folder
  
  resultDir = '~/Documents/Diplomarbeit/Simulation_Results/adma/';
  options.resultDir = resultDir;
  options.tmpDir = sprintf('%stmp/',resultDir);
  mkdir(resultDir);
  mkdir(options.tmpDir);

  % Parameter
  options.irDatabaseSampleRate = 48000;
  options.irDatabaseName = 'threeChanDMA';
  options.blockSize = 1024;

  % Tasks
  options.doConvolution = true;
  options.doTdRestore = false;
  options.do3ChanDMA = false;
  options.readFromFile = false;
  options.writeToFile = false;
end
