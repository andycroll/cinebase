# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

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
