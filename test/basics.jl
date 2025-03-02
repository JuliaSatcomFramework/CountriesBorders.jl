using CountriesBorders
using CountriesBorders: possible_selector_values, valid_column_names, mergeSkipDict, validate_skipDict, skipall, SkipDict, skipDict, get_geotable, extract_plot_coords, borders, remove_polyareas!, floattype, npolyareas
using CountriesBorders.GeoTablesConversion: POINT_CART
using Meshes
using CoordRefSystems
using Test
using Unitful

example1 = extract_countries(;continent = "europe", admin="-russia")
example2 = extract_countries(;admin="-russia", continent = "europe")
example3 = extract_countries(;subregion = "*europe; -eastern europe")
@testset "Test Docstring Examples" begin
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

    dmn_excluded = extract_countries("italy; spain; france; norway"; skip_areas = [
        ("Italy", 2)
        "Spain"
        SKIP_NONCONTINENTAL_EU
    ])
    @test all(in(dmn_excluded), included_cities)
    @test all(!in(dmn_excluded), excluded_cities)

    dmn_full = extract_countries("italy; spain; france; norway")
    @test all(in(dmn_full), included_cities)
    @test all(in(dmn_full), excluded_cities)
end

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

# We test that 50m resolution has more polygons than the default 110m one
@test length(get_geotable(;resolution = 50).geometry) > length(get_geotable().geometry)

# We test that extract_plot_coords gives first lat and then lon
@testset "Extract plot coords" begin
    dmn = extract_countries("italy")
    @test extract_plot_coords(dmn) isa @NamedTuple{lat::Vector{Float32}, lon::Vector{Float32}}
    ps = rand(Point, 100; crs = LatLon)
    @test extract_plot_coords(ps) == extract_plot_coords(coords.(ps))

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
end

@testset "Misc coverage" begin
    italy = extract_countries("italy") |> only
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

@testset "Cartesian LatLon conversion" begin
    using Meshes: WGS84Latest
    using Unitful: °
    using CountriesBorders.GeoTablesConversion: cartesian_geometry, latlon_geometry

    pa_latlon = PolyArea([Point(LatLon{WGS84Latest}(10°, -5°)), Point(LatLon{WGS84Latest}(10°, 15°)), Point(LatLon{WGS84Latest}(27°, 15°)), Point(LatLon{WGS84Latest}(27°, -5°))])
    pa_cartesian = PolyArea([Point{𝔼{2}}(Cartesian{WGS84Latest}(-5, 10)), Point{𝔼{2}}(Cartesian{WGS84Latest}(15, 10)), Point{𝔼{2}}(Cartesian{WGS84Latest}(15, 27)), Point{𝔼{2}}(Cartesian{WGS84Latest}(-5, 27))])
        
    @test pa_latlon |> cartesian_geometry |> latlon_geometry == pa_latlon
    @test pa_cartesian |> latlon_geometry |> cartesian_geometry == pa_cartesian
    @test pa_cartesian |> latlon_geometry == pa_latlon
    @test pa_latlon |> cartesian_geometry == pa_cartesian
end