#-------------------------
# renovate rebuild trigger
# a new upstream release needs a new `<version>.1` entry in builder.json
#-------------------------

# makes lint happy
FROM scratch


# renovate: datasource=github-releases depName=jsonnet-bundler/jsonnet-bundler
ENV JB_VERSION=0.6.0
