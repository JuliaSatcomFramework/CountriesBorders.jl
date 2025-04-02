@testsnippet setup_basic begin
    using CountriesBorders
    using CountriesBorders: possible_selector_values, valid_column_names, mergeSkipDict, validate_skipDict, skipall, SkipDict, skipDict, get_geotable, extract_plot_coords, borders, remove_polyareas!, floattype, to_cart_point, change_geometry, Cartesian, in_exit_early, polyareas, latlon_geometry, cartesian_geometry, floattype, to_latlon_point
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

    @test floattype(italy) == Float32

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

@testitem "Deprecations" setup=[setup_basic] begin
    using CountriesBorders: extract_plot_coords, to_raw_coords
    
    @test_logs (:warn, r"deprecated") to_raw_coords(LatLon(10°, 10°))
    @test_logs (:warn, r"deprecated") extract_plot_coords(LatLon(10°, 10°))
end

@testitem "Extract plot coords" setup=[setup_basic] begin
# We test that extract_plot_coords gives first lat and then lon
    using CountriesBorders: with_settings

    dmn = extract_countries("italy")
    @test extract_plot_coords(dmn) isa @NamedTuple{lat::Vector{Float32}, lon::Vector{Float32}}
    ps = rand(Point, 100; crs = LatLon)
    @test extract_plot_coords(ps) == extract_plot_coords(coords.(ps))

    fr = extract_countries("France")
    plc = extract_plot_coords(fr)
    # France has 3 rings so it should have 2 NaN in each vector
    f(x, n) = count(isnan, x) === n
    @test f(plc.lat, 2) && f(plc.lon, 2)
    @test extract_plot_coords(Float64, fr) |> eltype |> eltype === Float64
    plc = with_settings(:INSERT_NAN => false) do
        extract_plot_coords(fr)
    end
    @test f(plc.lat, 0) && f(plc.lon, 0)

    # Test that cart also works
    italy = extract_countries("italy") |> only
    v1 = extract_plot_coords(italy) 
    v2 = extract_plot_coords(borders(Cartesian, italy))
    for s in (:lat, :lon)
        a1 = getfield(v1, s)
        a2 = getfield(v2, s)
        f(x,y) = (isnan(x) && isnan(y)) || x == y
        @test all(x -> f(x...), zip(a1, a2))
    end

    # We test that it also works with vector of points or vector or vectors of points
    lls = extract_plot_coords(rand(Point, 3; crs = LatLon))
    @test count(isnan, lls.lat) == 0

    lls = extract_plot_coords([rand(Point, 3; crs = LatLon) for _ in 1:2])
    @test count(isnan, lls.lat) == 1

    lls = with_settings(:INSERT_NAN => false) do
        extract_plot_coords([rand(Point, 3; crs = LatLon) for _ in 1:2])
    end
    @test count(isnan, lls.lat) == 0

    # We test that the extract_plot_coords increase the number of points for very long lines
    b = Box(
        to_cart_point(LatLon(-30, -180)),
        to_cart_point(LatLon(30, 180)),
    )
    poly = polyareas(b) |> first
    with_settings(:PLOT_STRAIGHT_LINES => :NORMAL) do
        plc = extract_plot_coords(poly)
        # The +1 is because extract replicates the first point
        @test length(plc.lat) > length(vertices(poly)) + 1
    end

    with_settings(:PLOT_STRAIGHT_LINES => :NONE) do
        plc = extract_plot_coords(poly)
        @test length(plc.lat) == length(vertices(poly)) + 1
    end

    # We test the copy_first_point keyword when providing directly a vector of points
    r = rings(poly) |> first
    vs = vertices(r)
    @test length(extract_plot_coords(vs).lat) == length(vs)
    with_settings(:CLOSE_VECTORS => true) do
        @test length(extract_plot_coords(vs).lat) == length(vs) + 1
    end

    ps = [LatLon(0, -179), LatLon(0, 179)]
    with_settings(:PLOT_STRAIGHT_LINES => :NONE) do
        @test extract_plot_coords(ps).lon |> length == 2
    end
    with_settings(:PLOT_STRAIGHT_LINES => :NORMAL) do
        @test extract_plot_coords(ps).lon |> length > 10
    end
    with_settings(:PLOT_STRAIGHT_LINES => :SHORT) do
        @test extract_plot_coords(ps).lon |> length == 3 # We have three here as we just adding the antimeridian point as the distance is quite short
    end
    with_settings([:PLOT_STRAIGHT_LINES => :NORMAL]) do
        @test extract_plot_coords([LatLon(89, 0), LatLon(0, 0)]).lon |> length == 2
    end
end

@testitem "Cartesian LatLon conversion" setup=[setup_basic] begin

    pa_latlon = PolyArea([Point(LatLon{WGS84Latest}(10°, -5°)), Point(LatLon{WGS84Latest}(10°, 15°)), Point(LatLon{WGS84Latest}(27°, 15°)), Point(LatLon{WGS84Latest}(27°, -5°))])
    pa_cartesian = PolyArea([Point{𝔼{2}}(Cartesian{WGS84Latest}(-5, 10)), Point{𝔼{2}}(Cartesian{WGS84Latest}(15, 10)), Point{𝔼{2}}(Cartesian{WGS84Latest}(15, 27)), Point{𝔼{2}}(Cartesian{WGS84Latest}(-5, 27))])

    multi_cartesian = Multi([pa_cartesian])
    multi_latlon = Multi([pa_latlon])

    # Test the Box conversion
    box_latlon = Box(
        Point(LatLon(-10°, -10°)),
        Point(LatLon(10°, 10°))
    )

    @test box_latlon |> change_geometry(Cartesian) isa BOX_CART{Float64}
    @test box_latlon |> change_geometry(Cartesian, Float32) |> change_geometry(LatLon) isa BOX_LATLON{Float32}

    @test pa_latlon |> change_geometry(LatLon, Float32) isa POLY_LATLON{Float32}
    @test pa_latlon |> change_geometry(Cartesian, Float32) isa POLY_CART{Float32}

    @test pa_latlon |> cartesian_geometry isa POLY_CART{Float64}
    @test pa_cartesian |> latlon_geometry isa POLY_LATLON{Float64}

    @test pa_latlon |> change_geometry(Cartesian) |> change_geometry(LatLon) == pa_latlon
    @test pa_latlon |> change_geometry(LatLon) == pa_latlon
    @test pa_cartesian |> change_geometry(LatLon) |> change_geometry(Cartesian) == pa_cartesian
    @test pa_cartesian |> change_geometry(LatLon) == pa_latlon
    @test pa_cartesian |> change_geometry(Cartesian) == pa_cartesian
    @test pa_latlon |> change_geometry(Cartesian) == pa_cartesian

    @test multi_cartesian |> change_geometry(LatLon) == multi_latlon
    @test multi_latlon |> change_geometry(Cartesian) == multi_cartesian

    @test rand(LatLon) |> to_latlon_point isa POINT_LATLON{Float64}
end