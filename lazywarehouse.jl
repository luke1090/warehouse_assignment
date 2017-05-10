using JuMP
using Gurobi

# define global constants for organizing the route array
jobs = 5
vehicles = 2

u = vehicles+jobs
s = jobs
v = vehicles
# u = vehicle origins {x,y,...A,B,C,..}
# s = vehicle target positions {A',B',C'}

ui = 1:u
si = vehicles+1:u
vi = 1:v
xi = 1:v

# randomly generate a cost matrix - this will be done by c_ij
c = Array(Int,u,u)
rand!(c,1:u)
c = c - c.*eye(Int,u,u)


# some functions to parse the output of the MIP

function floatArrayfromJuMPArray(A::JuMP.JuMPArray)
# converts JuMP variables to julia primitives
    B = zeros(JuMP.size(A))
    
    for k in 1:JuMP.size(A,3)
        for j in 1:JuMP.size(A,2)
            for i in 1:JuMP.size(A,1)
                B[i,j,k] = A[i,j,k]
            end
        end
    end
    
    return B
end

function getroute(F::Array)
# expresses the route of the forklift as a list of jobs
    vex = size(F,3)
    route = Array{Any}(vex)
    for k in 1:vex
        println("vehicle ", k)
        row = k
        route[k] = Array{Int}(0)
        #println("start row = ", row)
        while size(find(F[row,:,k]),1) >= 1
            row = find(F[row,:,k])[1]
            #println("next row = ", row)
            append!(route[k],row)
            if row==k
                break
            end
        end
    end
    
    return route
end

function routeIsValid(R::Array)
    # check that the combined route covers all jobs
    # target value is at least jobs + 1 vehicle
    # this can break down if vehicles>jobs but that seems pretty unlikely
    # maybe change this out at some point / write a more robust one
    println(R)    
    return sum(size(R[i])[1] for i in eachindex(R)) >= u
end

m = Model(solver = GurobiSolver(Gurobi.Env()))

vmax = [50,50]
# vehicle maximum distance/time

@variable(m, flag[ui,ui,vi], Bin) # indicates a trip from i to j
@variable(m, venable[vi], Bin) # indicates that the forklift is in use

@objective(m, Min, sum(c[i,j]*flag[i,j,k] for i in ui, j in si, k in vi))

function cutInvalidRoutes(cb)
    floatArr = floatArrayfromJuMPArray(getvalue(flag))
    valid = routeIsValid(getroute(floatArr))
    
    if valid == false
        println("Found invalid subtours, cutting invalid solution")
        
        @lazyconstraint(cb, sum(floatArr[i,j,k]*flag[i,j,k] for i in ui, j in ui, k in vi) <= u-1)
        # the new solution must differ from the old one in at least one column
    end
end

addlazycallback(m, cutInvalidRoutes)

@constraint(m, [j in si], sum(flag[i,j,k] for i in ui, k in vi) == 1)
# travel to a job only once

@constraint(m, [j in xi], sum(flag[i,j,k] for i in ui, k in vi) <= 1)
# travel to a starting position up to one time

@constraint(m, [k in vi, j in ui], sum(flag[i,j,k] for i in ui) == sum(flag[j,i,k] for i in ui))
# for all destinations the vehicles in must equal the vehicles out

@constraint(m, [k in vi], sum(flag[i,j,k] for j in ui, i=k) == venable[k])
# for all vehicle origins (U - S) all vehicles must respect their starting position (stored in row s+k)

@constraint(m, [k in vi], sum(c[i,j]*flag[i,j,k] for i in ui, j in ui) <= venable[k]*vmax[k])
# each vehicle has a maximum distance/time to travel

@constraint(m, [i in ui], sum(flag[i,j,k] for k in vi, j=i) == 0)
# trips cannot start and end in the same node


@time begin
solve(m)
end

for k in vi
    println("vehicle ", k)
    for i in ui
        print(getvalue(flag[i,:,k]))
    end
end
println(getobjectivevalue(m))

for k in vi
    println("vehicle ", k, " distance: ",sum(c[i,j]*getvalue(flag[i,j,k]) for i in ui, j in si))
end

jumpflags = getvalue(flag)