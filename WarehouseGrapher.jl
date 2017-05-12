using GraphPlot
using LightGraphs
using Colors
using Compose


# TODO Perhaps a switch statement
function nodeValue(char)
    if char == "O"
        return 2;
    elseif char == "I"
        return 6;
    elseif char == "H"
        return 10;
    end
end

#function edgeCost(map, start_x, start_y, end_x, end_y)
    # TODO Why is there a max() here?
    # return nodeValue(map[start_x,start_y],map[start_x,start_y])
#end


function isValidMove(element)
    if((element=="I")||(element=="O")||(element=="H"))
        return true
    else
        return false
    end
end

function checkNeighbour(map, adj_mat, dist_mat, i, j)

    # Offsets relative to the cell of interest
    for x_offset in [-1, 0, 1]
        for y_offset in [-1, 0, 1]
            # Check it isn't entering node [i,j] itself
            if((x_offset!=0)||(y_offset!=0))
                # Set the coordinate of the neighbour we are examining
                x = i + x_offset
                y = j + y_offset
                if ((x > 0) && (x <= size(map)[1]) && (y > 0) && (y <= size(map)[2]))
                    if isValidMove(map[x,y])
                        println("\tTRUE ",x," ",y, " ", map[x,y])
                        adj_mat[(i-1)*size(map)[1] + j, (x-1)*size(map)[1] + y] = true
                        dist_mat[(i-1)*size(map)[1] + j, (x-1)*size(map)[1] + y] = nodeValue(map[x,y])

                        println("\t\tTRUE ",(i-1)*size(map)[1] + j," ", (x-1)*size(map)[1] + (y));
                    else
                        #adj_mat[(i-1)*size(map)[1] + j, (x-1)*size(map)[1] + y] = false
                        #dist_mat[(i-1)*size(map)[1] + j, (x-1)*size(map)[1] + y] = 0
                        #println("\tFALSE ",x," ",y, " ", map[x,y])
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
        println(map[i,:]);
    end

    close(fp)

    return map
end


function generateMapGraph(map)
    

    #adj_mat = Array(Bool,size(map)[1]*size(map)[2],size(map)[1]*size(map)[2])
    adj_mat = fill(false, size(map)[1]*size(map)[2],size(map)[1]*size(map)[2]);

    #print(adj_mat);
    #dist_mat = Array(Int64,size(map)[1]*size(map)[2],size(map)[1]*size(map)[2])
    dist_mat = fill(0, size(map)[1]*size(map)[2],size(map)[1]*size(map)[2]);

    #node_counter = 1
    for i in 1:size(map)[1]
        for j in 1:size(map)[2]
            if((map[i,j]=="I")||(map[i,j]=="O")||(map[i,j]=="H")) 
                println("TRUE ",i," ",j)
                checkNeighbour(map, adj_mat, dist_mat, i, j)
                #node_counter = node_counter + 1;
            end
        end
    end

    # Generating a Directed Graph
    g = DiGraph(adj_mat)
    println(g)
    return g, dist_mat
end

#=
function main()
    filename = "/Users/Prakhar/Dropbox/Forklift/SmallWarehouseMap.csv"

    map = readMapCSV(filename,16,16)
    g , dist_mat = generateMapGraph(map)

    @time path = a_star(g, 31, 146, dist_mat);
    println(path);
    println(dist_mat[16:32,16:32])

    nodefillc = fill(colorant"lightseagreen", 256);

    for node in path
        #nodefillc[node[1]] = colorant"orange";
    end

    

    draw(PDF("nodes.pdf", 160cm, 160cm), gplot(g, nodelabel=1:256, nodefillc=nodefillc))
end
=#