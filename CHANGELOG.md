# Changelog

## Unreleased

* Enhancements
  * All retry attempts are now recorded separately by `Telemetry` and
    `OpenTelemetry` middlewares.
  * Base URL is now included in the URL provided to  `Telemetry`,
    `OpenTelemetry`, and `StatsD` middlewares regardless of whether the request
    was successful or not. Previously was only included on successful requests.

## v3.0.0
* Breaking changes
    * Stopped support for Elixir 1.12.

* Enhancements
    * Added support for Elixir 1.15 and Erlang 25.3.
    * Changed log `warn` calls with `warning`, because `warn` is deprecated from Elixir 1.15.
    * Long deprecated `ex_statsd` dependency has been removed.

## v2.4.0
* Enhancements
  * Changes log levels of requests that fail with 5XX from "error" to "warn"

## v2.3.0
* Enhancements
    * Include method, path, status and duration in logger metadata

## v2.2.1
* Bug fixes
    * Fix proxy using Hackney's internal option names
    * Fix adapter options not being set when using no proxy

## v2.2.0
  * Enhancements
    * Add support for HTTP_PROXY, HTTPS_PROXY and NO_PROXY environment variables.

## v2.1.2
  * Bug fixes
    * Fix log levels of requests that end with `:timeout` or `:closed` from
      "error" to "warn"

## v2.1.1
  * Bug fixes
    * Reduce log level of closed request from "error" to "warn"

## v2.1.0
  * Enhancements
    * Update opentelemetry_tesla dependency to 2.0

## v2.1.0-rc.1
  * Enhancements
    * Replace vendor specific tapper library with vendor neutral OpenTelemetry library.

## v2.0.2
  * Bug fixes
    * Reduce log level of a timeout from "error" to "warn"

## v2.0.1
  * Bug fixes
    * Fix a case when specific request failure errors were not logged

## v2.0.0
  * Breaking changes
    * Module config is now deep merged with base salemove_http_client config.

      This is the same way Elixir Config handles configs.

    * Stats middleware configuration option is now required

      When using this version, the module config needs to have stats either
      specified in the config or set to false. This allows turning off stats
      in tests, for example.

## v1.0.1
  * Bug fixes
    * Fixed error decoding to work correctly with Tesla 1.x

      Since release of 1.0, Tesla no longer wraps connection errors into
      `%Tesla.Error{}` structs.

## v1.0.0
  * Breaking Changes
    * Upgraded Tesla to 1.0

      This upgrade brings the following potentially breaking changes:

      - Headers are now stored as keyword lists
      - Errors are now handled with `{:ok, _}` and `{:error, _}`

  * Enhancements
    * Replace Poison with Jason
    * Added support for headers in a map

  * Bug fixes
    * Fixed logger configuration in LoggerTest

## v0.2.1

  * Enhancement
    * Added support for Elixir 1.8+

## v0.2.0

  * Enhancements
    * Add Tapper middleware (#9)

## v0.1.6

  * Bug fixes
    * Fix ignored log level setting when supplied as range (#8)

## v0.1.5

  * Enhancements
    * Add custom logger middleware instead of Tesla's one (#7)

      Standard Tesla logger emits errors for all responses with code
      4xx and 5xx. While it's OK to have error messages for 5xx responses,
      some APIs may return 4xx code in normal situations. For this case
      configurable log level for certain response codes or code ranges
      is added.

## v0.1.4

  * Enhancements
    * Allow sending `application/x-www-form-urlencoded` requests (#6)

      Add option to use `json: false` in configuration to send request
      body as `application/x-www-form-urlencoded` rather than json.

## v0.1.3

  * Enhancements
    * Add optional Retry middleware to the default middleware stack (#5)

## v0.1.2

  * Bug fixes
    * Fix incorrect typespecs

## v0.1.1

  * Enhancements
    * Add support for compile-time configuration

## v0.1.0

  * Initial release
