const GEOTABLE_DICT = Dict{Int, GeoTables.GeoTable}()

function get_geotable(; resolution = nothing, force = false, kwargs...)
    resolution = check_resolution(resolution; force)
    force && haskey(GEOTABLE_DICT, resolution) && delete!(GEOTABLE_DICT, resolution)
    get!(GEOTABLE_DICT, resolution) do
        admin_geojson = naturalearth("admin_0_countries_lakes", resolution)
        GeoTablesConversion.asgeotable(admin_geojson; resolution)
    end
end