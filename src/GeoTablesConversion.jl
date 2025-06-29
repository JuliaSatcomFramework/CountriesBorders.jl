module GeoTablesConversion
    using CoordRefSystems: CoordRefSystems, LatLon
    using Meshes: Meshes, Geometry, Multi, Point, coords, close, GeometrySet, Ring, PolyArea
    using CircularArrays: CircularArray
    using GeoTables: GeoTables, georef
    import Tables
    import GeoInterface as GI
    using Unitful: Unitful, @u_str

    # Types
    using ..CountriesBorders: LATLON, CART, POINT_LATLON, POINT_CART, VALID_POINT, RING_LATLON, RING_CART, VALID_RING, POLY_LATLON, POLY_CART, MULTI_LATLON, MULTI_CART, BOX_LATLON, BOX_CART, CountryBorder, DOMAIN
    # Helpers
    using ..CountriesBorders: to_cart_point, to_latlon_point, valuetype, to_raw_coords, cartesian_geometry, latlon_geometry, change_geometry, remove_polyareas!

    export CountryBorder, DOMAIN, remove_polyareas!

    include("conversion_utils.jl")
end
