# CountriesBorders

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://disberd.github.io/CountriesBorders.jl/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://disberd.github.io/CountriesBorders.jl/dev) -->
[![Build Status](https://github.com/JuliaSatcomFramework/CountriesBorders.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaSatcomFramework/CountriesBorders.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/JuliaSatcomFramework/CountriesBorders.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaSatcomFramework/CountriesBorders.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

This package provides utilities for extracting coordinates of countries borders in latitude/longitude.

It uses the natural earth database for getting the borders coordinates.

## Example Usage
```julia
using CountriesBorders
# Extract the coordinates of the borders of Italy and Spain, as Domain from Meshes. This function is exported by CountriesBorders
dmn = extract_countries("italy; spain")

# Creates two variables containint the lat/lon coordinates of Rome, Madrid and Paris. SimpleLatLon is exported by CountriesBorders
rome = Point(LatLon(41.9, 12.49))
paris = Point(LatLon(48.864, 2.349))
madrid = Point(LatLon(40.416, -3.703))

# Verify that rome and madrid are included in the domain
rome in dmn # Returns true
madrid in dmn # Returns true
paris in dmn # Returns false as we only extracted italy and spain
```

See the docstring of `extract_countries` (and its extended help) for more details, or check the example notebook within the `notebooks` folder. A static version of the notebook is also available at [this link](https://rawcdn.githack.com/disberd/CountriesBorders.jl/main/notebooks/example_use.html)