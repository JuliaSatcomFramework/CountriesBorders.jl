const COASTLINES_DICT = Dict{Int, CoastLines}()

function get_coastlines(; resolution = nothing, force = false)
    resolution = check_resolution(resolution; force)
    force && haskey(COASTLINES_DICT, resolution) && delete!(COASTLINES_DICT, resolution)
    get!(COASTLINES_DICT, resolution) do
        ne_data = naturalearth("coastline", resolution)
        raw_points = map(ne_data.geometry) do geom
            GeoTablesConversion.topoints(geom)
        end
        if resolution === 50
            #= 
            We need to fix an issue with the 50 resolution in which one coastline line contains two separate "geometries" which result in a connecting artifact line when plotting them as lines.
            We solve this by splitting the specific line (which is element 1388 of the array) into two separate lines.
            =#
            item = raw_points[1388]
            # we check for the specific point to make sure the underlying data didn't change
            lon, lat = to_raw_lonlat(item[392])
            if lon ≈ 180
                o = splice!(item, 1:391)
                insert!(raw_points, 1388, o)
            end
        end
        CoastLines(resolution, raw_points)
    end
end