module GeoTablesConversion
    using Meshes
    using Meshes: Geometry, Manifold, CRS, 🌐, Multi, 𝔼, Point, prettyname, printinds, MultiPolygon
    using CircularArrays: CircularArray
    using GeoTables
    using Tables
    import GeoInterface as GI
    using CoordRefSystems
    using CoordRefSystems: Deg, Met
    using Unitful
    using Unitful: °

    export CountryBorder, DOMAIN, remove_polyareas!

    include("main_type.jl")
    include("conversion_utils.jl")
end

using .GeoTablesConversion
using .GeoTablesConversion: VALID_POINT, LATLON, CART, VALID_RING, GSET
