module CountriesBorders

using BasicTypes: BasicTypes, valuetype
using GeoTables
using CoordRefSystems: CoordRefSystems, LatLon, Cartesian2D, WGS84Latest, Deg, Met, Cartesian
using Meshes: Meshes, Geometry, CRS, 🌐, Multi, 𝔼, Point, MultiPolygon, printelms, Ring, PolyArea, Box, GeometrySet, SubDomain, Domain
using Meshes: measure, nvertices, nelements, paramdim, centroid, boundingbox, to, volume, element, discretize, rings, vertices, simplexify, pointify, convexhull
using CircularArrays: CircularArrays, CircularArray
using GeoInterface
using Tables
using GeoJSON
using GeoPlottingHelpers: GeoPlottingHelpers, with_settings, extract_latlon_coords, extract_latlon_coords!, geo_plotly_trace, to_raw_lonlat, geom_iterable
using Artifacts
using Unitful: Unitful, ustrip, @u_str
using PrecompileTools
using NaturalEarth: NaturalEarth, naturalearth
using ScopedValues: ScopedValues, ScopedValue, with

# Re-export form Meshes and CoordRefSystems
export LatLon, Point

include("types.jl")
export CountryBorder, SimpleLatLon, SkipFromAdmin, FastInRegion

# These two constants are used to customize the default resolution of the geotable with borders and coastlines
const DEFAULT_RESOLUTION = Ref{Int}(110)
const RESOLUTION = ScopedValue{Union{Int, Nothing}}(nothing)

include("helpers.jl")

include("GeoTablesConversion.jl")

include("countries_geotable.jl")

include("coastlines.jl")
export get_coastlines

# This file also defines `borders`
include("meshes_interface.jl")

include("skip_polyarea.jl")
export SKIP_NONCONTINENTAL_EU

include("implementation.jl")
export extract_countries

include("plot_coordinates.jl")
export extract_plot_coords, extract_latlon_coords

include("show.jl")

@compile_workload begin
    table = get_geotable()
    coastlines = get_coastlines()
    dmn = extract_countries("italy; spain")
    rome = SimpleLatLon(41.9, 12.49)
    rome in dmn # Returns true
end

end # module CountriesBorders
