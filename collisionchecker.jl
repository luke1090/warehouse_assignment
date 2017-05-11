function plotroutes(vehicles::Int,routeplan::Array,routes::Array)

    actualroute = Array{Any}(vehicles)

    for v in eachindex(routeplan)
        #println("vehicle ",v)
        startrow = v
        nextrow = v
        jobs = routeplan[v]
        vehicleroute = []

        for i in eachindex(jobs)
            startrow = nextrow
            nextrow = jobs[i]
            #println("nextrow ", nextrow)

            append!(vehicleroute,routes[startrow,nextrow])
            #println(vehicleroute)

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
end