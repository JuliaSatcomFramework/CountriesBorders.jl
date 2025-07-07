@testsnippet setup_basic begin
    using CountriesBorders
    using CountriesBorders: possible_selector_values, valid_column_names, mergeSkipDict, validate_skipDict, skipall, SkipDict, skipDict, get_geotable, extract_plot_coords, borders, remove_polyareas!, valuetype, to_cart_point, change_geometry, Cartesian, in_exit_early, polyareas, latlon_geometry, cartesian_geometry, to_latlon_point
    using CountriesBorders.GeoTablesConversion: POINT_CART, POINT_LATLON, POLY_LATLON, POLY_CART, BOX_LATLON, BOX_CART
    using Meshes
    using CoordRefSystems
    using Test
    using Unitful
    using Meshes: WGS84Latest
    using Unitful: °
end

@testitem "Test Docstring Examples" setup=[setup_basic] begin
    example1 = extract_countries(;continent = "europe", admin="-russia")
    example2 = extract_countries(;admin="-russia", continent = "europe")
    example3 = extract_countries(;subregion = "*europe; -eastern europe")
    @test !isnothing(example1)
    @test !isnothing(example2)
    @test !isnothing(example3)
    @test length(example2) == length(example1) + 1
    @test !isnothing(extract_countries(;ConTinEnt = "Asia"))

    # We test the skip_areas example

    included_cities = cities = [
        LatLon(41.9, 12.49) # Rome
        LatLon(39.217, 9.113) # Cagliari
        LatLon(48.864, 2.349) # Paris
        LatLon(59.913, 10.738) # Oslo
    ] .|> Point

    excluded_cities = cities = [
        LatLon(37.5, 15.09) # Catania
        LatLon(40.416, -3.703) # Madrid
        LatLon(5.212, -52.773) # Guiana Space Center
        LatLon(78.222, 15.652) # Svalbard Museum
    ]

    # We don't use the const from the package to have more coverage
    Skip_noncontinental_eu =  [
        SkipFromAdmin("France", 1) # This skips Guyana
        SkipFromAdmin("Norway", [
            1, 3, 4 # Continental Norway is the 2nd PolyArea only
        ])
    ] |> skipDict

    dmn_excluded = extract_countries("italy; spain; france; norway"; skip_areas = [
        ("Italy", 2)
        "Spain"
        Skip_noncontinental_eu
    ])
    @test all(in(dmn_excluded), included_cities)
    @test all(!in(dmn_excluded), excluded_cities)

    dmn_full = extract_countries("italy; spain; france; norway")
    @test all(in(dmn_full), included_cities)
    @test all(in(dmn_full), excluded_cities)
end

