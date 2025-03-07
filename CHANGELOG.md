# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- The `CountryBorder` type now has a new field `bboxes` which contains the bounding boxes (Cartesian) of each polyarea within the country. This is used to speed up the inclusion test in the new custom `in` implementation using the `in_exit_early` internal function. This brings speedups of ~20x compared to the previous implementation.
