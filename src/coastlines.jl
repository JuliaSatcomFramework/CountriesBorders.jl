"""
    CoastLines
"""
struct CoastLines
    resolution::Int
    raw_points::Vector{Vector{POINT_LATLON{Float32}}}
end

const COASTLINES_DICT = Dict{Int, CoastLines}()

function get_coastlines(; resolution = 110, force = false)
    force && haskey(COASTLINES_DICT, resolution) && delete!(COASTLINES_DICT, resolution)
    get!(COASTLINES_DICT, resolution) do
        ne_data = naturalearth("coastline", resolution)
        raw_points = map(ne_data.geometry) do geom
            GeoTablesConversion.topoints(geom)
        end
        CoastLines(resolution, raw_points)
    end
end