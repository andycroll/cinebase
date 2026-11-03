# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [5.10.0] - 2026-11-03
### Added
- Live sport is an `Event`: `Six Nations 2027 - England v France` gives the event Six Nations and the variant `sport`. The fixture keeps the competition in its film name. `Event#variant` is `arts` or `sport`.
- `Festival.from_title` takes `names:`, and `Performance.festival_names` lets a chain name a short form that differs by place, such as NFF.
- `+ Mulled Wine` marks the `mulled_wine` variant, and festival prefixes after `DocHouse:` are read.

## [5.9.3] - 2026-11-03
### Added
- Festivals named in full, such as `UK Jewish Film Festival:` and `Women and the World International Film Festival:`, in brackets after the film, such as `Coward (French Film Festival)`, or with the year next to the name, such as `FFF26:`.
- `Dog Friendly:` without a hyphen marks a dog-friendly screening, and `(Preview)` or `[Preview]` a preview.

## [5.9.2] - 2026-11-03
### Changed
- Festivals take their full name, so chains agree: `CFF` is Cambridge Film Festival, `FFF` and `French Film Fest UK` are French Film Festival, `IFF` is Into Film Festival, `JFF` and `UKJFF` are UK Jewish Film Festival, `LPFF` is London Palestine Film Festival, `RFF` is Romanian Film Festival and `SLA` is Scotland Loves Anime.

### Added
- A `See It First –` prefix marks a preview, and bracketed subtitles, such as `(with subtitles)`, mark a subtitled screening.
- Paris Opera is an `Event`: `Paris Opera Ballet: Giselle` and `La Bayadère (Opéra de Paris)` give the prefix `Paris Opera: `.
- A festival named after the film, such as `Party USA - NFF UK Premier`, is read and stripped like a prefix. `Festival::PATTERNS` holds both.
- A1Web reads the language from `(Japanese Language with English Subtitles)`.
- `Dog-Friendly:` marks a dog-friendly screening, `: Preview and Q&A` a preview, and `NFF 2026 Shorts:` the NFF festival.

### Fixed
- `COMMON_REMOVE` strips a `Throwback:` prefix and a full stop left after a bracketed marker, such as `(35mm).`
- Titles in capitals with `WORLD TOUR` are title cased throughout, not just the words `World Tour`.

## [5.9.1] - 2026-11-03
### Fixed
- Titles with non-breaking spaces now match the common rules and audience labels.
- `COMMON_REMOVE` also strips presenter credits such as `Bar Trash Presents:`, an anniversary at the end of a title without brackets, `– Live On Stage` with an en dash, Q&A add-ons naming a `Dir.`, and bracketed Q&As.

## [5.9.0] - 2026-11-03
### Added
- `Cinebase::Event` for opera, ballet, theatre and exhibition screenings. `Performance#event` names the series from the `film_name` prefix the title sanitizer gives, such as `Met Opera: `, and `Performance#film_name` leaves it out.
- `Cinebase::Audience` reads relaxed, kids, baby, dog-friendly, members and preview labels from a raw title.
- `Performance` takes the raw `title:`. With it, `#variant` adds audience variants and `#festival` falls back to one named in the title.
- Festival prefixes for Cinecity, FFF, French Film Fest UK, IFF, Into Film Festival, JFF, LDNDOCS, London Palestine Film Festival, LPFF, NFF, Queer East, RFF, SLA and Women and the World Festival, with or without a year, which may have two digits.
- Bengali, Gujarati, Japanese, Romanian and Vietnamese language versions.

### Changed
- `COMMON_REPLACE` names every spelling of a Met Opera, Royal Ballet and Opera, National Theatre Live, Exhibition on Screen or Bolshoi season with one prefix, including Met operas listed in an RBO season.
- `COMMON_REMOVE` also strips audience labels, festival gala labels, bracketed 3D and 4K, `4K Restoration`, restorations after an anniversary, square-bracketed anniversaries, bracketed encores, `(Recorded)`, `(English Dubbed)`, `- Live On Stage`, and `+ ScreenTalk`, `+ Intro` and `+ Short Film` add-ons.
- Titles listed in capitals are title cased.

## [5.8.0] - 2026-11-02
### Added
- `Cinebase::Http` for chain gems' requests: `get`, and `post` with a form or JSON body, over HTTPS. It retries dropped connections twice, never follows redirects, raises errors that name the status and host but leave out the body, and returns bodies as UTF-8. `keep_alive: true` reuses one connection per host until `close`. Tests stub `Cinebase::Http.pause` to skip the waits between attempts.
- `Cinebase::London` for London dates and times: `today`, `utc` for a listed wall-clock time (the hour repeated when clocks go back is read as BST) and `date` for a time's London date.

### Changed
- The A1Web and Boxoffice clients, and `Performance#starting_at`, use them. `Performance#starting_at` no longer raises for a local time in the repeated hour when clocks go back.

## [5.7.0] - 2026-11-01
### Added
- `cinebase/a1web`, loaded only on request, for chains whose websites run on Admit One's A1Web, such as Arc, Reel and Movie House
- `A1web::Client` reads venues from the website's cinema menu and site codes from `GlobalSiteData`, or from a venue's own page when the home page lists none. It reads a venue's `/whatson` page, which holds every advertised date, as UTF-8 although A1Web sends Windows-1252. It retries dropped connections.
- `A1web::Listings` reads each showtime's date, start, absolute booking link and tags (icon names, `a1-event-*` icon classes and group headings). It handles date panels keyed by timestamp, tabs carrying a timestamp, and tabs with only a label such as `Tue 03 Nov`, reads repeated mobile copies once, and adds the venue path that Movie House booking links leave out.
- `A1web::Cinema` and `A1web::Performance` base classes. A chain defines `Cinema.website` and `#brand`, optionally `Cinema.locations` with addresses and coordinates, and `Performance.cinema_class`, `.title_sanitizer` and optionally `.variants`. 3D and IMAX also come from titles.

## [5.6.0] - 2026-10-31
### Added
- `Cinema#latitude` and `Cinema#longitude`, `nil` by default. Chain gems return Floats in decimal degrees when they know where a cinema is.
- `Vista::TokenHolder` for chain modules: `token`, `acquire_token!`, `ensure_token!` (fetches only when there is no token or it expires within `RENEWAL_MARGIN`, an hour), `token_expires_at` and `reject_token!`
- `Vista::GuestToken.expires_at(token)` reads a JWT's `exp` claim
- `cinebase/boxoffice`, loaded only on request, for chains whose websites run on Webedia's "Movies Pro" theme and sell tickets through Boxoffice, such as Everyman and Showcase. Extracted from `everyman_uk`.
- `Boxoffice::Client` reads theatres from the website's daily static build and showtimes and films from its `/api/gatsby-source-boxofficeapi/` routes, with no token. It retries dropped connections, and a whole year of one theatre's showtimes is one request.
- `Boxoffice::Showtime` reads a showtime's start in the theatre's time zone, booking link (the chain's `default` provider first, then any other), dimension (`3d` or `RealD3D` tags), language and variants. `VARIANTS` maps Boxoffice's own tags; chains pass `variants:` with their own tags merged in.
- `Boxoffice::Cinema` and `Boxoffice::Performance` base classes. A chain defines `Cinema.website` and `#brand`, and `Performance.cinema_class`, `.title_sanitizer` and optionally `.variants`.

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
