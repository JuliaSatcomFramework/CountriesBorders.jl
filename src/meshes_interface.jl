# These are methods which are not really part of meshes
function borders(crs::VALID_CRS, cb::CountryBorder)
    @warn """The `borders` function is deprecated and will be removed in a future version.
Change calls from: 
- `borders(crs, cb)` to `GeoBasics.to_multi(crs, cb)` 
- `borders(cb)` to `GeoBasics.to_multi(LatLon, cb)`
"""
    to_multi(crs, cb)
end
borders(x) = borders(LatLon, x)

resolution(cb::CountryBorder) = cb.resolution
resolution(d::DOMAIN) = resolution(element(d, 1))


function polyareas(x) 
    @warn """The `CountriesBorders.polyareas` function is deprecated and will be removed in a future version.
Change calls from: 
- `CountriesBorders.polyareas(x)` to `GeoBasics.polyareas(Cartesian, x)`
"""
    GeoBasics.polyareas(Cartesian, x)
end

function bboxes(x)
    @warn """The `CountriesBorders.bboxes` function is deprecated and will be removed in a future version.
Change calls from: 
- `CountriesBorders.bboxes(x)` to `GeoBasics.bboxes(Cartesian, x)`
"""
    GeoBasics.bboxes(Cartesian, x)
end

# LatLon fallbacks
Meshes.measure(cb::CountryBorder) = measure(to_multi(LatLon, cb))
Meshes.nvertices(cb::CountryBorder) = nvertices(to_multi(LatLon, cb))
Meshes.paramdim(cb::CountryBorder) = paramdim(to_multi(LatLon, cb))

# Cartesian fallbacks
Meshes.boundingbox(cb::CountryBorder) = boundingbox(to_multi(Cartesian, cb))

Meshes.centroid(crs::VALID_CRS, cb::CountryBorder) = centroid(to_multi(crs, cb))
Meshes.centroid(cb::CountryBorder) = centroid(Cartesian, cb)

Meshes.centroid(crs::VALID_CRS, d::DOMAIN, i::Int) = centroid(crs, element(d, i))
Meshes.centroid(d::DOMAIN, i::Int) = centroid(Cartesian, d, i)

# The centroid computation on the domain does it in Cartesian2D, and the optionally transforms this 2D centroid in LatLon directly
function Meshes.centroid(crs::VALID_CRS, d::DOMAIN)
    p_cart = centroid(d)
    return crs <: Cartesian ? p_cart : to_latlon_point(p_cart)
end

Meshes.discretize(crs::VALID_CRS, cb::CountryBorder) = discretize(to_multi(crs, cb))
Meshes.discretize(cb::CountryBorder) = discretize(Cartesian, cb)

Meshes.rings(crs::VALID_CRS, cb::CountryBorder) = rings(to_multi(crs, cb))
Meshes.rings(cb::CountryBorder) = rings(Cartesian, cb)

Meshes.vertices(crs::VALID_CRS, cb::CountryBorder) = vertices(to_multi(crs, cb))
Meshes.vertices(cb::CountryBorder) = vertices(Cartesian, cb)

Meshes.simplexify(crs::VALID_CRS, cb::CountryBorder) = simplexify(to_multi(crs, cb))
Meshes.simplexify(cb::CountryBorder) = simplexify(Cartesian, cb)

Meshes.pointify(crs::VALID_CRS, cb::CountryBorder) = pointify(to_multi(crs, cb))
Meshes.pointify(cb::CountryBorder) = pointify(Cartesian, cb)

Meshes.convexhull(m::CountryBorder) = convexhull(to_multi(Cartesian, m))

# Base methods
Base.parent(crs::VALID_CRS, cb::CountryBorder) = parent(to_multi(crs, cb))
Base.parent(cb::CountryBorder) = parent(LatLon, cb)
