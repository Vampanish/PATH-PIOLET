function run_lidar_simulation()
    % MATLAB LIDAR Vehicle Detection Simulation
    % This function runs the LIDAR simulation from drivsim.mat
    
    try
        % Load the simulation data
        if exist('drivsim.mat', 'file')
            load('drivsim.mat');
            fprintf('Loaded drivsim.mat successfully\n');
        else
            fprintf('drivsim.mat not found, creating mock simulation\n');
            create_mock_simulation();
        end
        
        % Initialize simulation parameters
        simulation_running = true;
        vehicle_count = 0;
        frame_count = 0;
        
        fprintf('Starting LIDAR vehicle detection simulation...\n');
        fprintf('SIMULATION_STATUS: STARTED\n');
        
        % Main simulation loop
        while simulation_running && frame_count < 1000  % Run for max 1000 frames
            % Simulate LIDAR scanning
            [lidar_points, detected_vehicles] = simulate_lidar_scan();
            
            % Count vehicles
            vehicle_count = length(detected_vehicles);
            
            % Output vehicle count for Flutter to read
            fprintf('VEHICLE_COUNT: %d\n', vehicle_count);
            
            % Output detailed simulation data as JSON
            sim_data = struct();
            sim_data.timestamp = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
            sim_data.vehicleCount = vehicle_count;
            sim_data.lidarPoints = lidar_points;
            sim_data.detectedVehicles = detected_vehicles;
            sim_data.sensorStatus = 'Active';
            sim_data.accuracy = 0.85 + rand() * 0.14; % 85-99% accuracy
            
            json_str = jsonencode(sim_data);
            fprintf('SIMULATION_DATA: %s\n', json_str);
            
            % Increment frame counter
            frame_count = frame_count + 1;
            
            % Pause for realistic simulation timing (2 seconds per frame)
            pause(2);
            
            % Check for stop condition (could be enhanced with file-based communication)
            if mod(frame_count, 10) == 0
                fprintf('Simulation frame %d completed\n', frame_count);
            end
        end
        
        fprintf('SIMULATION_STATUS: STOPPED\n');
        fprintf('Simulation completed after %d frames\n', frame_count);
        
    catch ME
        fprintf('Error in simulation: %s\n', ME.message);
        fprintf('SIMULATION_STATUS: ERROR\n');
    end
end

function [lidar_points, detected_vehicles] = simulate_lidar_scan()
    % Simulate LIDAR point cloud and vehicle detection
    
    % Generate random LIDAR points (simulating 360-degree scan)
    num_points = 800 + randi(400); % 800-1200 points
    
    % Create point cloud in polar coordinates, then convert to Cartesian
    angles = rand(num_points, 1) * 2 * pi; % 0 to 2π
    distances = 5 + rand(num_points, 1) * 45; % 5 to 50 meters
    heights = rand(num_points, 1) * 5; % 0 to 5 meters
    
    % Convert to Cartesian coordinates
    x = distances .* cos(angles);
    y = distances .* sin(angles);
    z = heights;
    
    % Add some noise for realism
    x = x + randn(size(x)) * 0.1;
    y = y + randn(size(y)) * 0.1;
    z = z + randn(size(z)) * 0.05;
    
    % Create intensity values
    intensity = rand(num_points, 1);
    
    % Package LIDAR points
    lidar_points = struct();
    for i = 1:min(num_points, 1000) % Limit to 1000 points for performance
        lidar_points(i).x = x(i);
        lidar_points(i).y = y(i);
        lidar_points(i).z = z(i);
        lidar_points(i).intensity = intensity(i);
    end
    
    % Vehicle detection algorithm (simplified)
    detected_vehicles = detect_vehicles_from_lidar(x, y, z);
end

function vehicles = detect_vehicles_from_lidar(x, y, z)
    % Simplified vehicle detection from LIDAR points
    
    % Cluster points to identify potential vehicles
    % This is a simplified version - real LIDAR processing is much more complex
    
    vehicle_count = randi([3, 15]); % Random 3-15 vehicles
    vehicles = struct();
    
    for i = 1:vehicle_count
        % Random vehicle positions within scan range
        angle = rand() * 2 * pi;
        distance = 10 + rand() * 30; % 10-40 meters from sensor
        
        vehicles(i).id = sprintf('vehicle_%d', i);
        vehicles(i).x = distance * cos(angle);
        vehicles(i).y = distance * sin(angle);
        vehicles(i).z = 0; % Assuming ground level
        vehicles(i).confidence = 0.7 + rand() * 0.3; % 70-100% confidence
        
        % Random vehicle type
        types = {'car', 'truck', 'motorcycle'};
        vehicles(i).type = types{randi(length(types))};
    end
end

function create_mock_simulation()
    % Create a mock simulation file if drivsim.mat doesn't exist
    fprintf('Creating mock simulation data...\n');
    
    % You can add your actual LIDAR data structure here
    simulation_data.name = 'LIDAR Vehicle Detection';
    simulation_data.version = '1.0';
    simulation_data.description = 'Mock LIDAR simulation for vehicle counting';
    simulation_data.created = datestr(now);
    
    % Save mock data (optional)
    % save('drivsim_mock.mat', 'simulation_data');
end

% Auto-start simulation when script is run
if ~exist('OCTAVE_VERSION', 'builtin')
    % Running in MATLAB
    run_lidar_simulation();
else
    % Running in Octave
    fprintf('Octave detected, running simulation...\n');
    run_lidar_simulation();
end