function check_resolution(resolution::Union{Nothing, Real}; force::Bool = false)
    force && isnothing(resolution) && throw(ArgumentError("You can't force a computation without specifying the resolution"))
    resolution = @something resolution RESOLUTION[] DEFAULT_RESOLUTION[]
    resolution in (10, 50, 110) || throw(ArgumentError("The resolution can only be `nothing` or an integer value among `10`, `50` and `110`"))
    return Int(resolution)
end

function remove_polyareas!(cb::CountryBorder, idx::Int)
    (; valid_polyareas, admin, resolution) = cb
    npolyareas = length(valid_polyareas)
    idx ≤ npolyareas || throw(ArgumentError("You are trying to remove the $idx-th PolyArea from $(admin) but that country is only composed of $npolyareas PolyAreas for the considered resolution ($(resolution)m)."))
    if !valid_polyareas[idx] 
        @info "The $idx-th PolyArea in $(admin) has already been removed"
        return cb
    end
    @assert sum(valid_polyareas) > 1 "You can't remove all PolyAreas from a `CountryBorder` object"
    # We find the idx while accounting for already removed polyareas
    current_idx = @views sum(valid_polyareas[1:idx])
    deleteat!(geoborders(cb), current_idx)
    valid_polyareas[idx] = false
    return cb
end
function remove_polyareas!(cb::CountryBorder, idxs)
    for idx in idxs
        remove_polyareas!(cb, idx)
    end
    return cb
end