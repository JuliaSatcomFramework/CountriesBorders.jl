const LATLON{T} = LatLon{WGS84Latest,Deg{T}}
const CART{T} = Cartesian2D{WGS84Latest,Met{T}}

const POINT_LATLON{T} = Point{🌐, LATLON{T}}
const POINT_CART{T} = Point{𝔼{2}, CART{T}}
const VALID_POINT{T} = Union{POINT_LATLON{T}, POINT_CART{T}}

const RING_LATLON{T} = Ring{🌐, LATLON{T}, CircularArray{POINT_LATLON{T}, 1, Vector{POINT_LATLON{T}}}}
const RING_CART{T} = Ring{𝔼{2}, CART{T}, CircularArray{POINT_CART{T}, 1, Vector{POINT_CART{T}}}}
const VALID_RING{T} = Union{RING_LATLON{T}, RING_CART{T}}

const POLY_LATLON{T} = PolyArea{🌐, LATLON{T}, RING_LATLON{T}, Vector{RING_LATLON{T}}}
const POLY_CART{T} = PolyArea{𝔼{2}, CART{T}, RING_CART{T}, Vector{RING_CART{T}}}

const MULTI_LATLON{T} = Multi{🌐, LATLON{T}, POLY_LATLON{T}}
const MULTI_CART{T} = Multi{𝔼{2}, CART{T}, POLY_CART{T}}

const BOX_LATLON{T} = Box{🌐, LATLON{T}}
const BOX_CART{T} = Box{𝔼{2}, CART{T}}

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
    "The bounding boxes of each polyarea within the country, mostly used for early filtering"
    bboxes::Vector{BOX_CART{T}}
    function CountryBorder(admin::String, latlon::MULTI_LATLON{T}, valid_polyareas::BitVector; resolution::Int, table_idx::Int) where {T}
        ngeoms = length(latlon.geoms)
        sum(valid_polyareas) === ngeoms || error("The number of set bits in the `valid_polyareas` vector must be equivalent to the number of PolyAreas in the `geom` input argument")
        cart = cartesian_geometry(latlon)
        bboxes = map(boundingbox, parent(cart))
        new{T}(admin, table_idx, valid_polyareas, resolution, latlon, cart, bboxes)
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


const GSET{T} = GeometrySet{🌐, LATLON{T}, CountryBorder{T}}
const SUBDOMAIN{T} = SubDomain{🌐, LATLON{T}, <:GSET{T}}
const DOMAIN{T} = Union{GSET{T}, SUBDOMAIN{T}}

