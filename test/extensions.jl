@testsnippet setup_extensions begin
    using CountriesBorders
    using CountriesBorders: extract_plot_coords
    using CountriesBorders.Unitful
    using CountriesBorders.Meshes
    using PlotlyBase
    using Test
end

@testitem "Region" setup=[setup_extensions] begin
    extract_coords(ring::Ring) =
        map(vertices(ring)) do p
            coords(p)
        end
    extract_coords(pa::PolyArea) = mapreduce(extract_coords, vcat, rings(pa))

    italy_full = extract_countries("Italy")

    italy_no_sicily = extract_countries("Italy", skip_areas=[("Italy", 2)])

    sicily = parent(only(italy_full))[2]

    sicily_lats = map(x -> x.lat |> ustrip, extract_coords(sicily)) |> collect

    sg_italy_nosicily = italy_no_sicily |> scattergeo
    sg_italy = italy_full |> scattergeo
    @test isempty(intersect(sicily_lats, sg_italy_nosicily.lat))
    @test length(intersect(sicily_lats, sg_italy.lat)) == length(sicily_lats)
    @test count(isnan, sg_italy.lat) == 2
    @test count(isnan, sg_italy_nosicily.lat) == 1
end