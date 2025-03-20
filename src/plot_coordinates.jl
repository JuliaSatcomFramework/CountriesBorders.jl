"""
    INSERT_NAN

ScopedValue use to control whether to insert NaN before each ring within `extract_plot_coords!` unless we are in the first ring being inserted.

Defaults to `true`
"""
const INSERT_NAN = Base.ScopedValues.ScopedValue{Bool}(true)

const VALID_PLOT_COORD = Union{LATLON, CART, VALID_POINT}

# Extracting lat/lon coordaintes of the borders
function extract_plot_coords!(lat::Vector{T}, lon::Vector{T}, ll::LATLON) where T <: Number
    f(x) = convert(T, ustrip(x))
    push!(lat, f(ll.lat))
    push!(lon, f(ll.lon))
    return nothing
end
function extract_plot_coords!(lat::Vector{T}, lon::Vector{T}, c::CART) where T <: Number
    f(x) = convert(T, ustrip(x))
    push!(lat, f(c.y))
    push!(lon, f(c.x))
    return nothing
end
extract_plot_coords!(lat, lon, p::VALID_POINT) = extract_plot_coords!(lat, lon, coords(p))

function extract_plot_coords!(lat, lon, els::AbstractVector{<:VALID_PLOT_COORD})
    if INSERT_NAN[] && !isempty(lat) && !isempty(lon)
        extract_plot_coords!(lat, lon, LatLon(NaN, NaN))
    end
    for el in els
        extract_plot_coords!(lat, lon, el)
    end
    return nothing
end
function extract_plot_coords!(lat, lon, els::AbstractVector)
    for el in els
        extract_plot_coords!(lat, lon, el)
    end
    return nothing
end

function extract_plot_coords!(lat, lon, ring::VALID_RING)
    if INSERT_NAN[] && !isempty(lat) && !isempty(lon)
        extract_plot_coords!(lat, lon, LatLon(NaN, NaN))
    end
    # Insert the coordinates of each point of the ring
    for v in vertices(ring)
        extract_plot_coords!(lat, lon, v)
    end
    # We add the first point to the end of the array to close the ring
    extract_plot_coords!(lat, lon, first(vertices(ring)))
    return nothing
end

geom_iterable(pa::Union{Multi, PolyArea}) = rings(pa)
geom_iterable(cb::CountryBorder) = rings(borders(cb))
geom_iterable(d::Domain) = d

"""
    extract_plot_coords(inp)
Extract the lat and lon coordinates (in degrees) from the geometry/region `inp`
and return them in a `@NamedTuple{lat::Vector{Float32}, lon::Vector{Float32}`.

When `inp` is composed of multiple rings/polygons, the returned vectors `lat`
and `lon` contain the concateneated lat/lon values of each ring separated by
`NaN32` values. This is done to allow plotting multiple separated borders in a
single trace.
"""
function extract_plot_coords!(lat, lon, inp)
    applicable(geom_iterable, inp) || throw(ArgumentError("last input of `extract_plot_coords!` must implement the `geom_iterable` function to use the generic fallback. Alternatively, a specific method for `extract_plot_coords!(lat, lon, inp)` must be implemented for type $(typeof(inp))."))
    iterable = geom_iterable(inp)
	for geom ∈ iterable
        extract_plot_coords!(lat, lon, geom)
	end
    return nothing
end

"""
    extract_plot_coords([T::Type{<:AbstractFloat} = Float32], item)

Returns a NamedTuple with two vectors `lat` and `lon` containing the corresponding coordinates of all the points contained within the provided `item`.

This is mostly intended to simplify creation of the `lat` and `lon` keyword arguments to provide to the `scattergeo` function from `PlotlyBase`. By default points are converted to Float32 and NaN values are inserted between each `Ring` to allow plotting multiple polyareas within a single trace.
"""
function extract_plot_coords(T::Type{<:AbstractFloat}, item)
    lat = T[]
    lon = T[]
    extract_plot_coords!(lat, lon, item)
    return (; lat, lon)
end
extract_plot_coords(item) = extract_plot_coords(Float32, item)