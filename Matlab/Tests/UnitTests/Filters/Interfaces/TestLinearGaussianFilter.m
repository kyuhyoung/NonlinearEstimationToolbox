
classdef TestLinearGaussianFilter < TestGaussianFilter
    % Provides unit tests for the LinearGaussianFilter class.
    
    % >> This function/class is part of the Nonlinear Estimation Toolbox
    %
    %    For more information, see https://bitbucket.org/nonlinearestimation/toolbox
    %
    %    Copyright (C) 2017  Jannik Steinbring <jannik.steinbring@kit.edu>
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
    
    methods (Test)
        function testSetMeasGatingThreshold(obj)
            f = obj.initFilter();
            
            f.setMeasGatingThreshold(0.5);
            
            obj.verifyEqual(f.getMeasGatingThreshold(), 0.5);
        end
        
        
        function testUpdateLinearMeasurementModel(obj)
            configs    = logical(dec2bin(0:15) - '0');
            numConfigs = 16;
            
            for i = 1:numConfigs
                obj.testUpdateLinearMeasurementModelConfiguration(configs(i, :));
            end
        end
    end
    
    methods (Access = 'protected')
        function defaultConstructorTests(obj, f)
            % Call superclass tests
            obj.defaultConstructorTests@TestGaussianFilter(f);
            
            % LinearGaussianFilter-related tests
            obj.verifyEqual(f.getMeasGatingThreshold(), 1);
        end
        
        function testUpdateLinearMeasurementModelConfiguration(obj, config)
            hasMeasMatrix  = config(1);
            stateDecomp    = config(2);
            postProcessing = config(3);
            measGating     = config(4);
            
            [initState, measModel, ...
             measurement, stateDecompDim, ...
             trueStateMean, trueStateCov, ...
             trueMeasMean, trueMeasCov] = TestUtilsLinearMeasurementModel.getMeasModelData(hasMeasMatrix, stateDecomp);
            
            f   = obj.initFilter();
            tol = sqrt(eps);
            
            f.setState(initState);
            
            if stateDecomp
                f.setStateDecompDim(stateDecompDim);
            end
            
            if postProcessing
                f.setUpdatePostProcessing(@TestGaussianFilter.postProcessingScale);
            end
            
            if measGating
                % Compute threshold that should fail
                dimMeas  = size(trueMeasMean, 1);
                measDist = (trueMeasMean - measurement)' * trueMeasCov^(-1) * (trueMeasMean - measurement);
                
                normalizedDist = chi2cdf(measDist, dimMeas);
                
                f.setMeasGatingThreshold(normalizedDist * 0.5);
                
                obj.verifyWarning(@() f.update(measModel, measurement), ...
                                  'Filter:IgnoringMeasurement');
                
                [stateMean, stateCov] = f.getStateMeanAndCov();
                
                [initStateMean, initStateCov] = initState.getMeanAndCov();
                
                % State estimate should not change
                obj.verifyEqual(stateMean, initStateMean);
                obj.verifyEqual(stateCov, stateCov');
                obj.verifyEqual(stateCov, initStateCov);
            else
                f.update(measModel, measurement);
                
                [stateMean, stateCov] = f.getStateMeanAndCov();
                
                if postProcessing
                    [trueStateMean, ...
                     trueStateCov] = TestGaussianFilter.postProcessingScale(trueStateMean, trueStateCov);
                end
                
                obj.verifyEqual(stateMean, trueStateMean, 'RelTol', tol);
                obj.verifyEqual(stateCov, stateCov');
                obj.verifyEqual(stateCov, trueStateCov, 'RelTol', tol);
            end
        end
        
        function [f, tol] = setupNonlinarPrediction(obj)
            f   = obj.initFilter();
            tol = sqrt(eps);
        end
    end
end