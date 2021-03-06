function output = takanen2013(insig,fs,computationType,printFigs,printMap)
%TAKANEN2013   Binaural auditory model by Takanen, Santala, and Pulkki 2013
%   Usage:  output = takanen2013(insig,fs,computationType,printFigs);
%           output = takanen2013(insig,fs,computationType);
%           output = takanen2013(insig,fs);
%
%   Input parameters:
%        insig           : binaural input signal for which the binaural 
%                          activity map should be computed. Optionally, the
%                          output of the nonlinear cochlear model by Verhulst
%                          et. al. 2012 can be used as well
%        fs              : sampling rate
%        computationType : defines the type of output provided by the model
%                             1 := the binaural activity map (default)
%                             2 := the MSO and LSO model outputs
%        printFigs       : boolean value that defines whether several
%                          figures illustrating the processing steps in the
%                          model are plotted or not. As default, no figures
%                          are plotted.
%        printMap        : optional boolean value describing whether the
%                          resulting activity map is plotted (by default)
%                          or not. 
%
%   Output parameters:
%        output : A structure that contains different fields depending on
%                 the input arguments.
%
%   TAKANEN2013(insig,fs,computationType) computes either the binaural
%   activity map or the MSO and LSO model outputs from the binaural input
%   signal. 
%
%   If computationType==1, the output structure consists of:
%   
%      output.activityMap
%         Matrix that describes in which of the six
%         frequency ranges there is activation on a given
%         location on the map at a specific time instant
%
%      output.colorGains
%         Matrix that describes the signal level dependent gains for the
%         different activation values on the activityMap
%
%      output.colorMtrx
%         RGB color codes employed for the different
%         frequency ranges on the binaural activity map
%
%      output.levels
%         vector specifying the left/right location
%
%   If computationType==2, the output structure consists of:
%
%      output.leftMso
%         output of the MSO model projecting to the left hemisphere
%
%      output.leftLso
%         output of the LSO model projecting to the left hemisphere
%
%      output.leftWbMso
%         output of the wideband MSO model projecting to the left hemisphere
%
%      output.rightMso
%         output of the MSO model projecting to the right hemisphere
%
%      output.rightLso
%         output of the LSO model projecting to the right hemisphere
%
%      output.rightWbMso
%         output of the wideband MSO model projecting to the right hemisphere
%
%   Takanen, Santala and Pulkki presented a binaural auditory model that
%   uses the outputs of models of the medial superior olive (MSO), lateral
%   superior olive (LSO), following count-comparison principle (von Bekesy,
%   1930) to project the "what" processing stream output of the model of 
%   periphery on a one-dimensional binaural activity map.
%
%   The steps involved in the computation of the binaural activity map
%   consist of:
%
%     1) the given stimulus is processed with a model of periphery that
%        consists of a nonlinear time-domain model of cochlea by Verhulst
%        et. al. (2012) and of a model of cochlear nucleus
%
%     2) the binaural cues are decoded in the models of MSO, LSO and wide-
%        band MSO from the dorsal stream output of the periphery model
%
%     3) the outputs of the MSO and LSO models are mapped into directions
%        ranging from -90 to 90, and combined to form one set of "where"
%        cues for each hemisphere
%
%     4) the "where" cues are used to map the "what" cues originating from
%        the ventral stream output of the periphery models on a
%        topographically organized binaural activity map
%
%   See also: takanen2013periphery, takanen2013mso, takanen2013lso,
%             takanen2013wbmso, takanen2013directionmapping,
%             takanen2013cueconsistency, takanen2013onsetenhancement,
%             takanen2013formbinauralactivitymap
%
%   XXX The demo needs cleanup: demo_takanen2013
%
%   References:
%     G. von Békésy. Zur Theorie des Hörens. Über das Richtungshören bei
%     einer Zeitdifferenz oder Lautstärkeungleighheit der beiderseitigen
%     Schalleinwirkungen. Physik. Zeitschr., pages 824-835, 857-868, 1930.
%     
%     V. Pulkki and T. Hirvonen. Functional count-comparison model for
%     binaural decoding. Acta Acustica united with Acustica, 95(5):883 - 900,
%     Sept./Oct. 2009.
%     
%     M. Takanen, O. Santala, and V. Pulkki. Visualization of functional
%     count-comparison-based binaural auditory model output. Manuscript in
%     revision, 2013.
%     
%     M. Takanen, O. Santala, and V. Pulkki. Perceptually encoded signals and
%     their assessment. Manuscript in revision, 2013.
%     
%     S. Verhulst, T. Dau, and C. A. Shera. Nonlinear time-domain cochlear
%     model for transient stimulation and human otoacoustic emission. J.
%     Acoust. Soc. Am., 132(6):3842 - 3848, 2012.
%     
%
%   Url: http://amtoolbox.sourceforge.net/doc//binaural/takanen2013.php

% Copyright (C) 2009-2013 Peter L. Søndergaard and others.
% This file is part of AMToolbox version 0.9.1
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

%   AUTHOR: Marko Takanen, Olli Santala, Ville Pulkki
%
%   COPYRIGHT (C) 2013 Aalto University
%                      School of Electrical Engineering
%                      Department of Signal Processing and Acoustics
%                      Espoo, Finland
        
%% ------ Checking the input parameters -----------------------------------
%check the amount of inputs and set the parameters to default values, if
%necessary
if nargin<3
    printFigs=0;
    computationType=1;
end
if nargin<4
    printFigs=0;
end
if(nargin<5)
    printMap =1;
