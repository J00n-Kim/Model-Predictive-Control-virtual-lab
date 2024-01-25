function [allData, scenario, sensor] = generateReference()
%test - Returns sensor detections
%    allData = test returns sensor detections in a structure
%    with time for an internally defined scenario and sensor suite.
%
%    [allData, scenario, sensors] = test optionally returns
%    the drivingScenario and detection generator objects.

% Generated by MATLAB(R) 9.14 (R2023a) and Automated Driving Toolbox 3.7 (R2023a).
% Generated on: 01-Aug-2023 13:15:41

% Create the drivingScenario object and ego car
[scenario, egoVehicle] = createDrivingScenario;

% Create all the sensors
sensor = createSensor(scenario);

allData = struct('Time', {}, 'ActorPoses', {}, 'ObjectDetections', {}, 'LaneDetections', {}, 'PointClouds', {}, 'INSMeasurements', {});
running = true;
while running

    % Generate the target poses of all actors relative to the ego vehicle
    poses = targetPoses(egoVehicle);
    time  = scenario.SimulationTime;

    % Generate detections for the sensor
    laneDetections = [];
    ptClouds = [];
    insMeas = [];
    [objectDetections, isValidTime] = sensor(poses, time);
    numObjects = length(objectDetections);
    objectDetections = objectDetections(1:numObjects);

    % Aggregate all detections into a structure for later use
    %if isValidTime
        allData(end + 1) = struct( ...
            'Time',       scenario.SimulationTime, ...
            'ActorPoses', actorPoses(scenario), ...
            'ObjectDetections', {objectDetections}, ...
            'LaneDetections', {laneDetections}, ...
            'PointClouds',   {ptClouds}, ... %#ok<AGROW>
            'INSMeasurements',   {insMeas}); %#ok<AGROW>
    %end

    % Advance the scenario one time step and exit the loop if the scenario is complete
    running = advance(scenario);
end

% Restart the driving scenario to return the actors to their initial positions.
restart(scenario);

% Release the sensor object so it can be used again.
release(sensor);

%%%%%%%%%%%%%%%%%%%%
% Helper functions %
%%%%%%%%%%%%%%%%%%%%

% Units used in createSensors and createDrivingScenario
% Distance/Position - meters
% Speed             - meters/second
% Angles            - degrees
% RCS Pattern       - dBsm

function sensor = createSensor(scenario)
% createSensors Returns all sensor objects to generate detections

% Assign into each sensor the physical and radar profiles for all actors
profiles = actorProfiles(scenario);
sensor = visionDetectionGenerator('SensorIndex', 1, ...
    'SensorLocation', [3.7 0], ...
    'MaxRange', 100, ...
    'DetectorOutput', 'Objects only', ...
    'Intrinsics', cameraIntrinsics([1814.81018227767 1814.81018227767],[320 240],[480 640]), ...
    'ActorProfiles', profiles);

function [scenario, egoVehicle] = createDrivingScenario
% createDrivingScenario Returns the drivingScenario defined in the Designer

% Construct a drivingScenario object.
scenario = drivingScenario;

% Add all road segments
roadCenters = [-15 2 0;
    150 2 0];
laneSpecification = lanespec(2);
road(scenario, roadCenters, 'Lanes', laneSpecification, 'Name', 'Road');

% Add the ego vehicle
egoVehicle = vehicle(scenario, ...
    'ClassID', 1, ...
    'Position', [-13.4719245054944 -0.142268773979098 0], ...
    'Mesh', driving.scenario.carMesh, ...
    'Name', 'Car');
waypoints = [-13.4719245054944 -0.142268773979098 0;
    14 -0.4 0;
    19.6 -0.8 0;
    23 -0.5 0;
    23.6 1.2 0;
    24.21 3.25 0.01;
    28.39 3.95 0.01;
    33.2 4 0;
    41.6 4 0;
    53.9 4 0;
    80.4 4 0];
speed = [15;15;15;15;15;15;15;15;15;15;15];
yaw =  [0;NaN;NaN;NaN;NaN;NaN;NaN;NaN;NaN;NaN;NaN];
trajectory(egoVehicle, waypoints, speed, 'Yaw', yaw);

% Old Path
% % Add all road segments
% roadCenters = [0 0 0;
%     150 0 0];
% laneSpecification = lanespec(2);
% road(scenario, roadCenters, 'Lanes', laneSpecification, 'Name', 'Road');
% 
% % Add the ego vehicle
% egoVehicle = vehicle(scenario, ...
%     'ClassID', 1, ...
%     'Position', [1.50795437905951 -2.09236578676633 0], ...
%     'Mesh', driving.scenario.carMesh, ...
%     'Name', 'Car');
% waypoints = [1.50795437905951 -2.09236578676633 0;
%     13 -2.4 0;
%     21.5 -1.7 0;
%     23 -0.5 0;
%     23.6 1.2 0;
%     27.3 2.4 0;
%     75.3 1.7 0];
% speed = [30;30;30;30;30;30;30];
% trajectory(egoVehicle, waypoints, speed);
