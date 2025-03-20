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
    export change_geometry, latlon_geometry, cartesian_geometry, to_cart_point, to_latlon_point, floattype, to_raw_coords

    include("main_type.jl")
    include("helpers.jl")
    include("conversion_utils.jl")
end
