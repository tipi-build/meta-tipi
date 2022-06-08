# [tipi.build](https://tipi.build) - OpenEmbedded / Yocto Layer
As Yocto is a wonderful project to create custom linux distributions for any system architectures and particularly useful for linux embedded projects. 

tipi.build can be used as a a build system within Yocto thanks to this integration. With `inherit tipi` it is possible to build any C or C++ codebase and package it as a Yocto package, by adding a recipe as shown in [recipes-examples/simple-example](./recipes-examples/simple-example/simple-example.bb) :

```python
SUMMARY = "Simple example of a project built with tipi"
SRC_URI = "https://github.com/tipi-build/simple-example/archive/refs/heads/main.zip"
S = "${WORKDIR}/simple-example-main"

SRC_URI[sha256sum] = "cf4973ed9be15d0704c62262d498d2f0931c8ca629ce5de0d9050764c74cfd95"

inherit tipi
```

[Complete example here](./recipes-examples/simple-example/simple-example.bb)


## Getting Started
To start using the meta-tipi layer in yocto, you will need the following : 

1. Setup poky `git clone git://git.yoctoproject.org/poky --branch dunfell && cd poky`
2. Clone this layer `git clone https://github.com/tipi-build/meta-tipi.git`  
3. Enable a build folder with meta-tipi enabled : `TEMPLATECONF=meta-tipi/conf source oe-init-build-env`
4. To try the integration run `bitbake simple-example`
