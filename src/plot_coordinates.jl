# These are internal ScopedValues used to control the behavior of `extract_plot_coords!`. They are mirrored by keys of the same name in the `PLOT_SETTINGS` Dict which is also a ScopedValue and should be from users to control the behavior of `extract_plot_coords!`.
# Specify whether to insert NaN before each vector of points within the lat/lon vectors
const INSERT_NAN = Base.ScopedValues.ScopedValue{Bool}(true)
#= 
Specify whether `extract_plot_coords!` should potentially add artificial points between each pair of input points in order to have lines appear straight on scattergeo plots. This can have a symbol and three valid values (In reality, every symbol that is not the first two will be treated as `:NONE`)
- `:NORMAL` will add artificial points only when necessary (when distance between points is too large) and will create lines that never cross the antimeridian. This is useful for example to plot Box geometries with large areas and have them still look like boxes.
- `:SHORT` will add artificial points like per `:NORMAL` but will also make sure the line drawn between the points is the shortest one (potentially crossing the antimeridian at 180° longitude).
- `:NONE` will not add artificial points
=#
const PLOT_STRAIGHT_LINES = Base.ScopedValues.ScopedValue{Symbol}(:NO)
#= 
Specify whether to close the vector of points by repeating the first point at the end of the vector.
=#
const CLOSE_VECTORS = Base.ScopedValues.ScopedValue{Bool}(false)

"""
    PLOT_SETTINGS

ScopedValue that contains the settings for `extract_plot_coords!`. It is a Dict with keys as symbol which can be used to customize the behavior of `extract_plot_coords!`.

Check the docstring of [`with_settings`](@ref) for the possible keys accepted for this Dict.
"""
const PLOT_SETTINGS = Base.ScopedValues.ScopedValue{Dict{Symbol, Any}}(Dict{Symbol, Any}())

"""
    with_settings(f, settings::Pair{Symbol, <:Any}...)

Convenience function to set the `PLOT_SETTINGS` ScopedValue to a Dict created from the key-value pairs in `settings` and call `f` with that `PLOT_SETTINGS` set.

The possible keys that can be provided as settings are:
- `:INSERT_NAN => Bool`: Specify whether to insert NaN before each vector of points within the lat/lon vectors.
- `:PLOT_STRAIGHT_LINES => Symbol`: Specify whether `extract_plot_coords!` should potentially add artificial points between each pair of input points in order to have lines appear straight on scattergeo plots. This can have a symbol and three valid values (In reality, every symbol that is not the first two will be treated as `:NONE`)
  - `:NORMAL` will add artificial points only when necessary (when distance between points is too large) and will create lines that never cross the antimeridian. This is useful for example to plot Box geometries with large areas and have them still look like boxes.
  - `:SHORT` will add artificial points like per `:NORMAL` but will also make sure the line drawn between the points is the shortest one (potentially crossing the antimeridian at 180° longitude).
  - `:NONE` will not add artificial points
- `:CLOSE_VECTORS => Bool`: Specify whether to close the vector of points by repeating the first point at the end of the vector.

This is essentially a convenience wrapper for:
```julia
Base.ScopedValues.with(CountriesBorders.PLOT_SETTINGS => Dict(settings...)) do
    f()
end
```
"""
with_settings(f, settings::AbstractVector) = with_settings(f, settings...)
function with_settings(f, settings::Pair{Symbol, <:Any}...)
    Base.ScopedValues.with(PLOT_SETTINGS => Dict(settings...)) do
        f()
    end
end

should_insert_nan() = get(PLOT_SETTINGS[], :INSERT_NAN, INSERT_NAN[])
should_shorten_straight_lines() = get(PLOT_SETTINGS[], :PLOT_STRAIGHT_LINES, PLOT_STRAIGHT_LINES[]) === :SHORT
should_oversample_points() = get(PLOT_SETTINGS[], :PLOT_STRAIGHT_LINES, PLOT_STRAIGHT_LINES[]) ∈ (:SHORT, :NORMAL)
should_close_vectors() = get(PLOT_SETTINGS[], :CLOSE_VECTORS, CLOSE_VECTORS[])

function crossing_latitude_flat((lon1, lat1), (lon2, lat2))
    Δlat = lat2 - lat1
    coeff = 180 - lon1
    den = lon2 + 360 - lon1
    if lon1 <= 0
        coeff = 180 + lon1
        den = lon1 + 360 - lon2
    end
    return lat1 + coeff * Δlat / den
end

#= 
This function will take two points in lat/lon and return a generator which produces more points to simulate straight lines on scattergeo plots. It has denser points closer to the poles as the distortion from scattergeo are more pronounced there.
This function is also extremely heuristic, and can probably be improved significantly in terms of the algorithm
=#
function line_plot_coords(start, stop)
    lon1, lat1 = to_raw_coords(start)
    lon2, lat2 = to_raw_coords(stop)
    Δlat = lat2 - lat1
    Δlon = lon2 - lon1
    if Δlon ≈ 0
        return (start,)
    end
    if abs(Δlon) > 180 && should_shorten_straight_lines()
        # We have to shorten and split at antimeridian
        mid_lat = crossing_latitude_flat((lon1, lat1), (lon2, lat2))
        return Iterators.flatten((
            line_plot_coords(LatLon(lat1, lon1), LatLon(mid_lat, copysign(180, lon1))),
            line_plot_coords(LatLon(mid_lat, copysign(180, lon2)), LatLon(lat2, lon2))
        ))
    end
    nrm = hypot(Δlat, Δlon)
    should_split = nrm > 10
    min_length = if should_split 
        10 
    else 
        maxlat = max(abs(lat1), abs(lat2))
        val = (100 / max(maxlat, 10)) 
        if maxlat > 65
            val /= 2
        end
        if maxlat > 80
            val /= 2
        end
        val
    end
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

function extract_plot_coords!(lat, lon, els::AbstractVector{<:VALID_PLOT_COORD})
    if should_insert_nan() && !isempty(lat) && !isempty(lon)
        extract_plot_coords!(lat, lon, LatLon(NaN, NaN))
    end
    if should_oversample_points()
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
    if should_close_vectors()
        extract_plot_coords!(lat, lon, first(els))
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
    # We plot the points in the ring
    Base.ScopedValues.with(CLOSE_VECTORS => true) do
        extract_plot_coords!(lat, lon, vertices(ring))
    end
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