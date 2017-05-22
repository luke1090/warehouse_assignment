using GraphPlot
using LightGraphs
using Colors
using Compose


function computeCosts(start_node, target_node, costs, x_size, y_size)
    
    target_x, target_y = nodeToXY(target_node, x_size, y_size)
    start_x, start_y = nodeToXY(start_node, x_size, y_size)
    
    # Choosing to give preference to height or breadth
    dx = abs(start_x - target_x)
    dy = abs(start_y - target_y)
    
    if(dx>dy)
        w = 1
    else
        w = 0
    end

    # First divide through by the map size
    for i in 1:x_size, j in 1:y_size
        # Convert to node number
        node_number = xyToNode(i,j,x_size);
    
        dx = abs(i - target_x)
        dy = abs(j - target_y)

        D = 1; # Straight line move weight
        #D2 = 1.41; # Diagonal move weight
    
        costs[node_number] = round(50 * (D * ( ((0.1*w + 1) * dx) + ((0.1*(1-w) + 1) * dy) )))
        # round((D * (dx + dy))+ (D2 - 2 * D) * min(dx, dy)));
    end
end


function nodeToXY(node_number::Int64, x_size::Int64, y_size::Int64)
    x = Int64(floor(node_number / x_size) + 1);
    y = rem(node_number, y_size);
    return x,y ;
end

function xyToNode(x::Int64, y::Int64, x_size::Int64)
    return (x-1)*x_size + y;
end

function nodeValue(char)
    if char == "O"
        return 10;
    elseif char == "I"
        return 50;
    elseif char == "H"
        return 100;
    elseif char == "X"
        return 10000000;
    else
        return 10000000;
    end
end


function isValidMove(element)
    if((element=="I")||(element=="O")||(element=="H"))
        return true
    else
        return false
    end
end


function checkNeighbour(map, adj_mat, dist_mat, i, j)

    # Offsets relative to the cell of interest
    for x_offset in [-1, 0, 1], y_offset in [-1, 0, 1]
        # Check it isn't entering node [i,j] itself
        if (!(x_offset == 0 && y_offset == 0))
            # Set the coordinate of the neighbour we are examining
            x = i + x_offset;
            y = j + y_offset;
            if ((x > 0) && (x <= size(map)[1]) && (y > 0) && (y <= size(map)[2]))
                if isValidMove(map[x,y])
                    # We increase the cost of a diagonal path by 1.5, as it requires 'driving' a further distance
                    
                    if (x_offset == 0 || y_offset == 0)
                        # If at least one offset is 0, then it is a straight move
        			    adj_mat[(i-1)*size(map)[1] + j, (x-1)*size(map)[1] + y] = true
                        dist_mat[(i-1)*size(map)[1] + j, (x-1)*size(map)[1] + y] = nodeValue(map[x,y])                  
        		    
                    else 
                        # Diagonal moves only possible in outdoor zone.
                        if(map[i,j]=="O")
                            adj_mat[(i-1)*size(map)[1] + j, (x-1)*size(map)[1] + y] = true
                            diag_mult = 1.5;
                            dist_mat[(i-1)*size(map)[1] + j, (x-1)*size(map)[1] + y] = diag_mult * nodeValue(map[x,y])
                        end
                    end
                end
            end
        end
    end
end


function readMapCSV(filename, MAP_SIZE_X, MAP_SIZE_Y)
   
    fp = open(filename, "r")
    map = Array(String,MAP_SIZE_X,MAP_SIZE_Y)
    

    for i in 1:MAP_SIZE_X
        line = readline(fp)
        # Ensure we don't read more Y values than we intended
        map[i,:] = [strip(string(s)) for s in split(line,",")[1:MAP_SIZE_Y]]
        # println(map[i,:]);
    end

    close(fp)

    return map
end


function generateMapGraph(map)

    x, y = size(map);

    # Set up adjacency and distance matrices, prefill with 'empty'
    adj_mat = fill(false, x * y, x * y);
    dist_mat = fill(0, x * y, x * y);

    for i in 1:x
        for j in 1:y
            if((map[i,j]=="I")||(map[i,j]=="O")||(map[i,j]=="H")) 
                checkNeighbour(map, adj_mat, dist_mat, i, j)
            end
        end
    end

    # Generating a Directed Graph
    g = DiGraph(adj_mat)
    println(g)
    return g, dist_mat
end

function path_init(filename, x_size, y_size)

    w_map = readMapCSV(filename, x_size, y_size)
    g, dist_mat = generateMapGraph(w_map)

    return g, dist_mat, w_map
end


