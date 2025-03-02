module CountriesBorders

using GeoTables
using Meshes
using Meshes: 🌐, printelms
using GeoInterface
using Tables
using GeoJSON
using Artifacts
using Unitful: Unitful, ustrip
using PrecompileTools
using NaturalEarth: NaturalEarth, naturalearth
using CoordRefSystems
using CoordRefSystems: Deg, Met

export extract_countries, SKIP_NONCONTINENTAL_EU, SkipFromAdmin, SimpleLatLon, LatLon, Point
export CountryBorder

include("conversions.jl")

const SimpleLatLon = LatLon
const RegionBorders{T} = Union{CountryBorder{T}, DOMAIN{T}}

include("geotable.jl")
include("meshes_interface.jl")
include("skip_polyarea.jl")
include("implementation.jl")
include("plot_coordinates.jl")

@compile_workload begin
    table = get_geotable()
    dmn = extract_countries("italy; spain")
    rome = SimpleLatLon(41.9, 12.49)
    rome in dmn # Returns true
end

end # module CountriesBorders
