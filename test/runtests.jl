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

@run_package_tests verbose=true