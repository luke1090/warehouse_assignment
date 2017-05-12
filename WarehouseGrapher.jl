using GraphPlot
using LightGraphs
using Colors
using Compose


global costs = Array(AbstractFloat, 1, 60 * 59 * 60 * 59);

#=
function computeCosts(target_node, x, y)
    # Take a vertex and convert it into (x,y)
    global costsMat = Array(AbstractFloat, 1, 60 * 59 * 60 * 59); # Global
    # First divide through by the map size
    for i in 1:x, j in 1:y
        # Convert to node number
        node_number = (i-1)*x + (j-1)*y + 1;
        println("i-1 ", i-1, " ");
        println("Node numb", node_number);

        target_x = floor(target_node / x);
        target_y = rem(target_node, y);
        dx = abs(i - target_x)
        dy = abs(j - target_y)
        D = 1; # Straight line move
        D2 = 1.41; # Diagonal move
        costsMat[node_number] = D * (dx + dy) + (D2 - 2 * D) * min(dx, dy);
    end

    costs = deepcopy(costsMat);
end
=#

target_node = 2698;
x = 60;
y = 59;
global costs = Array(Int64, 1, 60 * 60 + 59); # Global
# First divide through by the map size
for i in 1:x, j in 1:y
    # Convert to node number
    node_number = (i-0)*x + (j-0);
    #println("i-1 ", i-1, " ");
    println("(i,j) = (", i, ",", j, ")    nn=", node_number);
    println("Node numb", node_number);

    target_x = floor(target_node / x) + 1;
    target_y = rem(target_node, y);
    dx = abs(i - target_x)
    dy = abs(j - target_y)
    D = 1; # Straight line move
    D2 = 1.41; # Diagonal move
    costs[node_number] = round(D * (dx + dy) + (D2 - 2 * D) * min(dx, dy));

end



function heuristic(v)
    #println("Heurisitic returning ", convert(Int64, round(costs[v])));
    return costs[v];
end

function nodeValue(char)
    if char == "O"
        return 2;
    elseif char == "I"
        return 6;
    elseif char == "H"
        return 10;
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
                    #println("\tTRUE ",x," ",y, " ", map[x,y])
                    adj_mat[(i-1)*size(map)[1] + j, (x-1)*size(map)[1] + y] = true
                    dist_mat[(i-1)*size(map)[1] + j, (x-1)*size(map)[1] + y] = nodeValue(map[x,y])

                    #println("\t\tTRUE ",(i-1)*size(map)[1] + j," ", (x-1)*size(map)[1] + (y));
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
        println(map[i,:]);
    end

    close(fp)

    return map
end


function generateMapGraph(map)

    # Set up adjacency and distance matrices, prefill with 'empty'
    adj_mat = fill(false, size(map)[1]*size(map)[2],size(map)[1]*size(map)[2]);
    dist_mat = fill(0, size(map)[1]*size(map)[2],size(map)[1]*size(map)[2]);

    for i in 1:size(map)[1]
        for j in 1:size(map)[2]
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

function main()
    filename = "WarehouseMap.csv"
    x = 60;
    y = 59;

    start_node = 339;
    end_node = 2698;
    #computeCosts(end_node, x, y);

println("Entering readmap");
    map = readMapCSV(filename, x, y)

    println("Entering mapgraph");
    g, dist_mat = generateMapGraph(map)

    
    println("Entering solver");
    

    @time path = a_star(g, start_node, end_node, dist_mat, heuristic);


    #draw(PDF("nodes.pdf", 160cm, 160cm), gplot(g, nodelabel=1:x * y))
    println(path);
    #println(dist_mat[16:32,16:32])

    nodefillc = fill(colorant"lightseagreen", x * y);

    # Colour the nodes we travel through
    for node in path
        nodefillc[node[1]] = colorant"orange";
    end

    draw(PDF("nodes.pdf", 160cm, 160cm), gplot(g, nodelabel=1:x * y, nodefillc=nodefillc))
end

main();