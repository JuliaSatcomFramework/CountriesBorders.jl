#=
The contents o this file have been mostly taken and adapted from the
[GeoIO.jl](https://github.com/JuliaEarth/GeoIO.jl) package which is licensed
under MIT license.
Discussion about the re-use of this code with the original authors can be found in https://github.com/JuliaEarth/GeoIO.jl/issues/91
The corresponding MIT License is copied below:

MIT License

Copyright (c) 2021 Júlio Hoffimann <julio.hoffimann@gmail.com> and contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
=#

# This function assumes that a set of points represent a valid GeoJSON geometry (which is already split to avoid antimeridian problems) and simply makes sure that the sign of the longitude at 180° is consistent with the remaining points in the ring
function fix_antimeridian_sign!(points::Vector{<:POINT_LATLON})
    cond(p) = abs(coords(p).lon) == 180u"°"
    getsign(p) = sign(coords(p).lon)
    any(cond, points) || return
    signpoint = points[findfirst(!cond, points)]
    s = getsign(signpoint)
    for (i, p) in enumerate(points)
        if cond(p)
            c = coords(p)
            points[i] = LatLon(c.lat, copysign(c.lon, s)) |> Point
        else
            s = getsign(p) # We use the sign of the latest valid point as relevant for the sign. This is mostly needed for antarctica which spans all latitudes
        end
    end
    return nothing
end

# The commented out lines below are those not needed for parsing the specific file of countries borders. These might be enabled in the future if needed.

# Part from https://github.com/JuliaEarth/GeoIO.jl/blob/8c0eb84223ecf8a8601850f8b7cc27f81a18d68c/src/conversion.jl.
function topoints(geom)
    [LatLon(GI.y(p), GI.x(p)) |> Point for p in GI.getpoint(geom)]
end

function tochain(geom)
  points = topoints(geom)
  if first(points) == last(points)
    # fix backend issues: https://github.com/JuliaEarth/GeoTables.jl/issues/32
    while first(points) == last(points) && length(points) ≥ 2
      pop!(points)
    end
    fix_antimeridian_sign!(points)
    Ring(points)
  end
end

function topolygon(geom)
  # fix backend issues: https://github.com/JuliaEarth/GeoTables.jl/issues/32
  toring(g) = close(tochain(g))
  outer = toring(GI.getexterior(geom))
  if GI.nhole(geom) == 0
    PolyArea(outer)
  else
    inners = map(toring, GI.gethole(geom))
    PolyArea([outer, inners...])
  end
end

_convert(::GI.PolygonTrait, geom) = topolygon(geom)

function _convert(::GI.MultiPolygonTrait, geom)
  @assert !GI.is3d(geom) "We only support 2d geometries (lon/lat coordinates) but we got a 3d geometry"
  Multi([topolygon(g) for g in GI.getgeom(geom)])
end

geom2meshes(geom) = geom2meshes(GI.geomtrait(geom), geom)
geom2meshes(trait::Union{GI.MultiPolygonTrait,GI.PolygonTrait}, geom) = _convert(trait, geom)

# Part from https://github.com/JuliaEarth/GeoIO.jl/blob/8c0eb84223ecf8a8601850f8b7cc27f81a18d68c/src/utils.jl
# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

function asgeotable(table; resolution)
  cols = Tables.columns(table)
  names = Tables.columnnames(cols)
  gcol = :geometry
  vars = setdiff(names, [gcol])
  table = isempty(vars) ? nothing : (; (v => Tables.getcolumn(cols, v) for v in vars)...)
  geoms = Tables.getcolumn(cols, gcol)
  admins = Tables.getcolumn(cols, :ADMIN)
  countries = map(geoms, admins, eachindex(geoms)) do geom, admin, table_idx
    borders = GeoBorders(geom2meshes(geom))
    valid_polyareas = trues(length(polyareas(LatLon, borders)))
    CountryBorder(admin, borders, valid_polyareas; table_idx, resolution)
  end
  domain = GeometrySet(countries)
  georef(table, domain)
end