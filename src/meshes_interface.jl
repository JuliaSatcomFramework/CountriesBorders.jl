# These are methods which are not really part of meshes
resolution(cb::CountryBorder) = cb.resolution
resolution(d::DOMAIN) = resolution(element(d, 1))

# LatLon fallbacks
Meshes.measure(cb::CountryBorder) = measure(to_multi(LatLon, cb))
Meshes.nvertices(cb::CountryBorder) = nvertices(to_multi(LatLon, cb))
Meshes.paramdim(cb::CountryBorder) = paramdim(to_multi(LatLon, cb))

# Cartesian fallbacks
Meshes.boundingbox(cb::CountryBorder) = boundingbox(to_multi(Cartesian, cb))

Meshes.centroid(crs::VALID_CRS, cb::CountryBorder) = centroid(to_multi(crs, cb))
Meshes.centroid(cb::CountryBorder) = centroid(Cartesian, cb)

Meshes.centroid(crs::VALID_CRS, d::DOMAIN) = centroid(to_gset(crs, d))
Meshes.centroid(d::DOMAIN) = centroid(Cartesian, d)

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