function draw_path(g, x_size, y_size, path, draw_node_labels)
    # Build the 2d layout for the visualisation of nodes
    locs_x = Array(Float64, 1, nv(g))
    locs_y = Array(Float64, 1, nv(g))

    for i in 1:x_size, j in 1:y_size
        locs_y[(i-1) * x_size + j] = i;
        locs_x[(i-1) * x_size + j] = j;
    end

    locs_x = vec(locs_x);
    locs_y = vec(locs_y);

    nodefillc = fill(colorant"lightseagreen", nv(g))
    edgestrokec = fill(colorant"white", ne(g))
    nodesize = fill(1.0, nv(g))

    # Colour the nodes we travelled through
    for node in path
        nodefillc[node] = colorant"orange"; # Color the from node orange
        nodesize[node] = 100000.0
    end

    if draw_node_labels
        draw(PDF("nodes.pdf", 160cm, 160cm), gplot(g, locs_x, locs_y, nodelabel=1:nv(g), nodefillc=nodefillc, edgestrokec=edgestrokec))
    else
        draw(PDF("nodes.pdf", 160cm, 160cm), gplot(g, locs_x, locs_y, nodefillc=nodefillc, edgestrokec=edgestrokec, nodesize=nodesize))
    end
    
end

# TODO: Not sure how this works.
function animate_path(g, x, y, path)
    # Build the 2d layout for the visualisation of nodes
    locs_x = Array(Float64, 1, x*y )#+ 59); # TODO Why + 59?
    locs_y = Array(Float64, 1, x*y )#+ 59);

    for i in 1:x, j in 1:y
        locs_y[(i-1) * x + j] = i;
        locs_x[(i-1) * x + j] = j;
    end

    locs_x = vec(locs_x);
    locs_y = vec(locs_y);

    nodefillc = fill(colorant"lightseagreen", x * y + 59); # TODO WHY 59

    # Colour the nodes we travelled through
    for (index, node) in enumerate(path)
        nodefillc[node[1]] = colorant"orange"; # Color the from node orange
        nodefillc[node[2]] = colorant"orange"; # Color the to node orange
        # Not the most efficient way of doing this, but it increases readability for a tiny performance penalty.
        # It might even be optimised out...
        
    end
    draw(PDF("nodes.pdf", 160cm, 160cm), gplot(g, locs_x, locs_y, nodelabel=1:x * y, nodefillc=nodefillc))
    #draw(PDF("nodes.pdf", 160cm, 160cm), gplot(g, locs_x, locs_y, nodelabel=1:x * y, nodefillc=nodefillc))
end


function calc_path_cost(path, dist_mat)

    path_cost = 0;

    # TODO So this isn't great...
    try
        for move in path
            path_cost += dist_mat[move[1], move[2]];
        end
    catch
        path_cost = 0;
    end

    return path_cost;
end


function path_main(start_node, end_node, g, dist_mat, x_size, y_size)

    # The first call to both @time and a_star will give inaccurate results, so we run it again
    #println("Compiling @time and a_star functions. Ignore two results below.");
    #@time path = a_star(g, start_node, end_node, dist_mat);

    costs = Array(Int64, 1, nv(g))

    heuristic = generateHeuristic(start_node, end_node, costs, x_size, y_size)
    #println("Planning path from ", start_node, " to ", end_node);
    path = a_star(g, start_node, end_node, dist_mat, heuristic);

    #=
    @time path = a_star(g, start_node, end_node, dist_mat, heuristic);

    println("Beginning timed trials for no heuristic.")
    @time path = a_star(g, start_node, end_node, dist_mat);
    @time path = a_star(g, start_node, end_node, dist_mat);
    @time path = a_star(g, start_node, end_node, dist_mat);

    println("Beginning timed trials for heuristic.")
    @time path = a_star(g, start_node, end_node, dist_mat, heuristic);
    @time path = a_star(g, start_node, end_node, dist_mat, heuristic);
    @time path = a_star(g, start_node, end_node, dist_mat, heuristic);

    println(path)
    =#
    return path

end


function generateHeuristic(start_node, end_node, costs, x_size, y_size)
    
    computeCosts(start_node, end_node, costs , x_size, y_size);

    function heuristic(v)
        return costs[v];
    end

    return heuristic
end


function main(s,t,filename = "/Users/Prakhar/Dropbox/Forklift/WarehouseMap.csv",size=60)    

    # Functions run once
    g, dist_mat, map = path_init(filename,size,size)
    costs = Array(Int64, 1, nv(g))

    # Functions for each job
    heuristic = generateHeuristic(s, t, costs, size, size)
    @time path = a_star(g, s, t, dist_mat, heuristic);
    # TODO: Probably the dist_max being passed here would have to be scaled.
    println(calc_path_cost(path, dist_mat))

    draw_path(g, size, size, path)

end