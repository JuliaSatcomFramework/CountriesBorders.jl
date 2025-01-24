const LATLON{T} = LatLon{WGS84Latest,Deg{T}}
const CART{T} = Cartesian2D{WGS84Latest,Met{T}}

const POINT_LATLON{T} = Point{🌐, LATLON{T}}
const POINT_CART{T} = Point{𝔼{2}, CART{T}}
const VALID_POINT = Union{POINT_LATLON, POINT_CART}

const RING_LATLON{T} = Ring{🌐, LATLON{T}, CircularArray{POINT_LATLON{T}, 1, Vector{POINT_LATLON{T}}}}
const RING_CART{T} = Ring{𝔼{2}, CART{T}, CircularArray{POINT_CART{T}, 1, Vector{POINT_CART{T}}}}
const VALID_RING = Union{RING_LATLON, RING_CART}

const POLY_LATLON{T} = PolyArea{🌐, LATLON{T}, RING_LATLON{T}, Vector{RING_LATLON{T}}}
const POLY_CART{T} = PolyArea{𝔼{2}, CART{T}, RING_CART{T}, Vector{RING_CART{T}}}

const MULTI_LATLON{T} = Multi{🌐, LATLON{T}, POLY_LATLON{T}}
const MULTI_CART{T} = Multi{𝔼{2}, CART{T}, POLY_CART{T}}

"""
    CountryBorder{T} <: Geometry{🌐,LATLON{T}}

Structure representings the coordinates of the borders of a country (based on the NaturalEarth database). 
`T` is the floating point precision of the borders coordinates, and defaults to Float32.

This structure holds the borders in both LatLon and Cartesian2D, to allow faster comparison with flattening approximation of the LatLon coordinates.

# Fields

- `admin::String`: The name of the country, i.e. the ADMIN entry in the GeoTable.
- `table_idx::Int`: The index of the country in the original GeoTable.
- `valid_polyareas::BitVector`: The indices of skipped PolyAreas in the original MultiPolygon of the country.
- `resolution::Int`: The resolution of the underlying border sampling from the NaturalEarth dataset.
- `latlon::MULTI_LATLON{T}`: The borders in LatLon CRS.
- `cart::MULTI_LATLON{T}`: The borders in Cartesian2D CRS.
"""
struct CountryBorder{T} <: Geometry{🌐,LATLON{T}}
    "Name of the Country, i.e. the ADMIN entry in the GeoTable"
    admin::String
    "The index of the country in the original GeoTable"
    table_idx::Int
    "Indices of skipped PolyAreas in the original MultiPolygon of the country"
    valid_polyareas::BitVector
    "The resolution of the underlying border sampling from the NaturalEarth dataset"
    resolution::Int
    "The borders in LatLon CRS"
    latlon::MULTI_LATLON{T}
    "The borders in Cartesian2D CRS"
    cart::MULTI_CART{T}
    function CountryBorder(admin::String, latlon::MULTI_LATLON{T}, valid_polyareas::BitVector; resolution::Int, table_idx::Int) where {T}
        fix_lon_wrap!(latlon) # Fix singularities at the wrapping around 180° lon
        ngeoms = length(latlon.geoms)
        sum(valid_polyareas) === ngeoms || error("The number of set bits in the `valid_polyareas` vector must be equivalent to the number of PolyAreas in the `geom` input argument")
        cart = cartesian_geometry(latlon)
        new{T}(admin, table_idx, valid_polyareas, resolution, latlon, cart)
    end
end
function CountryBorder(admin::AbstractString, geom::POLY_LATLON, valid_polyareas = BitVector((true,)); kwargs...)
    multi = Multi([geom])
    CountryBorder(String(admin), multi, BitVector(valid_polyareas); kwargs...)
end
function CountryBorder(admin::AbstractString, multi::MULTI_LATLON, valid_polyareas = BitVector(ntuple(i -> true, length(multi.geoms))); kwargs...)
    CountryBorder(String(admin), multi, BitVector(valid_polyareas); kwargs...)
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
    valid_polyareas[idx] = false
    return cb
