function plotroutes(routeplan::Array,routes::Array)
    
    vehicles = size(routeplan,1)
    println("plotting routes for ",vehicles," vehicles")
    actualroute = Array{Any}(vehicles)

    for v in eachindex(routeplan)
        println("vehicle ",v)
        startrow = v
        nextrow = v
        jobs = routeplan[v]
        vehicleroute = []

        for i in eachindex(jobs)
            startrow = nextrow
            nextrow = jobs[i]
            println("nextrow ", nextrow)

            append!(vehicleroute,routes[startrow,nextrow])
            println("updated route ",vehicleroute)

            if nextrow > vehicles
                # i.e. it is a job, not a start position
                #println("nextrow ", nextrow)
                append!(vehicleroute,routes[nextrow,nextrow])
                #println(vehicleroute)
            end
        end

        actualroute[v] = vehicleroute
    end

    #println("vehicle1 route", actualroute[1])
    #println("vehicle2 route", actualroute[2])
    #println(actualroute)
    return actualroute
end

#=
function findcollisions(AR::Array)
# takes some array of vehicle positions (routes) AR
#(row1/vehicle1) Any[1,2,3,8,13,18,17,16,16,17,18,13,8,9,10,10,9,8,3,2,1]
#(row2/vehicle2) Any[5,4,3,8,13,18,19,20,20,19,18,13,8,7, 6, 6,7,8,3,4,5]
#
# returns a matrix of collision information
    
    collisionMatrix = []
    # col 1: vehicles in a collision
    # col 2: location of collision
    # col 3: time of collision
    for v1 in 1:vehicles
        for v2 in v1+1:vehicles
            collisiontimes = find(AR[v1]-AR[v2] .== 0)
            collisionspaces = []
            collisionvehicles = Array{Any}(size(collisiontimes))
            for i in eachindex(collisiontimes)
                append!(collisionspaces,AR[v1][collisiontimes[i]])
                collisionvehicles[i] = [v1,v2]
            end

            subtotal = hcat(collisionvehicles, collisionspaces, collisiontimes)
            
            println("subtotal ",subtotal)
            
            if isempty(collisionMatrix)
                collisionMatrix = subtotal
            else
                collisionMatrix = vcat(collisionMatrix,subtotal)
            end
        end
    end
    
    return collisionMatrix
end=#


function animateroutes(AR::Array,nodecost::Array)
# takes an array of proposed routes and an array relating node number to node cost
# returns an animated array showing vehicle locations per timestep
    animatedroutes = Array{Any}(size(AR,1))
    
    for vehicle in eachindex(AR)
        #println("vehicle",vehicle)
        animatedroute = []
        for step in eachindex(AR[vehicle])
            node = AR[vehicle][step]
            squarecost = nodecost[node]
            for x in 1:(squarecost)
                append!(animatedroute,node)
            end
        end
        animatedroutes[vehicle] = animatedroute
    end
    return animatedroutes
end


#given job routes with conflicting timespaces
#find vehicle with greater slack
#-> add a "pause" node to that vehicle's route before the collision
#-> assumes that all vehicles have unique starting positions
#resolve collisions

function resolvecollisions(AR::Array)
    vehiclecount = size(AR,1)
    
    routelength = Array{Int}(vehiclecount)
    # find the length of each vehicles route
    for i in eachindex(AR)
    #println(i)
    routelength[i] = size(AR[i],1)
    end

    endtime = maximum(routelength)
    
    timeslider = 1
    
    while timeslider<=endtime
        
        #check if the cell exists, then compare to other rows if they exist
        # if a collision is detected,
        # find the vehicle with the shorter path
        # add a pause node to that path BEFORE the collision location
        for i in 1:vehiclecount
            if timeslider<=routelength[i]
                p1 = AR[i][timeslider]
                for j in i+1:vehiclecount
                    #println("vehicle",i," vs vehicle",j," at time",timeslider,"/",endtime)
                    if timeslider<=routelength[j]
                        p2 = AR[j][timeslider]
                        if p1==p2
                            # collision detected at node p1=p2
                            # this decision needs to be changed for multi-timestep collisions
                            # the pause node must be added to the vehicle that arrives LATER
                            # should only ever have to look back 1 timestep
                            if routelength[i]<=routelength[j]
                                # add pause in vehicle i
                                # default q value
                                q = i
                            else
                                # add pause in vehicle j
                                q = j
                            end
                            # then check if q value is consistent with arrival times
                            # if unequal arrival time then use that q instead
                            if AR[i][timeslider-1]==p1 && AR[j][timeslider-1]!=p1
                                q = j
                            elseif AR[i][timeslider-1]!=p1 && AR[j][timeslider-1]==p1
                                q = i
                            end
                            
                            println("adding pause to vehicle",q," at time",timeslider,"/",endtime)
                            insert!(AR[q],timeslider,AR[q][timeslider-1])
                            routelength[q] = size(AR[q],1)
                            endtime = maximum(routelength)
                        end
                    end
                end
            end
        end
        timeslider = timeslider+1
    end
    
    return AR
end