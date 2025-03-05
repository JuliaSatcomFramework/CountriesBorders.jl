@testsnippet InterfacesSetup begin
    using Meshes
    using CountriesBorders
    using CountriesBorders: borders
    using CoordRefSystems
    using Test
end

@testitem "Meshes interface" setup=[InterfacesSetup] begin
    italy = extract_countries("italy") |> only
    @test measure(italy) == measure(borders(LatLon, italy))
    @test nvertices(italy) == nvertices(borders(LatLon, italy))

    # Cartesian defaults
    @test convexhull(italy) == convexhull(borders(Cartesian, italy))
    @test boundingbox(italy) == boundingbox(borders(Cartesian, italy))
    @test centroid(italy) == centroid(borders(Cartesian, italy))
    @test discretize(italy) == discretize(borders(Cartesian, italy))
    @test rings(italy) == rings(borders(Cartesian, italy))
    @test vertices(italy) == vertices(borders(Cartesian, italy))
    @test simplexify(italy) == simplexify(borders(Cartesian, italy))
    @test pointify(italy) == pointify(borders(Cartesian, italy))
end

@testitem "Longitude Wrapping" setup=[InterfacesSetup] begin
    russia = extract_countries("russia")
    @test all(!in(russia), [LatLon(lat, -100) for lat in -30:.01:75])
end

@testitem "in_exit_early" setup=[InterfacesSetup] begin
    using CountriesBorders: in_exit_early, Cartesian, borders, DOMAIN, to_cart_point
    dmn = extract_countries("*")
    # Add consistency checks with the standard `in` method not doing exit early
    _in(p, cb::CountryBorder) = in(to_cart_point(p), borders(Cartesian, cb))
    _in(p, dm::DOMAIN) = any(_in(p, e) for e in dm)

    @test all(1:100) do _
        p = rand(Point; crs = LatLon)
        _in(p, dmn) == in(p, dmn)
    end
end