end
function remove_polyareas!(cb::CountryBorder, idxs)
    for idx in idxs
        remove_polyareas!(cb, idx)
    end
    return cb
end

# This function will cycle through all vertices of a ring and change points with
# longitude ≈ 180° to -180° in case the rest of the points have mostly negative
# longitude   
function fix_lon_wrap!(ring::RING_LATLON{T}) where T
    @static if pkgversion(CoordRefSystems) ≥ v"0.12.1"
        return nothing # CoordRefSystems.jl v0.12.1 fixed the underlying issue so we do nothing
    end
    verts = vertices(ring)
    get_lon(ll::LATLON) = ll.lon
    get_lon(p::Point) = coords(p) |> get_lon
    get_lon(v::AbstractVector{<:Point}) = Iterators.map(get_lon, v)
    any(≈(180°), get_lon(verts)) || return # No points have longitude ≈ 180°
    sum_lon = sum(lon -> lon ≈ 180° ? 0° : lon, get_lon(verts))
    for i in eachindex(verts)
        ll = coords(verts[i])
        if get_lon(ll) ≈ 180°
            lat = ll.lat
            #=
            Note: The line below works because the fully parametrized
            constructor LatLon{Datum, Deg}(lat, lon) does not perform any
            wrapping. This is an inner detail of CoordRefSystems.jl so it's not
            very robust.
            =#
            new_ll = LATLON{T}(lat, sum_lon > 0 ? 180° : -180°)
            verts[i] = Point(new_ll)
        end
    end
    nothing
end
fix_lon_wrap!(g::Union{Multi, PolyArea}) = foreach(fix_lon_wrap!, rings(g))


const GSET{T} = GeometrySet{🌐, LATLON{T}, CountryBorder{T}}
const SUBDOMAIN{T} = SubDomain{🌐, LATLON{T}, <:GSET{T}}
const DOMAIN{T} = Union{GSET{T}, SUBDOMAIN{T}}

"""
    cartesian_geometry(poly::PolyArea{🌐,<:LATLON})
    cartesian_geometry(multi::Multi{🌐,<:LATLON})

Convert geometries from LatLon to Cartesian coordinate systems.

## Arguments
- `poly::PolyArea{🌐,<:LATLON}`: A polygon in LatLon coordinates.
- `multi::Multi{🌐,<:LATLON}`: A multi-geometry in LatLon coordinates.

## Returns
- `PolyArea` or `Multi`: The converted geometry in Cartesian coordinate system.
"""
function cartesian_geometry(poly::PolyArea{🌐,<:LATLON})
    map(rings(poly)) do r
        map(Meshes.flat, vertices(r)) |> Ring
    end |> splat(PolyArea)
end
cartesian_geometry(multi::Multi{🌐,<:LATLON}) = map(cartesian_geometry, parent(multi)) |> Multi

"""
    latlon_geometry(poly::PolyArea{𝔼{2},<:CART})
    latlon_geometry(multi::Multi{𝔼{2},<:CART})

Convert geometries from Cartesian to LatLon coordinate systems.

## Arguments
- `poly::PolyArea{𝔼{2},<:CART}`: A polygon in Cartesian coordinates.
- `multi::Multi{𝔼{2},<:CART}`: A multi-geometry in Cartesian coordinates.

## Returns
- `PolyArea` or `Multi`: The converted geometry in LatLon coordinate system.
"""
function latlon_geometry(poly::PolyArea{𝔼{2},<:CART})
    map(rings(poly)) do r
        map(vertices(r)) do v
            LatLon{WGS84Latest}(coords(v).y |> ustrip, coords(v).x |> ustrip) |> Point
        end |> Ring
    end |> splat(PolyArea)
end
latlon_geometry(multi::Multi{𝔼{2},<:CART}) = map(latlon_geometry, parent(multi)) |> Multi