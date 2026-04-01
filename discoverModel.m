% discoverModel.m
% Loads the Simulink model in the background and prints all blocks and their types.

try
    % Load the model without opening the UI
    load_system('BatteryModel');
    
    % Find all blocks in the system
    blocks = find_system('BatteryModel', 'Type', 'block');
    
    fprintf('\n--- Simulink Blocks in BatteryModel ---\n');
    for i = 1:length(blocks)
        blk = blocks{i};
        % Get the type of the block
        blk_type = get_param(blk, 'BlockType');
        
        % Clean up the block name (replace newlines with spaces)
        blk_clean = strrep(blk, sprintf('\n'), ' ');
        
        fprintf('%s : %s\n', blk_clean, blk_type);
    end
    fprintf('---------------------------------------\n\n');
    
    % Close the system to free up memory without saving
    close_system('BatteryModel', 0);
catch ME
    % If an error occurs, print it and close the model safely
    fprintf('Error: %s\n', ME.message);
    try
        close_system('BatteryModel', 0);
    catch
    end
end
