module CountriesBorders

using GeoTables
using Meshes
using Meshes: 🌐, printelms
using GeoInterface
using Tables
using GeoJSON
using GeoPlottingHelpers: GeoPlottingHelpers, with_settings, extract_latlon_coords, extract_latlon_coords!, geo_plotly_trace
using Artifacts
using Unitful: Unitful, ustrip, @u_str
using PrecompileTools
using NaturalEarth: NaturalEarth, naturalearth
using CoordRefSystems
using CoordRefSystems: Deg, Met

export extract_countries, SKIP_NONCONTINENTAL_EU, SkipFromAdmin, SimpleLatLon, LatLon, Point

include("GeoTablesConversion.jl")
using .GeoTablesConversion
using .GeoTablesConversion: VALID_POINT, LATLON, CART, VALID_RING, GSET, POLY_CART, BOX_CART, POINT_LATLON, POINT_CART, MULTI_CART
export CountryBorder

const SimpleLatLon = LatLon
const RegionBorders{T} = Union{CountryBorder{T}, DOMAIN{T}}

include("geotable.jl")
include("meshes_interface.jl")
include("skip_polyarea.jl")
include("implementation.jl")
include("plot_coordinates.jl")
export extract_plot_coords, extract_latlon_coords

@compile_workload begin
    table = get_geotable()
    dmn = extract_countries("italy; spain")
    rome = SimpleLatLon(41.9, 12.49)
    rome in dmn # Returns true
end

end # module CountriesBorders