@testitem "Misc Coverage" setup=[setup_basic] begin
    # We test the array method
    dm1 = extract_countries("italy; spain; france; norway")
    dm2 = extract_countries(["italy","spain","france","norway"])
    @test length(dm1) == length(dm2)

    # We test that sending a regex throws
    @test_throws "Vector{String}" extract_countries(; admin = r"france")

    # we do coverage for possible_selector_values and valid_column_names
    possible_selector_values()
    valid_column_names()

    # Test that extract_countries returns nothing if no matching country is found
    @test extract_countries("IDFSDF") === nothing

    # We test that "*" selects all countries
    dmn = extract_countries("*")
    @test length(dmn) == length(parent(dmn))

    # skip_polyarea coverage
    sfa1 = SkipFromAdmin("France", :)
    sfa2 = SkipFromAdmin("France", 1)
    sd = mergeSkipDict([
        sfa1
        sfa2
    ])

    @test sfa1 |> skipall # France should be skipall
    @test !skipall(sfa2)
    @test sd["France"] |> skipall # The merge should have kept the skipall

    validate_skipDict(sd) # Check it doesn't error
    @test_throws "more than one row" validate_skipDict(skipDict(("A", :)))
    @test_throws "no match" validate_skipDict(skipDict(("Axiuoiasdf", :)))
    @test_throws "greater than" validate_skipDict(skipDict(("Italy", 35)))

    sfa3 = merge(sfa2, sfa1)
    @test skipall(sfa3)
    @test !skipall(sfa2) # merge shouldn't have changed sfa2
    sfa4 = merge!(sfa2, sfa1)
    @test skipall(sfa4)
    @test skipall(sfa2) # merge! should have changed sfa2

    sfa = SkipFromAdmin("France", 1)
    sfb = SkipFromAdmin("France", 1:3)
    @test sfb.idxs != sfa.idxs
    merge!(sfa, SkipFromAdmin("France", 2), SkipFromAdmin("France", 3))
    @test sfb.idxs == sfa.idxs

    @test to_cart_point(LatLon(0, 0)) isa POINT_CART{Float64}
    poly = map([(-1,-1), (-1, 1), (1, 1), (1, -1)]) do p 
        LatLon(p...) |> Point
    end |> PolyArea |> change_geometry(Cartesian)
    @test in_exit_early(LatLon(0,0), poly)

    # We test that 50m resolution has more polygons than the default 110m one
    @test length(get_geotable(;resolution = 50).geometry) > length(get_geotable().geometry)
    @test length(get_geotable(;resolution = 10).geometry) > length(get_geotable(;resolution = 50).geometry)

    italy = extract_countries("italy") |> only
    npolyareas(x) = length(polyareas(x))
    @test LatLon(41.9, 12.49) in italy
    @test npolyareas(italy) == 3
    remove_polyareas!(italy, 1)
    @test npolyareas(italy) == 2
    @test_logs (:info, r"has already been removed") remove_polyareas!(italy, 1)

    @test valuetype(italy) == Float32

    # Show methods
    @test sprint(summary, italy) == "Italy Borders"
    @test contains(sprint(show, MIME"text/plain"(), italy), ", 1 skipped")

    # centroid
    dmn = extract_countries("italy; spain")
    c_ll = centroid(LatLon, dmn)
    c_cart = centroid(dmn)
    @test c_cart isa POINT_CART
    @test centroid(dmn, 1) isa POINT_CART
end    

@testitem "Coastlines" setup=[setup_basic] begin
    using CountriesBorders: CoastLines
    using PlotlyBase
    using CountriesBorders.GeoPlottingHelpers: geom_iterable, geo_plotly_trace
    cl = get_coastlines()
    @test cl isa CoastLines
    @test cl.resolution == 110

    cl = get_coastlines(;resolution = 50)
    @test cl isa CoastLines
    @test cl.resolution == 50

    @test repr(cl) == "CoastLines, resolution = 50m"
    @test geom_iterable(cl) == cl.raw_points
    @test geo_plotly_trace(cl).mode == "lines"
end

@testitem "Resolution" setup=[setup_basic] begin
    using CountriesBorders: RESOLUTION, DOMAIN, CoastLines, DEFAULT_RESOLUTION
    using CountriesBorders.ScopedValues: with
    using CountriesBorders.Meshes: element

    resolution(cb::CountryBorder) = cb.resolution
    resolution(cl::CoastLines) = cl.resolution
    resolution(d::DOMAIN) = resolution(element(d, 1))

    @test resolution(extract_countries("italy")) == 110
    @test resolution(get_coastlines()) == 110

    # Check with ScopedValue
    with(RESOLUTION => 50) do
        @test resolution(extract_countries("italy")) == 50
        @test resolution(get_coastlines()) == 50
    end

    @test resolution(extract_countries("italy")) == 110
    @test resolution(get_coastlines()) == 110

    DEFAULT_RESOLUTION[] = 50

    @test resolution(extract_countries("italy")) == 50
    @test resolution(get_coastlines()) == 50

    DEFAULT_RESOLUTION[] = 110
end