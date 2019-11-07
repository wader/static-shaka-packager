## static-shaka-packager

Image with shaka-packager binary built as hardened static PIE binaries with no
external dependencies. Can be used with any base image even scratch.

### Usage
```Dockerfile
COPY --from=mwader/static-shaka-packager:2.3.0 /shaka-packager /usr/local/bin/
```
```sh
docker run --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" mwader/static-shaka-packager:2.3.0 ...
```

### Files in the image
`/shaka-packager` shaka-packager binary  

### Security

Binary is built with various hardening features but it's probably still a good idea to run
them as non-root even when used inside a container, especially so if running on input files
that you don't control.
