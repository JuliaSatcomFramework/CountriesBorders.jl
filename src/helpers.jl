floattype(::Type{<:CountryBorder{T}}) where {T} = T
floattype(::Type{<:DOMAIN{T}}) where {T} = T
floattype(::Type{<:Geometry{🌐,LATLON{T}}}) where T = T
floattype(::Type{<:Geometry{𝔼{2},CART{T}}}) where T = T
floattype(::Type{<:Union{LATLON{T}, CART{T}}}) where T = T
floattype(::Type{<:VALID_POINT{T}}) where T = T
floattype(x) = floattype(typeof(x))

function to_raw_coords(x)
    @warn "to_raw_coords is deprecated, use GeoPlottingHelpers.to_raw_lonlat instead (which is already a dependency of CountriesBorders)"
    to_raw_lonlat(x)
end

to_cart_point(T::Type{<:Real}, p::POINT_CART) = convert(POINT_CART{T}, p)
to_cart_point(T::Type{<:Real}, p::POINT_LATLON) = to_cart_point(T, Meshes.flat(p))
to_cart_point(T::Type{<:Real}, p::Union{LATLON, CART}) = to_cart_point(T, Point(p))
to_cart_point(T::Type{<:Real}) = Base.Fix1(to_cart_point, T)
to_cart_point(x) = to_cart_point(floattype(x), x)

to_latlon_point(T::Type{<:Real}, p::POINT_LATLON) = convert(POINT_LATLON{T}, p)
function to_latlon_point(T::Type{<:Real}, p::POINT_CART) 
    lon, lat = to_raw_lonlat(p)
    return LATLON{T}(lat * u"°", lon * u"°") |> Point
end
to_latlon_point(T::Type{<:Real}, p::Union{LATLON, CART}) = to_latlon_point(T, Point(p))
to_latlon_point(T::Type{<:Real}) = Base.Fix1(to_latlon_point, T)
to_latlon_point(x) = to_latlon_point(floattype(x), x)


"""
    cartesian_geometry([T::Type{<:Real}, ] geom)
    cartesian_geometry(T::Type{<:Real})

Convert geometries from LatLon to Cartesian coordinate systems, optionally changing the underlying machine type of the points to `T`

The second method simply returns a function that applies the conversion with the provided machine type to any geometry.

## Arguments
- `T::Type{<:Real}`: The desired machine type of the points in the output geometry. If not provided, it will default to the machine type of the input geometry.
- `geom`: The geometry to convert, which can be an arbitrary Geometry either in LatLon{WGS84Latest} or Cartesian2D{WGS84Latest} coordinates.

## Returns
- The converted geometry, with points of type `POINT_CART{T}`.
"""
function cartesian_geometry(T::Type{<:Real}, b::Union{BOX_LATLON, BOX_CART})
    b isa BOX_CART{T} && return b
    f = to_cart_point(T)
    return BOX_CART{T}(f(b.min), f(b.max))
end
function cartesian_geometry(T::Type{<:Real}, ring::Union{RING_CART, RING_LATLON})
    ring isa RING_CART{T} && return ring
    map(to_cart_point(T), vertices(ring)) |> Ring
end
function cartesian_geometry(T::Type{<:Real}, poly::Union{POLY_LATLON, POLY_CART})
    poly isa POLY_CART{T} && return poly
    map(cartesian_geometry(T), rings(poly)) |> splat(PolyArea)
end
function cartesian_geometry(T::Type{<:Real}, multi::Union{MULTI_LATLON, MULTI_CART})
    multi isa MULTI_CART{T} && return multi
    map(cartesian_geometry(T), parent(multi)) |> Multi
end
cartesian_geometry(T::Type{<:Real}) = Base.Fix1(cartesian_geometry, T)
cartesian_geometry(x) = cartesian_geometry(floattype(x), x)

"""
    latlon_geometry([T::Type{<:Real}, ] geom)
    latlon_geometry(T::Type{<:Real})

Convert geometries from Cartesian to LatLon coordinate systems, optionally changing the underlying machine type of the points to `T`

The second method simply returns a function that applies the conversion with the provided machine type to any geometry. 

## Arguments
- `T::Type{<:Real}`: The desired machine type of the points in the output geometry. If not provided, it will default to the machine type of the input geometry.
- `geom`: The geometry to convert, which can be an arbitrary Geometry either in LatLon{WGS84Latest} or Cartesian2D{WGS84Latest} coordinates.

## Returns
- The converted geometry, with points of type `POINT_LATLON{T}`.

"""
function latlon_geometry(T::Type{<:Real}, b::Union{BOX_LATLON, BOX_CART})
    b isa BOX_LATLON{T} && return b
    f = to_latlon_point(T)
    return BOX_LATLON{T}(f(b.min), f(b.max))
