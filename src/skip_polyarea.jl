"""
    SkipFromAdmin(admin::AbstractString, idxs::AbstractVector{<:Integer})
    SkipFromAdmin(admin::AbstractString, idx::Int)
    SkipFromAdmin(admin::AbstractString, [::Colon])
Structure used to specify parts of countries to skip when generating contours with [`extract_countries`](@ref).

When instantiated with just a country name or with a name and an instance of the `Colon` (`:`), it will signal that the full country whose ADMIN name starts with `admin` (case sensitive) will be removed from the output of `extract_countries`.

If created with an `admin` name and a list of integer indices, the polygons at the provided indices will be removed from the `MultiPolyArea` associated to country `admin` if this is present in the output of `extract_countries`.

## Note
The constructor does not perform any validation to verify that the provided `admin` exists or that the provided `idxs` are valid for indexing into the `MultiPolyArea` associated to the borders of `admin`.
"""
struct SkipFromAdmin
    admin::String
    idxs::Vector{Int}
    function SkipFromAdmin(admin::AbstractString, idxs::Vector{Int}) 
        @assert !isempty(idxs) "You can't initialize a SkipFromAdmin with an empty idxs vector as that represents skipping all PolyAreas. Call `SkipFromAdmin(admin, :)` if you want to explicitly skip all PolyAreas"
        @assert minimum(idxs) > 0 "One of the provided idxs is lower than 1, this is not allowed."
        sort!(idxs)
        unique!(idxs)
        new(String(admin), idxs)
    end
    SkipFromAdmin(admin::AbstractString, ::Colon) = new(String(admin), Int[])
end
SkipFromAdmin(admin, idxs::AbstractVector{<:Integer}) = SkipFromAdmin(admin, Int.(collect(idxs)))
SkipFromAdmin(admin, idx::Int) = SkipFromAdmin(admin, [idx])
SkipFromAdmin(admin::AbstractString) = SkipFromAdmin(admin, :)
SkipFromAdmin(t::Tuple{<:AbstractString, <:Any}) = SkipFromAdmin(t...)

skipall(s::SkipFromAdmin) = isempty(s.idxs)

function Base.merge!(a::SkipFromAdmin, bs::SkipFromAdmin...)
    @assert all(b -> b.admin == a.admin, bs) "You are trying to merge two `SkipFromAdmin` instances with different admin names"
    # If the first already skips all, we just return it
    skipall(a) && return a
    if any(skipall, bs)
        # We empty the idxs of a
        empty!(a.idxs)
    else
        for b in bs
            append!(a.idxs, b.idxs)
        end
        sort!(a.idxs)
        unique!(a.idxs)
    end
    return a
end
Base.merge(a::SkipFromAdmin, bs::SkipFromAdmin...) = merge!(deepcopy(a), bs...)

const SkipDict = Dict{String, SkipFromAdmin}

"""
    validate_skipDict(d::SkipDict; geotable = get_geotable())
Verify that the provided `SkipDict` contains only valid entries w.r.t. `geotable`.

An entry is valid if the `admin` name exists in `geotable` and if the corresponding `idxs` to be skipped are valid indices to the PolyAreas associated to the country identified by `admin`
"""
function validate_skipDict(d::SkipDict; geotable = get_geotable())
    ADMIN = geotable.ADMIN
    foreach(d) do (name, s)
        idxs = findall(startswith(name), ADMIN)
        l = length(idxs)
        @assert l > 0 error("The admin name '$name' has no match in the geotable, use the exact name of the country to generate `SkipFromAdmin` (Case sensitive)")
        @assert l < 2 error("The admin name '$name' matches more than one row of the geotable, use the exact name of the country to generate `SkipFromAdmin`")
        # If we skip all polyareas we just return without doing the last check
        skipall(s) && return
        idx = first(idxs)
        geom = geotable.geometry[idx]
        lg = geom isa Multi ? length(parent(geom)) : 1
        mi = maximum(s.idxs)
        @assert mi <= lg "The provided idxs to remove from '$name' have at laset one idx ($mi) which is greater than the number of PolyAreas associated to '$name' ($lg PolyAreas)"
    end
end

# We pass through a Dict to enforce uniqueness of the skipped admin names
skipDict(s::SkipFromAdmin) = SkipDict(s.admin => s)
skipDict(d::SkipDict) = d
skipDict(v::Vector{SkipFromAdmin}) = mergeSkipDict(v)
skipDict(x) = SkipFromAdmin(x) |> skipDict

# Taken basically from Base.merge(d::AbstractDict, others::AbstractDict...)
function Base.merge!(d::SkipDict, others::SkipDict...)
        for other in others
        if Base.haslength(d) && Base.haslength(other)
            sizehint!(d, length(d) + length(other))
        end
        for (k,v) in other
            if haskey(d, k)
                merge!(d[k], v)
            else
                d[k] = deepcopy(v)
            end
        end
    end
    return d
end

mergeSkipDict(args...) = merge(map(skipDict, args)...)
mergeSkipDict(v::AbstractVector) = mergeSkipDict(v...)

# We create a function to skip non continental EU polyareas
const SKIP_NONCONTINENTAL_EU = [
	SkipFromAdmin("France", 1) # This skips Guyana
	SkipFromAdmin("Norway", [
		1, 3, 4 # Continental Norway is the 2nd PolyArea only
	])
] |> skipDict