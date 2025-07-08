@testsnippet InterfacesSetup begin
    using Meshes
    using CountriesBorders
    using CountriesBorders.GeoBasics: to_multi, bboxes, polyareas, to_cartesian_point
    using CountriesBorders.BasicTypes: valuetype
    using CoordRefSystems
    using Test
end

@testitem "Meshes interface" setup=[InterfacesSetup] begin
    italy = extract_countries("italy") |> only
    @test measure(italy) == measure(to_multi(LatLon, italy))
    @test nvertices(italy) == nvertices(to_multi(LatLon, italy))

    # Cartesian defaults
    @test convexhull(italy) == convexhull(to_multi(Cartesian, italy))
    @test boundingbox(italy) == boundingbox(to_multi(Cartesian, italy))
    @test centroid(italy) == centroid(to_multi(Cartesian, italy))
    @test discretize(italy) == discretize(to_multi(Cartesian, italy))
    @test rings(italy) == rings(to_multi(Cartesian, italy))
    @test vertices(italy) == vertices(to_multi(Cartesian, italy))
    @test simplexify(italy) == simplexify(to_multi(Cartesian, italy))
    @test pointify(italy) == pointify(to_multi(Cartesian, italy))
end

@testitem "Longitude Wrapping" setup=[InterfacesSetup] begin
    russia = extract_countries("russia")
    @test all(!in(russia), [LatLon(lat, -100) for lat in -30:.01:75])
end

@testitem "in_exit_early" setup=[InterfacesSetup] begin
    using CountriesBorders: DOMAIN
    using CountriesBorders.GeoBasics: in_exit_early, to_multi, to_cartesian_point
    using CoordRefSystems: CoordRefSystems, Cartesian
    dmn = extract_countries("*")
    # Add consistency checks with the standard `in` method not doing exit early
    _in(p, cb::CountryBorder) = in(to_cartesian_point(valuetype(cb), p), to_multi(Cartesian, cb))
    _in(p, dm::DOMAIN) = any(_in(p, e) for e in dm)

    @test all(1:100) do _
        p = rand(Point; crs = LatLon)
        _in(p, dmn) == in(p, dmn)
    end
end