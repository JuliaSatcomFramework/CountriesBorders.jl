# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

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