end
%some parameter values for the model
widthInErbs = 9; % the number of adjacent ERB bands the information is gathered over in wideband mso model
contraDelay = floor(0.0002*fs); %the what cues are delayed by 0.2 ms

%% ------ Modeling the first stages of the human auditory pathway ---------
disp('Model of periphery');
periph = takanen2013periphery(insig,fs,printFigs);

dims = size(periph.left);

%the left and right side where stream outputs of the periphery model are
%used as energies for the MSO and the LSO model (the energy of the
%wideband MSO model is different and decoded in the corresponding model)
cueEnergies.leftLso = periph.right;
cueEnergies.rightLso = periph.left;
cueEnergies.leftLso = [zeros(contraDelay,dims(2));cueEnergies.leftLso(1:end-contraDelay,:)];
cueEnergies.rightLso = [zeros(contraDelay,dims(2));cueEnergies.rightLso(1:end-contraDelay,:)];
%the cue energy for the MSO is otherwise the same as the one of LSO, except
%that the energies are set to zero above 1.5 kHz as the MSO cues are not
%computed above that limit
limit = find(periph.fc>=1500,1,'first');
cueEnergies.leftMso = [cueEnergies.leftLso(:,1:(limit-1)) zeros(dims(1),dims(2)-limit+1)];
cueEnergies.rightMso = [cueEnergies.rightLso(:,1:(limit-1)) zeros(dims(1),dims(2)-limit+1)];

disp('Models of MSO');
leftMso = takanen2013mso(periph.left,periph.right,fs,periph.fc,printFigs);
rightMso = takanen2013mso(periph.right,periph.left,fs,periph.fc,printFigs);

disp('Models of wideband MSO');
[leftWbMso cueEnergies.leftWbMso]= takanen2013wbmso(periph.left,periph.right,fs,widthInErbs,periph.fc,printFigs);
[rightWbMso cueEnergies.rightWbMso] = takanen2013wbmso(periph.right,periph.left,fs,widthInErbs,periph.fc,printFigs);

disp('Models of LSO');
leftLso = takanen2013lso(periph.right,periph.left,fs,periph.fc);
rightLso = takanen2013lso(periph.left,periph.right,fs,periph.fc);

%% ------ From directional cues to a binaural activity map ----------------
if(computationType==0)
    output.leftMso = leftMso;output.rightMso = rightMso;
    output.leftLso = leftLso;output.rightLso = rightLso;
    output.leftWbMso = leftWbMso;output.rightWbMso = rightWbMso;
else
    %% Direction mapping and cue combination
    
    %1) Mapping the MSO and LSO model outputs into azimuthal angles ranging
    %from -90 to 90
    disp('Direction mapping');
    [directionCues.leftMso,directionCues.leftLso,directionCues.leftWbMso] = takanen2013directionmapping(leftMso,leftLso,rightMso,leftWbMso);
    [directionCues.rightMso,directionCues.rightLso,directionCues.rightWbMso] = takanen2013directionmapping(rightMso,rightLso,leftMso,rightWbMso);
    
    %2) Check cue consistency
    [directionCues cueEnergies] = takanen2013cueconsistency(directionCues, cueEnergies,periph.fc);
    
    %3) Derive two sets of where cues, one for each hemisphere, from the six
    %directional cues
    
    % an offset of 20 degrees is added to the directional cues so that the
    % resulting values are not imaginary
    directionCues.leftMso = directionCues.leftMso+20;
    directionCues.rightMso = directionCues.rightMso+20;
    directionCues.leftLso = directionCues.leftLso+20;
    directionCues.rightLso = directionCues.rightLso+20;
    directionCues.leftWbMso = directionCues.leftWbMso+20;
    directionCues.rightWbMso = directionCues.rightWbMso+20;
    
    N = 3; % the cues are raised to third power to emphasize the values pointing more to the side
    whereLeft = ((cueEnergies.leftMso.*directionCues.leftMso.^N+cueEnergies.leftLso.*directionCues.leftLso.^N+...
        cueEnergies.leftWbMso.*directionCues.leftWbMso.^N).^(1/N))./...
        ((cueEnergies.leftMso+cueEnergies.leftLso+cueEnergies.leftWbMso+1e-30).^(1/N));
    whereRight = ((cueEnergies.rightMso.*directionCues.rightMso.^N+cueEnergies.rightLso.*directionCues.rightLso.^N+...
        cueEnergies.rightWbMso.*directionCues.rightWbMso.^N).^(1/N))./...
        ((cueEnergies.rightMso+cueEnergies.rightLso+cueEnergies.rightWbMso+1e-30).^(1/N));
    %the introduced offset is removed after the cues are combined
    whereLeft = whereLeft-20;
    whereRight = whereRight-20;
    
    %the ventral stream output of the periphery model is used as the what cue
    whatLeft = periph.ventralLeft;
    whatRight = periph.ventralRight;
    whatLeft = [zeros(contraDelay,dims(2));whatLeft(1:(end-contraDelay),:)];
    whatRight = [zeros(contraDelay,dims(2));whatRight(1:(end-contraDelay),:)];
    
    %% Onset contrast enhancement
    [whereLeft, whatLeft] = takanen2013onsetenhancement(whereLeft,whatLeft,fs,periph.fc);
    [whereRight, whatRight] = takanen2013onsetenhancement(whereRight,whatRight,fs,periph.fc);
    
    %% Forming of the binaural activity map
    [output.activityMap output.colorGains output.colorMtrx output.levels] = ...
        takanen2013formbinauralactivitymap(whereLeft,whereRight,whatLeft,whatRight,fs,periph.fc,printFigs,printMap);
end
