using TestItemRunner

@testitem "Aqua" begin
    using Aqua
    using CountriesBorders
    Aqua.test_all(CountriesBorders; ambiguities = false)
    Aqua.test_ambiguities(CountriesBorders)
end

@testitem "DocTests" begin
    using Documenter
    using CountriesBorders
    Documenter.doctest(CountriesBorders; manual = false)
end

@testitem "Basic" begin include("basics.jl") end
@testitem "Extensions" begin include("extensions.jl") end
# include("meshes_interface.jl")

@run_package_tests verbose=true