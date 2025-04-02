const COASTLINES_DICT = Dict{Int, CoastLines}()

function get_coastlines(; resolution = nothing, force = false)
    resolution = check_resolution(resolution; force)
    force && haskey(COASTLINES_DICT, resolution) && delete!(COASTLINES_DICT, resolution)
    get!(COASTLINES_DICT, resolution) do
        ne_data = naturalearth("coastline", resolution)
        raw_points = map(ne_data.geometry) do geom
            GeoTablesConversion.topoints(geom)
        end
        CoastLines(resolution, raw_points)
    end
end