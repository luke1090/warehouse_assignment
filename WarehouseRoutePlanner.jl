include("./lazywarehouse.jl")
include("./collisionchecker.jl")
include("./WarehouseGrapher.jl")

# Initialise A* for a given map
#x = 120;
#y = 120;
#x_size = x;
#y_size = y;

#=
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
=#

function planroutes(mapfile::String,jobs::Array,vehicles::Array)

    @time begin
        g, dist_mat, w_map, x_size, y_size = path_init(mapfile);
        println("PATH_INIT =================")
    end
    
    #=
    @time 
        println("draw_path")
        draw_path(mapfile, [], true);
    end
    =#

    @time begin

        for job in jobs
            i, j = nodeToXY(job["start_node"], x_size, y_size);
            println("Node: ", job["start_node"], " is ", w_map[i, j]);
            i, j = nodeToXY(job["end_node"], x_size, y_size);
            println("Node: ", job["end_node"], " is ", w_map[i, j]);
        end

        for v in vehicles
            i, j = nodeToXY(v["start_node"], x_size, y_size);
            println("Node: ", v["start_node"], " is ", w_map[i, j]);
        end


        # define global constants for organizing the route array
        jobcount = size(jobs,1)
        vehiclecount = size(vehicles,1)

        u = jobcount + vehiclecount


        routecosts = Array(Int,u,u)
        # generated by pathcost module

        routedefinitions = Array(Any,u,u)
        # generated by A*

        nodecosts = Array(Int,x_size*y_size)
        # generated from map
        # 1 dim array nodecosts[1] = cost to traverse node1

        for (v_index, vehicle) in enumerate(vehicles)

            # Calculate vehicle to vehicle costs
            current_index = 1;
            for (v_other_index, vehicle_other) in enumerate(vehicles)
                route = path_main(vehicle["start_node"], vehicle_other["start_node"], g, dist_mat, x_size, y_size);
                cost_vehicle_start_to_job_start = calc_path_cost(route, dist_mat);
                routecosts[v_index, current_index] = cost_vehicle_start_to_job_start;
                routedefinitions[v_index, current_index] = route;
                current_index += 1;
            end

            current_index -= 1; # TODO Comment

            for (j_index, job) in enumerate(jobs)
                route = path_main(vehicle["start_node"], job["start_node"], g, dist_mat, x_size, y_size);

                cost_vehicle_start_to_job_start = calc_path_cost(route, dist_mat);
                routecosts[v_index, current_index + j_index] = cost_vehicle_start_to_job_start;
                routedefinitions[v_index, current_index + j_index] = route;
            end
        end

        for (j_index, job) in enumerate(jobs)
            # Calculate job to vehicle costs
            current_index = 1;
            for (v_index, vehicle) in enumerate(vehicles)
                route = path_main(job["end_node"], vehicle["start_node"], g, dist_mat, x_size, y_size);
                cost_vehicle_start_to_job_start = calc_path_cost(route, dist_mat);
                routecosts[j_index + size(vehicles)[1], current_index] = cost_vehicle_start_to_job_start;
                routedefinitions[j_index + size(vehicles)[1], current_index] = route;
                current_index += 1;
            end

            current_index -= 1; # TODO Comment

            for (j_other_index, job_other) in enumerate(jobs)
                route = path_main(job["end_node"], job_other["start_node"], g, dist_mat, x_size, y_size);

                cost_vehicle_start_to_job_start = calc_path_cost(route, dist_mat);
                routedefinitions[j_index + size(vehicles)[1], current_index + j_other_index] = route;
                routecosts[j_index + size(vehicles)[1], current_index + j_other_index] = cost_vehicle_start_to_job_start;
            end
        end

        # Flatten route definitions
        for i in 1:size(routedefinitions)[1], j in 1:size(routedefinitions)[2]
            flattened = [];

            # TODO Not ideal but gets the job done. This thing gets upset when it receives an empty (or undefined) route.
            try
                for (index, edge) in enumerate(routedefinitions[i,j])
                    if index == 1
                        append!(flattened, edge[1]);
                    end
                    append!(flattened, edge[2]);
                end
                routedefinitions[i, j] = flattened;
            catch
                routedefinitions[i, j] = [];
            end
        end
        
        println("COMPUTING ARRAYS =================")
    end
    
    @time begin
        routeplan = planroutes(routecosts, jobcount, vehiclecount)
        routeplots = plotroutes(routeplan, routedefinitions)

        for i in 1:x_size, j in 1:y_size
            index = (i - 1) * x_size + j;
            nodecosts[index] = nodeValue(w_map[i, j]);
        end
        
        println("RUNNING THE MIP =================")
    end

    @time begin
        animatedroutes = animateroutes(routeplots, nodecosts)
        resolvedroutes = resolvecollisions(animatedroutes)
        println("RESOLVE COLLISIONS ================")
    end
    
    return resolvedroutes
end

#draw_path(g , x_size, y_size, resolvedroutes[2], false);

#println("Resolved routes");
#println(resolvedroutes)