<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/vapor/fluent-postgres-driver/assets/1130717/c2350b70-aaf1-43e1-ab79-86fc88ba8da4">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/vapor/fluent-postgres-driver/assets/1130717/dfc94dc2-281b-4e54-be86-549813496373">
  <img src="https://github.com/vapor/fluent-postgres-driver/assets/1130717/dfc94dc2-281b-4e54-be86-549813496373" height="96" alt="FluentPostgresDriver">
</picture> 
<br>
<br>
<a href="https://docs.vapor.codes/4.0/"><img src="https://design.vapor.codes/images/readthedocs.svg" alt="Documentation"></a>
<a href="https://discord.gg/vapor"><img src="https://design.vapor.codes/images/discordchat.svg" alt="Team Chat"></a>
<a href="LICENSE"><img src="https://design.vapor.codes/images/mitlicense.svg" alt="MIT License"></a>
<a href="https://github.com/vapor/fluent-postgres-driver/actions/workflows/test.yml"><img src="https://img.shields.io/github/actions/workflow/status/vapor/fluent-postgres-driver/test.yml?event=push&style=plastic&logo=github&label=tests&logoColor=%23ccc" alt="Continuous Integration"></a>
<a href="https://codecov.io/github/vapor/fluent-postgres-driver"><img src="https://img.shields.io/codecov/c/github/vapor/fluent-postgres-driver?style=plastic&logo=codecov&label=codecov"></a>
<a href="https://swift.org"><img src="https://design.vapor.codes/images/swift58up.svg" alt="Swift 5.8+"></a>
</p>

<br>

FluentPostgresDriver is a [FluentKit] driver for PostgreSQL clients. It provides support for using the Fluent ORM with PostgreSQL databases, and uses [PostgresKit] to provide [SQLKit] driver services, [PostgresNIO] to connect and communicate with the database server asynchronously, and [AsyncKit] to provide connection pooling.

[FluentKit]: https://github.com/vapor/fluent-kit
[SQLKit]: https://github.com/vapor/sql-kit
[PostgresKit]: https://github.com/vapor/postgres-kit
[PostgresNIO]: https://github.com/vapor/postgres-nio
[AsyncKit]: https://github.com/vapor/async-kit

### Usage

Use the SPM string to easily include the dependendency in your `Package.swift` file:

```swift
.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0")
```

For additional information, see [the Fluent documentation](https://docs.vapor.codes/fluent/overview/).
