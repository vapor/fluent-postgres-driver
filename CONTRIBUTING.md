# Contributing to Fluent's PostgreSQL Driver

👋 Welcome to the Vapor team! 

## Docker

In order to build and test against Postgres, you will need a database running. The easiest way to do this is using Docker and the included `docker-compose.yml` file.

If you have Docker installed on your computer, all you will need to do is:

```sh
docker-compose up
```

This will start the two databases required for running this package's unit tests.

## Xcode

To open the project in Xcode:

- Clone the repo to your computer
- Drag and drop the folder onto Xcode

To test within Xcode, press `CMD+U`.

## SPM

To develop using SPM, open the code in your favorite code editor. Use the following commands from within the project's root folder to build and test.

```sh
swift build
swift test
```

## SemVer

Vapor follows [SemVer](https://semver.org). This means that any changes to the source code that can cause
existing code to stop compiling _must_ wait until the next major version to be included. 

Code that is only additive and will not break any existing code can be included in the next minor release.

----------

Join us on Discord if you have any questions: [vapor.team](http://vapor.team).

&mdash; Thanks! 🙌
