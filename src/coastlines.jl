const COASTLINES_DICT = Dict{Int, CoastLines}()

"""
    get_coastlines(; resolution = nothing, force = false)

Get the `CoastLines` object containing the points of the coastlines extracted from the NaturalEarth dataset at a specific resolution.

This object is mostly useful for plotting and can be fed directly to either the `extract_latlon_cords` or the `geo_plotly_trace` functions provided by the `GeoPlottingHelpers` package.

# Keyword Arguments
- `resolution`: The resolution of the coastlines to get. If `nothing`, the default resolution is used.
- `force`: If `true`, the coastlines are recalculated even if they already exist.
"""
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