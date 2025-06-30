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
    FastInRegion{T} <: Geometry{🌐,LATLON{T}}

Abstract type identifying regions where a fast custom algorithm for checking point inclusion in region is available. 

Subtypes of `FastInRegion` are expected to support support the `CountriesBorders.in_exit_early` function.
For most types, the default implementation is sufficient and translates into having a working method for the following two functions defined in CountriesBorders.jl:
- `polyareas`
- `bboxes`

See also [`CountriesBorders.in_exit_early`](@ref), [`CountriesBorders.polyareas`](@ref), [`CountriesBorders.bboxes`](@ref).
"""
abstract type FastInRegion{T} <: Geometry{🌐,LATLON{T}} end

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
struct CountryBorder{T} <: FastInRegion{T}
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
end

const GSET{T} = GeometrySet{🌐, LATLON{T}, CountryBorder{T}}
const SUBDOMAIN{T} = SubDomain{🌐, LATLON{T}, GSET{T}}
const DOMAIN{T} = Union{GSET{T}, SUBDOMAIN{T}}

const SimpleLatLon = LatLon # To Remove in next breaking
const RegionBorders{T} = Union{FastInRegion{T}, DOMAIN{T}}

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

const SkipDict = Dict{String, SkipFromAdmin}

"""
    CoastLines

This structure holds the raw points of the coastlines at a given resolution.

# Fields

- `resolution::Int`: The resolution of the coastlines.
- `raw_points::Vector{Vector{POINT_LATLON{Float32}}}`: The raw points of the coastlines.
"""
struct CoastLines
    resolution::Int
    raw_points::Vector{Vector{POINT_LATLON{Float32}}}
end

# Forwarding relevant meshes functions for the CountryBorder type
const VALID_CRS = Type{<:Union{LatLon, Cartesian}}