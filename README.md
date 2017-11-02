# Swagger/OpenAPI 2.0 Importer

A [Paw Extension](https://paw.cloud/extensions) to import [Swagger](http://swagger.io/) (aka. [OpenAPI](https://www.openapis.org/)) API description files into Paw.

## How to use?

* In Paw, go to File menu, then Import...
* Pick the saved Swagger file, and make sure the Format is "Swagger 2.0 Importer"

## Versions supported

Only [Swagger 2.0 specification](https://github.com/swagger-api/swagger-spec/blob/master/versions/2.0.md) is supported.

* For Swagger 1.2 files, follow the [Swagger 1.2 to 2.0 Migration Guide](https://github.com/swagger-api/swagger-spec/wiki/Swagger-1.2-to-2.0-Migration-Guide)
* For Swagger 3.0 files, unfortunately it isn't yet supported at this point

## Development

⚠️ This project is entierly based on [API Flow](https://github.com/luckymarmot/API-Flow). This repository only containes the compiled file for this extension. Please refer to the *API Flow* repository for the orignal source code and for development.

The commands below refer to the *API Flow* project.

### Prerequisites

```shell
nvm install
yarn install
```

### Build and install to Paw

```shell
TARGET="swagger" make transfer
```

### Build for deployment

```shell
TARGET="swagger" make pack
```

## License

This Paw Extension is released under the [MIT License](https://github.com/luckymarmot/API-Flow/blob/develop/LICENSE). Feel free to fork, and modify!

Copyright © 2014-2017 [Paw](https://paw.cloud)
