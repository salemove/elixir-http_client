# Changelog

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
