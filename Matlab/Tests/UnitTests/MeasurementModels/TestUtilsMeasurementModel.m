
classdef TestUtilsMeasurementModel
    % Provides test utilities for the MeasurementModel class.
    
    % >> This function/class is part of the Nonlinear Estimation Toolbox
    %
    %    For more information, see https://bitbucket.org/nonlinearestimation/toolbox
    %
    %    Copyright (C) 2015  Jannik Steinbring <jannik.steinbring@kit.edu>
    %
    %                        Institute for Anthropomatics and Robotics
    %                        Chair for Intelligent Sensor-Actuator-Systems (ISAS)
    %                        Karlsruhe Institute of Technology (KIT), Germany
    %
    %                        http://isas.uka.de
    %
    %    This program is free software: you can redistribute it and/or modify
    %    it under the terms of the GNU General Public License as published by
    %    the Free Software Foundation, either version 3 of the License, or
    %    (at your option) any later version.
    %
    %    This program is distributed in the hope that it will be useful,
    %    but WITHOUT ANY WARRANTY; without even the implied warranty of
    %    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    %    GNU General Public License for more details.
    %
    %    You should have received a copy of the GNU General Public License
    %    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
    methods (Static)
        function [initState, measModel, ...
                  measurement, stateDecompDim, ...
                  trueStateMean, trueStateCov, ...
                  trueMeasMean, trueMeasCov] = getMeasModelData(stateDecomp)
            if nargin < 1
                stateDecomp = false;
            end
            
            initState = Gaussian(TestUtilsMeasurementModel.initMean, ...
                                 TestUtilsMeasurementModel.initCov);
            
            measModel = MeasModel(stateDecomp);
            measModel.setNoise(TestUtilsMeasurementModel.measNoise);
            
            if stateDecomp
                stateDecompDim = 1;
                
                mat = [measModel.measMatrix zeros(3, 1)];
            else
                stateDecompDim = 0;
                
                mat = measModel.measMatrix;
            end
            
            [noiseMean, noiseCov] = TestUtilsMeasurementModel.measNoise.getMeanAndCov();
            
            measurement = TestUtilsMeasurementModel.meas;
            
            trueMeasMean   = mat * TestUtilsMeasurementModel.initMean + noiseMean;
            trueMeasCov    = mat * TestUtilsMeasurementModel.initCov * mat' + noiseCov;
            invTrueMeasCov = trueMeasCov \ eye(3);
            crossCov       = TestUtilsMeasurementModel.initCov * mat';
            
            K = crossCov * invTrueMeasCov;
            
            trueStateMean = TestUtilsMeasurementModel.initMean + K * (measurement - trueMeasMean);
            trueStateCov  = TestUtilsMeasurementModel.initCov - K * crossCov';
        end
    end
    
    properties (Constant, Access = 'private')
        initMean  = [0.3 -pi]';
        initCov   = [0.5 0.1; 0.1 3];
        measNoise = Gaussian([2 -1 0.5]', [ 2   -0.5 0
                                           -0.5  1.3 0.5
                                            0    0.5 sqrt(2)]);
        meas      = [1, -2, 5]';
    end
end
