# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [5.6.0] - Unreleased
### Added
- `Cinema#latitude` and `Cinema#longitude`, `nil` by default. Chain gems return Floats in decimal degrees when they know where a cinema is.

## [5.5.0] - 2026-10-22
### Changed
- `Vista::Client` keeps one connection open for all its requests instead of opening a new TLS connection each time, which cost over ten times the request itself. Requests on one client are serialised, so a client can be shared between threads.

## [5.4.0] - 2026-10-22
### Added
- `Vista::Client` accepts `region_code: nil` and then sends no `Connect-Region-Code` header, for chains such as Picturehouse whose API rejects every region code
- `COMMON_REMOVE` strips any `+ ... Q&A` or `+ ... Q+A` add-on, `+ Discussion`, `(35mm)`, `(70mm)` and a `4K` marker
- `Met Opera Encore 2026-27:` titles standardise like other Met Opera seasons
- `CFF:` (Cambridge Film Festival) title prefixes are festivals

## [5.3.0] - 2026-10-22
### Added
- `Performance#film_year` with an optional `film_year:` option, and `TitleSanitizer.film_year` reading a trailing `(1996)` from a title
- `COMMON_REMOVE` strips that year, `(Re-release)` and Lithuanian versions
- `Horror Season` title prefixes are festivals, so `Horror Season 2026 From Dusk Till Dawn (1996)` becomes `From Dusk Till Dawn`, year 1996, in the Horror Season 2026

### Fixed
- Indentation of tests added in 5.2.0

## [5.2.0] - 2026-10-22
### Added
- `Performance#festival`, `#language` and `#subtitled?`, with optional `festival:` and `language:` options
- `Cinebase::Festival` value object (`name`, `year`) and `Festival.from_title`
- `TitleSanitizer::COMMON_REMOVE` and `COMMON_REPLACE`: opt-in rules for dub and subtitle versions, language versions, anniversaries, Q&A add-ons, encores, sing-alongs, festival prefixes, opera and ballet seasons, and `WORLD TOUR` capitals
- `cinebase/vista`, loaded only on request, for chains on Vista OCAPI: `Vista::Client`, a `Vista::GuestToken` template and `Vista::PackageTask` for platform gems bundling curl-impersonate
- CI on Ruby 4.0

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
