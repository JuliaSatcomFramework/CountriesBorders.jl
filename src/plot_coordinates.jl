"""
    INSERT_NAN

ScopedValue use to control whether to insert NaN before each ring within `extract_plot_coords!` unless we are in the first ring being inserted.

Defaults to `true`
"""
const INSERT_NAN = Base.ScopedValues.ScopedValue{Bool}(true)

"""
    PLOT_STRAIGHT_LINES

ScopedValue use to control whether to plot straight lines between points within `extract_plot_coords!`.
It does so by inserting artifical points if two points in a vector are too far in longitude (and would result in a curved line on the `scattergeo` plot).

Defaults to `true`
"""
const PLOT_STRAIGHT_LINES = Base.ScopedValues.ScopedValue{Bool}(true)

# This function will take two points in lat/lon and return a generator which produces more points to simulate straight lines on scattergeo plots. It has denser points closer to the poles as the distortion from scattergeo are more pronounced there
function line_plot_coords(start, stop)
    lon1, lat1 = to_raw_coords(start)
    lon2, lat2 = to_raw_coords(stop)
    Δlat = lat2 - lat1
    Δlon = lon2 - lon1
    if Δlon ≈ 0
        return (start,)
    end
    nrm = hypot(Δlat, Δlon)
    should_split = nrm > 10
    min_length = should_split ? 10 : (200 / max(abs(lat1), abs(lat2), 10))
    npts = ceil(Int, nrm / min_length)
    lat_step = Δlat / npts
    lon_step = Δlon / npts
    f(n) = LatLon(lat1 + n * lat_step, lon1 + n * lon_step)
    ns = 0:(npts-1)
    if should_split
        Iterators.flatten(line_plot_coords(f(n), f(n + 1)) for n in ns)
    else
        (f(n) for n in 0:(npts-1))
    end
end

const VALID_PLOT_COORD = Union{LATLON,CART,VALID_POINT}

# Extracting lat/lon coordaintes of the borders
function extract_plot_coords!(lat::Vector{T}, lon::Vector{T}, ll::LATLON) where T<:Number
    f(x) = convert(T, ustrip(x))
    push!(lat, f(ll.lat))
    push!(lon, f(ll.lon))
    return nothing
end
function extract_plot_coords!(lat::Vector{T}, lon::Vector{T}, c::CART) where T<:Number
    f(x) = convert(T, ustrip(x))
    push!(lat, f(c.y))
    push!(lon, f(c.x))
    return nothing
end
extract_plot_coords!(lat, lon, p::VALID_POINT) = extract_plot_coords!(lat, lon, coords(p))

function extract_plot_coords!(lat, lon, els::AbstractVector{<:VALID_PLOT_COORD}; copy_first_point = false)
    if INSERT_NAN[] && !isempty(lat) && !isempty(lon)
        extract_plot_coords!(lat, lon, LatLon(NaN, NaN))
    end
    if PLOT_STRAIGHT_LINES[]
        for i in eachindex(els)[1:end-1]
            start = els[i]
            stop = els[i+1]
            for pt in line_plot_coords(start, stop)
                extract_plot_coords!(lat, lon, pt)
            end
        end
        # We have to put the last one again
        extract_plot_coords!(lat, lon, last(els))
    else
        for el in els
            extract_plot_coords!(lat, lon, el)
        end
    end
    if copy_first_point
        extract_plot_coords!(lat, lon, first(els))
    end
    return nothing
end
function extract_plot_coords!(lat, lon, els::AbstractVector; kwargs...)
    for el in els
        extract_plot_coords!(lat, lon, el; kwargs...)
    end
    return nothing
end

function extract_plot_coords!(lat, lon, ring::VALID_RING)
    # We plot the points in the ring
    extract_plot_coords!(lat, lon, vertices(ring); copy_first_point = true)
    return nothing
end

geom_iterable(pa::Union{Multi,PolyArea}) = rings(pa)
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
function extract_plot_coords!(lat, lon, inp; kwargs...)
    applicable(geom_iterable, inp) || throw(ArgumentError("last input of `extract_plot_coords!` must implement the `geom_iterable` function to use the generic fallback. Alternatively, a specific method for `extract_plot_coords!(lat, lon, inp)` must be implemented for type $(typeof(inp))."))
    iterable = geom_iterable(inp)
    for geom ∈ iterable
        extract_plot_coords!(lat, lon, geom; kwargs...)
    end
    return nothing
end

"""
    extract_plot_coords([T::Type{<:AbstractFloat} = Float32], item)

Returns a NamedTuple with two vectors `lat` and `lon` containing the corresponding coordinates of all the points contained within the provided `item`.

This is mostly intended to simplify creation of the `lat` and `lon` keyword arguments to provide to the `scattergeo` function from `PlotlyBase`. By default points are converted to Float32 and NaN values are inserted between each `Ring` to allow plotting multiple polyareas within a single trace.
"""
function extract_plot_coords(T::Type{<:AbstractFloat}, item; kwargs...)
    lat = T[]
    lon = T[]
    extract_plot_coords!(lat, lon, item; kwargs...)
    return (; lat, lon)
end
extract_plot_coords(item; kwargs...) = extract_plot_coords(Float32, item; kwargs...)