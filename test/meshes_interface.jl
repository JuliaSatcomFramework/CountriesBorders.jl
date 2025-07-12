@testsnippet InterfacesSetup begin
    using Meshes
    using CountriesBorders
    using CountriesBorders.GeoBasics: to_multi, bboxes, polyareas, to_cartesian_point
    using CountriesBorders.BasicTypes: valuetype
    using CoordRefSystems
    using Test
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