end
function latlon_geometry(T::Type{<:Real}, ring::Union{RING_CART, RING_LATLON})
    ring isa RING_LATLON{T} && return ring
    map(to_latlon_point(T), vertices(ring)) |> Ring
end
function latlon_geometry(T::Type{<:Real}, poly::Union{POLY_LATLON, POLY_CART})
    poly isa POLY_LATLON{T} && return poly
    map(latlon_geometry(T), rings(poly)) |> splat(PolyArea)
end
function latlon_geometry(T::Type{<:Real}, multi::Union{MULTI_LATLON, MULTI_CART})
    multi isa MULTI_LATLON{T} && return multi
    map(latlon_geometry(T), parent(multi)) |> Multi
end
latlon_geometry(T::Type{<:Real}) = Base.Fix1(latlon_geometry, T)
latlon_geometry(x) = latlon_geometry(floattype(x), x)


"""
    change_geometry(crs::Type{Cartesian}[, T::Type{<:Real}], x)
    change_geometry(crs::Type{LatLon}[, T::Type{<:Real}], x)
    change_geometry(crs[, T::Type{<:Real}])

Change the underlying CRS of a geometry from Cartesian to LatLon (or vice versa) and optionally change the underlying machine type of the points to `T`.

The last method only taking `Cartesian` or `LatLon` as input (and optionally the machine type `T`) simply returns a function that will apply the provided CRS (and optionally `T`) to any geometry used as input.

!!! note
    This method simply forwards the input to either the `cartesian_geometry` or `latlon_geometry` function based on the value of `crs`.
"""
change_geometry(::Type{Cartesian}, T::Type{<:Real}, x) = cartesian_geometry(T, x)
change_geometry(::Type{LatLon}, T::Type{<:Real}, x) = latlon_geometry(T, x)
change_geometry(crs::Union{Type{Cartesian}, Type{LatLon}}, x) = change_geometry(crs, floattype(x), x)
change_geometry(crs::Union{Type{Cartesian}, Type{LatLon}}) = Base.Fix1(change_geometry, crs)
change_geometry(::Type{Cartesian}, ::Type{T}) where {T <: Real} = x -> change_geometry(Cartesian, T, x)
change_geometry(::Type{LatLon}, ::Type{T}) where {T <: Real} = x -> change_geometry(LatLon, T, x)

function check_resolution(resolution::Union{Nothing, Real}; force::Bool = false)
    force && isnothing(resolution) && throw(ArgumentError("You can't force a computation without specifying the resolution"))
    resolution = @something resolution RESOLUTION[] DEFAULT_RESOLUTION[]
    resolution in (10, 50, 110) || throw(ArgumentError("The resolution can only be `nothing` or an integer value among `10`, `50` and `110`"))
    return Int(resolution)
end

function remove_polyareas!(cb::CountryBorder, idx::Int)
    (; valid_polyareas, latlon, cart, admin, resolution) = cb
    ngeoms = length(valid_polyareas)
    @assert idx ≤ ngeoms "You are trying to remove the $idx-th PolyArea from $(admin) but that country is only composed of $ngeoms PolyAreas for the considered resolution ($(resolution)m)."
    if !valid_polyareas[idx] 
        @info "The $idx-th PolyArea in $(admin) has already been removed"
        return cb
    end
    @assert sum(valid_polyareas) > 1 "You can't remove all PolyAreas from a `CountryBorder` object"
    # We find the idx while accounting for already removed polyareas
    current_idx = @views sum(valid_polyareas[1:idx])
    for g in (latlon, cart)
        deleteat!(g.geoms, current_idx)
    end
    deleteat!(cb.bboxes, current_idx)
    valid_polyareas[idx] = false
    return cb
end
function remove_polyareas!(cb::CountryBorder, idxs)
    for idx in idxs
        remove_polyareas!(cb, idx)
    end
    return cb
end