# Forwarding relevant meshes functions for the CountryBorder type
const VALID_CRS = Type{<:Union{LatLon, Cartesian}}

# These are methods which are not really part of meshes
floattype(::CountryBorder{T}) where {T} = T
floattype(::DOMAIN{T}) where {T} = T

borders(::Type{LatLon}, cb::CountryBorder) = cb.latlon
borders(::Type{Cartesian}, cb::CountryBorder) = cb.cart
borders(x) = borders(LatLon, x)

resolution(cb::CountryBorder) = cb.resolution
resolution(d::DOMAIN) = resolution(element(d, 1))

# This should return a vector of POLY_CART elements, mostly to be used with in_exit_early
polyareas(x) = polyareas(borders(Cartesian, x))
polyareas(v::Vector{<:POLY_CART}) = v
polyareas(x::MULTI_CART) = parent(x)
polyareas(x::POLY_CART) = (x,)

# This should return the cartesian bounding boxes for the polyareas of x, mostly to be used with in_exit_early
bboxes(x) = map(boundingbox, polyareas(x))
bboxes(cb::CountryBorder) = cb.bboxes

# LatLon fallbacks
Meshes.measure(cb::CountryBorder) = measure(borders(LatLon, cb))
Meshes.nvertices(cb::CountryBorder) = nvertices(borders(LatLon, cb))
Meshes.paramdim(cb::CountryBorder) = paramdim(cb.latlon)

# Cartesian fallbacks
Meshes.boundingbox(cb::CountryBorder) = boundingbox(cb.bboxes)

Meshes.centroid(crs::VALID_CRS, cb::CountryBorder) = centroid(borders(crs, cb))
Meshes.centroid(cb::CountryBorder) = centroid(Cartesian, cb)

# We do this to always use 
function _centroid_v(d::DOMAIN{T}) where T
  vector(i) = to(centroid(Cartesian, element(d, i)))
  volume(i) = measure(borders(Cartesian, element(d, i)))
  n = nelements(d)
  x = vector.(1:n)
  w = volume.(1:n)
  all(iszero, w) && (w = ones(eltype(w), n))
  v = sum(w .* x) / sum(w)
end

Meshes.centroid(crs::VALID_CRS, d::DOMAIN, i::Int) = centroid(crs, element(d, i))
Meshes.centroid(d::DOMAIN, i::Int) = centroid(Cartesian, d, i)

# The centroid computation on the domain does it in Cartesian2D, and the optionally transforms this 2D centroid in LatLon directly
Meshes.centroid(d::DOMAIN{T}) where T = centroid(Cartesian, d)
Meshes.centroid(::Type{Cartesian}, d::DOMAIN{T}) where T = Cartesian2D{WGS84Latest, Met{T}}(_centroid_v(d) |> Tuple) |> Point
function Meshes.centroid(::Type{LatLon}, d::DOMAIN)
    v = _centroid_v(d)
    lat = ustrip(v[2]) |> Deg # lat is Y
    lon = ustrip(v[1]) |> Deg # lon is X
    LatLon{WGS84Latest}(lat, lon) |> Point
end

Meshes.discretize(crs::VALID_CRS, cb::CountryBorder) = discretize(borders(crs, cb))
Meshes.discretize(cb::CountryBorder) = discretize(Cartesian, cb)

Meshes.rings(crs::VALID_CRS, cb::CountryBorder) = rings(borders(crs, cb))
Meshes.rings(cb::CountryBorder) = rings(Cartesian, cb)

Meshes.vertices(crs::VALID_CRS, cb::CountryBorder) = vertices(borders(crs, cb))
Meshes.vertices(cb::CountryBorder) = vertices(Cartesian, cb)

Meshes.simplexify(crs::VALID_CRS, cb::CountryBorder) = simplexify(borders(crs, cb))
Meshes.simplexify(cb::CountryBorder) = simplexify(Cartesian, cb)

Meshes.pointify(crs::VALID_CRS, cb::CountryBorder) = pointify(borders(crs, cb))
Meshes.pointify(cb::CountryBorder) = pointify(Cartesian, cb)

Meshes.convexhull(m::CountryBorder) = convexhull(borders(Cartesian, m))

# Base methods
Base.parent(cb::CountryBorder) = parent(LatLon, cb)
Base.parent(crs::VALID_CRS, cb::CountryBorder) = parent(borders(crs, cb))

"""
    in_exit_early(p, polys, bboxes)
Function that checks if a point is contained one of the polyareas in vector `polys` which are associated to the bounding boxes in vector `bboxes`.

Both `polys` and `bboxes` must be vectors of the same size, with element type `POLY_CART` and `BBOX_CART` respectively.

This function is basically pre-filtering points by checking inclusion in the bounding box which is significantly faster than checking for the polyarea itself.
"""
function in_exit_early(p, polys, bboxes)
    T = eltype(polys) |> crs |> CoordRefSystems.mactype
    p = to_cart_point(p, T)
    for i in eachindex(polys, bboxes)
        p in bboxes[i] || continue
        p in polys[i] && return true
    end
    return false
end
# This is a catchall method for extension for other types
in_exit_early(p, x) = in_exit_early(p, polyareas(x), bboxes(x))

to_cart_point(p::POINT_CART, T::Type{<:Real} = Float32) = convert(POINT_CART{T}, p)
to_cart_point(p::POINT_LATLON, T::Type{<:Real} = Float32) = to_cart_point(Meshes.flat(p), T)
to_cart_point(p::Union{LATLON, CART}, T::Type{<:Real} = Float32) = to_cart_point(Point(p), T)

Base.in(p::VALID_POINT, cb::CountryBorder) = in_exit_early(p, cb)
Base.in(p::LATLON, dmn::Union{DOMAIN, CountryBorder}) = in(Point(p), dmn)

# IO related
function Meshes.prettyname(d::GSET) 
    T = floattype(d)
    res = resolution(d)
    "GeometrySet{CountryBorder{$T}}, resolution = $(res)m"
end

## IO ##
function Base.summary(io::IO, cb::CountryBorder) 
    print(io, cb.admin)
    print(io, " Borders")
end

function Base.show(io::IO, cb::CountryBorder)
    print(io, cb.admin)
    nskipped = sum(!, cb.valid_polyareas)
    if nskipped > 0
        print(io, " ($nskipped skipped)")
    end
end

function Base.show(io::IO, ::MIME"text/plain", cb::CountryBorder)
    (; admin, valid_polyareas, latlon) = cb
    print(io, admin)
    print(io, ", $(floattype(cb)), $(resolution(cb))m")
    nskipped = sum(!, valid_polyareas)
    if nskipped > 0
        print(io, ", $nskipped skipped")
    end
    println(io)
    v = Any["Skipped PolyArea" for _ in 1:length(valid_polyareas)]
    v[valid_polyareas] = latlon.geoms
    printelms(io, v)
end