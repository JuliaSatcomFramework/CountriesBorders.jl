module GeoTablesConversion
    using CoordRefSystems: CoordRefSystems, LatLon
    using Meshes: Meshes, Geometry, Multi, Point, coords, close, GeometrySet, Ring, PolyArea
    using CircularArrays: CircularArray
    using GeoTables: GeoTables, georef
    import Tables
    import GeoInterface as GI
    using Unitful: Unitful, @u_str

    # Types
    using GeoBasics: POINT_LATLON, GeoBorders, polyareas
    using ..CountriesBorders: CountryBorder

    include("conversion_utils.jl")
end
