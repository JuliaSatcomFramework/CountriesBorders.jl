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
    (; admin, valid_polyareas) = cb
    print(io, admin)
    print(io, ", $(valuetype(cb)), $(resolution(cb))m")
    nskipped = sum(!, valid_polyareas)
    if nskipped > 0
        print(io, ", $nskipped skipped")
    end
    println(io)
    v = Any["Skipped PolyArea" for _ in 1:length(valid_polyareas)]
    v[valid_polyareas] = polyareas(LatLon, cb)
    printelms(io, v)
end

# GSET
function Meshes.prettyname(d::GSET) 
    T = valuetype(d)
    res = resolution(d)
    "GeometrySet{CountryBorder{$T}}, resolution = $(res)m"
end

# CoastLines
Base.show(io::IO, cl::CoastLines) = print(io, "CoastLines, resolution = $(cl.resolution)m")