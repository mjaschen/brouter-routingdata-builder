# Changelog

## 4.0.0

### Added

- support for high resolution SRTM data (1 arc second) in BEF format

### Changed

- depend on BRouter 1.7.7

## 3.0.0

### Changed

- depend on BRouter 1.7.4

## 2.2.0

### Changed

- Cleanup in Dockerfile, remove no longer needed dependency on Osmosis
- Use timestamp of planet file as map snapshot time when planet update is disabled

## 2.1.0

### Changed

- update to latest BRouter ([03aab82e1](https://github.com/abrensch/brouter/commit/03aab82e1e22306495e5807ef52e4dbf506bf280))

## 2.0.0

### Changed

- updates for latest BRouter version

## 1.1.0

### Changed

- pin BRouter version to 11a9843f4 (before merge of changed PBF parsing)

## 1.0.0

### Added

- support for multi-platform images (amd64/arm64)
- build arm64 images on Github Actions and push to registries

### Changed

- build from a recent BRouter upstream (1.7.x, 2023-05-17)
- update some base images in Dockerfile (needed for multi-platform support)

## 0.4.0

### Changed

- adjustments for new Gradle-based build process

## 0.3.0

### Changed

- current BRouter upstream (updated lookups.dat)

## 0.1.3

### Added

- Docker images are pushed to Docker Hub as well

## 0.1.2

### Added

- Github Actions workflow for building and pushing the Docker image to Github Container Registry

## 0.1.1

### Changed

- osmupdate temporary files are now removed after updating the planet file

## 0.1.0

### Added

- initial release
