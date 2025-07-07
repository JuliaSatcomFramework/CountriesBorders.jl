# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## [0.5.0] - 2025-07-07

This version moved a lot of the internals to the new GeoBasics package.

This is a new package which defines more consistently an interface for exploiting a fast point in region inclusion. It took many methods previously defined within this package and formalized them better in a new public API for our basic Geo needs in CountriesBorders and GeoGrids. See rest of the changelog for more details

### Added 
- Added a dependency on BasicTypes
- Added a dependency on GeoBasics

### Deprecated
- The following internal functions are now deprecatedand will be removed in a future version. They now print a warning and forward to the equivalent function from `GeoBasics.jl`, with suggested modification for users as follows: 
  - `borders`: To be now changed accordingly:
    - `borders(crs, cb)` to `GeoBasics.to_multi(crs, cb)` 
    - `borders(cb)` to `GeoBasics.to_multi(LatLon, cb)`
  - `polyareas`: To be now changed from `polyareas(x)` to `GeoBasics.polyareas(Cartesian, x)`
  - `bboxes`: To be now changed from `bboxes(x)` to `GeoBasics.bboxes(Cartesian, x)`

### Removed
- The following internal functions have been removed from CountriesBorders as they are now defined in `GeoBasics`:
  - `in_exit_early`
  - `to_cart_point`
  - `to_latlon_point`
  - `to_cartesian_geometry`
  - `to_latlon_geometry`
- All the type aliases for Meshes.jl types (e.g. LATLON, POINT_LATON) have been removed from this package as they are now defined in `GeoBasics.jl`.
- The internal `floattype` function has been removed and has been replaced with `BasicTypes.valuetype`
- The `SimpleLatLon` type/function has been removed as it was already deprecated.

### Changed
- The fields of the `CountryBorder` type have been changed, and now store a `GeoBasics.GeoBorders` field to represents the borders as opposed to the previous three fields `latlon`, `cart` and `bboxes`
- The `CountryBorder` type is now a subtype of `GeoBasics.FastInGeometry` to satisfy the new interface

## [0.4.12] - 2025-04-02

### Fixed
- Fix missing import which caused erroring in 0.4.11

## [0.4.11] - 2025-04-02

### Added
- Added a `resolution` keyword argument to `extract_countries` (only when not explicitly providing the `geotable` argument) to allow for different resolutions to be used for the extraction of countries.
- Added the `get_coastlines` function (exported) whichi simply allows getting `CoastLines` object containing the points of the coastlines extracted from the NaturalEarth dataset at a specific resolution.
- Added a `RESOLUTION` ScopedValue and a `DEFAULT_RESOLUTION` `Ref` (both not exported) that can be used to modify the default resolution (10, 50 or 110) for the `extract_countries` and the `get_coastlines` functions either temporarily within a scope or permanently with `DEFAULT_RESOLUTION[] = value`.

### Changed
- Refactored the structure of the code, and now all types are defined in the toplevel module (though still accessible also from the GeoTablesConversion module)
- Changed the way the default GeoTable for Countries Borders is stored internally. It is now stored inside a Dict
- The `to_raw_coords` function is now deprecated and will be removed in a future release. Users should migrate to use the `GeoPlottingHelpers.to_raw_lonlat` function instead.

### Removed
- The `set_geotable!` and `get_default_geotable_resolution` functions are now removed as the new storing of the Countries GeoTable is a plain Dict. They were not exported or part of the public interface so this does not represent a breaking change.

## [0.4.10] - 2025-04-01

### Changed
- The package now does not define plotting helpers anymore, but just relies on the new `GeoPlottingHelpers` package for that. The `extract_plot_coords` and `extract_plot_coords!` functions are now deprecated and will be removed in a future release. Users should migrate to use the `GeoPlottingHelpers.extract_latlon_coords` and `GeoPlottingHelpers.extract_latlon_coords!` functions directly.

## [0.4.9] - 2025-03-21

### Changed
- Changed the way plot settings are handled, and stop having `PLOT_STRAIGHT_LINES` being true by default.
  - The user-customizable settings should now be set using the `with_settings` function (not exported)

### Removed
- Removed the method for `scattergeo` acting on vector of LatLon points as it was type piracy.

## [0.4.8] - 2025-03-21

### Added
- Added a new ScopedValue `PLOT_STRAIGHT_LINES` to control whether `extract_plot_coords` should oversample points which are far apart in order to make lines in scattergeo look more straight. This is true by default.
- For inputs which are vector of points, `extract_plot_coords` now accepts a `copy_first_point` keyword argument to control whether the function should copy the first point at the end of the array after each vector of points to simulate `closing` a ring.
- Methods fo `polyareas` and `boxes` are now defined for `BOX_CART` geometries.

### Fixed
- All coordinates of the countries polyareas are now corrected during construction to ensure that rings of countries touching the antimeridian (longitude = 180) have a sign of the longitude which is consistent with the neighboring points within the same ring.
  - This only applies to some polyareas in Russia, Anctartica and few other countries

## [0.4.7] - 2025-03-20

### Added
- Added a method for `extract_plot_coords` to make it work automatically with a vector of valid points.

## [0.4.6] - 2025-03-20
This release has some breaking changes to internal functions, but as these were not exported it is not considered a breaking release

### Changed
- Some refactoring of internal code and breaking changes to the following non-exported internal functions to make them more flexible:
    - `latlon_geometry`
    - `cartesian_geometry`
    - `change_geometry`
    - `to_cart_point`

### Added
New internal function `to_latlon_point` which mirrors `to_cart_point` but for the output in LatLon crs.

## [0.4.5] - 2025-03-08

### Changed
- The `CountryBorder` type now has a new field `bboxes` which contains the bounding boxes (Cartesian) of each polyarea within the country. This is used to speed up the inclusion test in the new custom `in` implementation using the `in_exit_early` internal function. This brings speedups of ~20x compared to the previous implementation.
- The `extract_plot_coords` function is now exported.
