"""
    CountryBorder{T} <: FastInGeometry{T}

Structure representings the coordinates of the borders of a country (based on the NaturalEarth database). 
`T` is the floating point precision of the borders coordinates, and defaults to Float32.

This structure holds the borders in both LatLon and Cartesian2D, to allow faster comparison with flattening approximation of the LatLon coordinates.

# Fields

- `admin::String`: The name of the country, i.e. the ADMIN entry in the GeoTable.
- `table_idx::Int`: The index of the country in the original GeoTable.
- `valid_polyareas::BitVector`: The indices of skipped PolyAreas in the original MultiPolygon of the country.
- `resolution::Int`: The resolution of the underlying border sampling from the NaturalEarth dataset.
- `borders::GeoBorders{T}`: The borders of the country.
"""
struct CountryBorder{T} <: FastInGeometry{T}
    "Name of the Country, i.e. the ADMIN entry in the GeoTable"
    admin::String
    "The index of the country in the original GeoTable"
    table_idx::Int
    "Indices of skipped PolyAreas in the original MultiPolygon of the country"
    valid_polyareas::BitVector
    "The resolution of the underlying border sampling from the NaturalEarth dataset"
    resolution::Int
    "The borders of the country"
    borders::GeoBorders{T}
end

const GSET{T} = @static if pkgversion(Meshes) < v"0.55.2" 
    GeoBasics.FastInGeometrySet{T, CountryBorder{T}} 
else 
    GeoBasics.FastInGeometrySet{T, CountryBorder{T}}{Vector{CountryBorder{T}}} 
end
const SUBDOMAIN{T} = GeoBasics.FastInSubDomain{T, GSET{T}}
const DOMAIN{T} = Union{GSET{T}, SUBDOMAIN{T}}

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
    raw_points::Vector{Vector{GeoBasics.POINT_LATLON{Float32}}}
end