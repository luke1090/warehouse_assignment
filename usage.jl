include("./WarehouseRoutePlanner.jl")

jobs = [Dict("job_id" => 1,
             "start_node" => 1084,
             "end_node" => 14147)
        ,Dict("job_id" => 2,
             "start_node" => 6731,
             "end_node" => 3202),
        Dict("job_id" => 3,
             "start_node" => 9488,
             "end_node" => 4975)
             ];

vehicles = [Dict("vehicle_id" => 1,
             "start_node" => 5093),
        Dict("vehicle_id" => 2,
             "start_node" => 168)];

mapfile = "120x120WarehouseMap.csv"

resolvedroutes = planroutes(mapfile,jobs,vehicles)

draw_path(mapfile, resolvedroutes[2], false);