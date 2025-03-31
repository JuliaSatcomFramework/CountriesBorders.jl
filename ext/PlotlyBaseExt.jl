module PlotlyBaseExt
using PlotlyBase
using CountriesBorders: CountriesBorders, Multi, Domain, PolyArea, LatLon, 🌐, Point, RegionBorders
using CountriesBorders.GeoPlottingHelpers: GeoPlottingHelpers, extract_latlon_coords, geo_plotly_trace

function PlotlyBase.scattergeo(p::RegionBorders; kwargs...)
    (;lon, lat) = extract_latlon_coords(p)
	scattergeo(; lat, lon, mode="lines", kwargs...)
end

end