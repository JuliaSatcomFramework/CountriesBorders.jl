module PlotlyBaseExt
using PlotlyBase
using CountriesBorders: Multi, Domain, PolyArea, extract_plot_coords, LatLon, 🌐, Point, RegionBorders

function PlotlyBase.scattergeo(p::RegionBorders; kwargs...)
    (;lon, lat) = extract_plot_coords(p)
	scattergeo(; lat, lon, mode="lines", kwargs...)
end

end