# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.8.0

### Changed

- Rename `pki.additional_ca` to `pki.ca` by [@rucciva](https://github.com/rucciva).

### Fixed

- Default value merge behavior by [@rucciva](https://github.com/rucciva).

## 0.7.0

### Changed

- Change key of the `configurations` output variable by [@rucciva](https://github.com/rucciva).

## 0.6.0

### Changed

- Add requirement to manually remove null field should the `configurations` output variable need to be encoded to yaml by [@rucciva](https://github.com/rucciva).

## 0.5.0

### Added

- node's `active` to add certificate to blocklist if set to `false` by [@rucciva](https://github.com/rucciva).
- node's `instance_id` which if combined with `active` can be used to add old certificate to blocklist by [@rucciva](https://github.com/rucciva).

### Changed

- ca's `instance_ids` is now optional, default [""]  by [@rucciva](https://github.com/rucciva).

## 0.4.3

### Fixed

- Subnets information didn't get passed to cert by [@rucciva](https://github.com/rucciva).

## 0.4.2

### Fixed

- Accidental addition of default non-lighthouse group to lighthouse cert by [@rucciva](https://github.com/rucciva).

## 0.4.1

### Fixed

- CIDR variable validation by [@rucciva](https://github.com/rucciva).

## 0.4.0

### Changed

- Variable `mesh.node` to mimic nebula original config by [@rucciva](https://github.com/rucciva).

## 0.3.1

### Fixed

- fix CIDR validation panic by [@rucciva](https://github.com/rucciva).

## 0.3.0

### Changed

- Variable `nebula_mesh` to `mesh` by [@rucciva](https://github.com/rucciva).
- Variable `nebula_config_output_dir` to `config_output_dir` by [@rucciva](https://github.com/rucciva).

### Added

- Sub variable `mesh.routes_mtu` by [@rucciva](https://github.com/rucciva).
- Sub variable `mesh.blocklist` by [@rucciva](https://github.com/rucciva).
- Variable `default_non_lighthouse_group` by [@rucciva](https://github.com/rucciva).

## 0.2.4

### Fixed

- fix firewall definition by [@rucciva](https://github.com/rucciva).

## 0.2.3

### Fixed

- add try when asserting groups empty by [@rucciva](https://github.com/rucciva).

## 0.2.2

### Fixed

- fix for_each when nebula_config_output_dir empty by [@rucciva](https://github.com/rucciva).

## 0.2.1

### Changed

- update provider version to v0.3.0 by [@rucciva](https://github.com/rucciva).

## 0.2.0

### Changed

- default group for all non lighthouse node is now `_node_` by [@rucciva](https://github.com/rucciva).
- default firewal rule will not be added if it's defined in minimum of one node config [@rucciva](https://github.com/rucciva).

### Added

- Certificate and CA Certificate will be added to file output when specifying `public_key` by [@rucciva](https://github.com/rucciva).

## 0.1.1

### Fixed

- Fix firewall rule by [@rucciva](https://github.com/rucciva).

## 0.1.0

### Added

- Initial release by [@rucciva](https://github.com/rucciva).
