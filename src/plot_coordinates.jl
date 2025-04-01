GeoPlottingHelpers.geom_iterable(cb::CountryBorder) = rings(borders(cb))

"""
    extract_plot_coords(args...)

This function is now simply a forward to the function [`GeoPlottingHelpers.`]
"""
function extract_plot_coords(args...)
    @warn "This function is being deprecated in favor of `GeoPlottingHelpers.extract_latlon_coords`.\nMigrate your code to use the new function directly"
    extract_latlon_coords(args...)
end

const extract_plot_coords! = GeoPlottingHelpers.extract_latlon_coords!