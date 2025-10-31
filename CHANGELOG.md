# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [5.1.0] - 2025-10-31
### Changed
- Converted all test files from minitest spec syntax to vanilla minitest syntax

## [5.0.0] - 2025-10-30
### Changed
- **BREAKING**: Updated minimum Ruby version to 3.3+
- Migrated CI from Travis CI to GitHub Actions
- Updated bundler requirement to >= 2.0 (from ~> 1.9)
- Updated rake requirement to >= 13.0 (from ~> 10.0)
- Updated SimpleCov from 0.13.0 to 0.22.0
- Replaced deprecated CodeClimate test reporter with SimpleCov directly
- Changed default branch from `master` to `main`

### Added
- Frozen string literal pragma to all library files for Ruby 3+ compatibility
- `.ruby-version` file specifying Ruby 3.4.7

### Fixed
- Fixed Minitest deprecation warnings by updating to modern expectation syntax
- Fixed frozen string literal warnings in TitleSanitizer by using `.dup` for mutable string copy

## [3.0.1]
### Fixed
- `Cinema#address` is now a method call, alias_method was always pointing at the
  superclass

## [3.0.0]
### Changed
- screening_at for a Performance is always in UTC

## [2.0.0]
### Changed
- Screenings are now Performances

## [1.1.0]
### Changed
- It is expected that the `Cinema#adr` method is redefined on the subclass and
  thus auto-populates the following added methods...

### Added
- Method `Cinema#street_address` to pull String from `Cinema#adr`
- Method `Cinema#extended_address` to pull String from `Cinema#adr`
- Method `Cinema#locality` to pull String from `Cinema#adr`
- Method `Cinema#region` to pull String from `Cinema#adr`
- Method `Cinema#postal_code` to pull String from `Cinema#adr`
- Method `Cinema#country_name` to pull String from `Cinema#adr`

## [1.0.1]
### Fixed
- Implementation of TitleSanitizer no longer creates anonymous `Struct`

## [1.0.0] - 2015-05-30
### Added
- Initial Release
