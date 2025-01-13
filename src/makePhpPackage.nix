inputs:

final: prev:

let
  inherit (prev) lib;

  pear = prev.fetchurl {
    url = "https://pear.php.net/install-pear-nozlib.phar";
    hash = "sha256-UblKVcsm030tNSA6mdeab+h7ZhANNz7MkFf4Z1iigjs=";
  };

  generic = "${inputs.nixpkgs}/pkgs/development/interpreters/php/generic.nix";

  makePhpPackage =
    {
      src,
      version ? null,
      patches ? [ ],
      cflags ? "",
      ...
    }:
    (
      prev.callPackage generic {
        hash = null;

        version =
          if version != null then
            version
          else
            let
              configureFile = "${src}/configure.ac";

              extractVersionFromConfigureAc =
                configureText:
                let
                  match = builtins.match ".*AC_INIT\\(\\[PHP],\\[([^]-]+)(-dev)?].*" configureText;
                in
                if match != null then builtins.head match else null;

              version =
                let
                  configureText = builtins.readFile configureFile;
                  version = extractVersionFromConfigureAc configureText;
                in
                if version != null then version else "0.0.0+unknown";
            in
            "${version}.snapshot.${inputs.self.lastModifiedDate}";

        phpAttrsOverrides = attrs: {
          inherit src;

          patches = attrs.patches or [ ] ++ (patches.php or [ ]);

          preInstall =
            attrs.preInstall or ""
            + ''
              if [[ ! -f ./pear/install-pear-nozlib.phar ]]; then
                cp ${pear} ./pear/install-pear-nozlib.phar
              fi
            '';

          NIX_CFLAGS_COMPILE = attrs.NIX_CFLAGS_COMPILE or "" + cflags;
        };

        packageOverrides = finalPO: prevPO: {
          extensions = prevPO.extensions // {
            intl = prevPO.extensions.intl.overrideAttrs (attrs: {
              buildInputs =
                if
                  (
                    lib.versions.majorMinor prevPO.php.version == "8.1" && lib.versionOlder prevPO.php.version "8.1.22"
                  )
                  || (
                    lib.versions.majorMinor prevPO.php.version == "8.2" && lib.versionOlder prevPO.php.version "8.2.9"
                  )
                then
                  (builtins.filter (pkg: pkg != prev.icu73) attrs.buildInputs) ++ [ prev.icu64 ]
                else
                  attrs.buildInputs;
            });

            dom = prevPO.extensions.dom.overrideAttrs (attrs: {
              NIX_CFLAGS_COMPILE = attrs.NIX_CFLAGS_COMPILE or "" + cflags;
              patches = (patches.dom or [ ]) ++ (attrs.patches or [])
                ++ lib.optionals (lib.versionAtLeast prev.php.version == "8.1" && lib.versionOlder prev.php.version == "8.1.31") [
                  # Fix tests with libxml2 2.12
                  (prev.fetchpatch {
                    url = "https://github.com/php/php-src/commit/061058a9b1bbd90d27d97d79aebcf2b5029767b0.patch";
                    hash = "sha256-0hOlAG+pOYp/gUU0MUMZvzWpgr0ncJi5GB8IeNxxyEU=";
                    excludes = [
                      "NEWS"
                    ];
            })
            # Backport of PHP_LIBXML_IGNORE_DEPRECATIONS_START and PHP_LIBXML_IGNORE_DEPRECATIONS_END
            # Required for libxml2 2.13 compatibility patch.
            (prev.fetchpatch {
              url = "https://github.com/php/php-src/commit/e2d97314ab342d434e778cd00a2f34e4bdb07664.patch";
              hash = "sha256-w0hyYUgbRGpvIBfWeDTSEUGpiJdyrtNjKy+Fn1vyAO0=";
            })
            # Fix build with libxml2 2.13+. Has to be applied after libxml2 2.12 patch.
            (prev.fetchpatch {
              url = "https://github.com/php/php-src/commit/4fe821311cafb18ca8bdf20b9d796c48a13ba552.patch";
              hash = "sha256-YC3I0BQi3o3+VmRu/UqpqPpaSC+ekPqzbORTHftbPvY=";
            })
          ];
            });

            opcache = prevPO.extensions.opcache.overrideAttrs (attrs: {
              NIX_CFLAGS_COMPILE = attrs.NIX_CFLAGS_COMPILE or "" + cflags;
              postPatch = lib.concatStringsSep "\n" [
                (attrs.postPatch or "")

                (lib.optionalString (prevPO.php.version == "8.1.14") ''
                  rm ext/opcache/tests/gh9968.phpt
                '')

                (lib.optionalString (prevPO.php.version == "8.2.1") ''
                  rm ext/opcache/tests/gh9968.phpt
                '')
              ];
            });

            openssl = prevPO.extensions.openssl.overrideAttrs (attrs: {
              NIX_CFLAGS_COMPILE = attrs.NIX_CFLAGS_COMPILE or "" + cflags;
              buildInputs =
                let
                  replaceOpenssl =
                    pkg:
                    if pkg.pname == "openssl" && lib.versionOlder prevPO.php.version "8.1" then
                      prev.openssl_1_1.overrideAttrs (old: {
                        meta = builtins.removeAttrs old.meta [ "knownVulnerabilities" ];
                      })
                    else
                      pkg;
                in
                builtins.map replaceOpenssl attrs.buildInputs;
            });

            # Since https://github.com/php/php-src/pull/14362
            # the SOAP extension requires the `session` extension.
            soap = prevPO.extensions.soap.overrideAttrs (attrs: {
              internalDeps = attrs.internalDeps or [ ] ++ [ prevPO.extensions.session ];
              patches = (patches.soap or [ ]) ++ (attrs.patches or []);
            });

            sockets = prevPO.extensions.sockets.overrideAttrs (attrs: {
              NIX_CFLAGS_COMPILE = attrs.NIX_CFLAGS_COMPILE or "" + cflags;
              patches =
                attrs.patches or [ ]
                ++ lib.optionals (prevPO.php.version == "8.0.15") [
                  # See https://github.com/php/php-src/pull/7981
                  (prev.fetchpatch {
                    url = "https://github.com/php/php-src/commit/6a6c8a60965c6fc3f145870a49b13b719ebd4a72.patch";
                    hash = "sha256-WCdHQIKBg24AWLAftHuCLZ+QqRVZXWdHFqZhmRSJ7+Y=";
                  })
                ]
                ++ lib.optionals (prevPO.php.version == "8.1.2") [
                  # See https://github.com/php/php-src/pull/7981
                  (prev.fetchpatch {
                    url = "https://github.com/php/php-src/commit/6a6c8a60965c6fc3f145870a49b13b719ebd4a72.patch";
                    hash = "sha256-WCdHQIKBg24AWLAftHuCLZ+QqRVZXWdHFqZhmRSJ7+Y=";
                  })
                ];
            });

            tokenizer = prevPO.extensions.tokenizer.overrideAttrs (attrs: {
              NIX_CFLAGS_COMPILE = attrs.NIX_CFLAGS_COMPILE or "" + cflags;
              patches = [ ] ++ lib.optionals (lib.versionAtLeast prevPO.php.version "8.1") attrs.patches;
            });

            sqlite3 = prevPO.extensions.sqlite3.overrideAttrs (attrs: {
              NIX_CFLAGS_COMPILE = attrs.NIX_CFLAGS_COMPILE or "" + cflags;
              patches = (patches.sqlite3 or [ ]) ++ (attrs.patches or []);
            });
            simplexml = prevPO.extensions.simplexml.overrideAttrs (attrs: {
              NIX_CFLAGS_COMPILE = attrs.NIX_CFLAGS_COMPILE or "" + cflags;
              patches = (patches.simplexml or [ ]) ++ (attrs.patches or []);
            });
            xmlwriter = prevPO.extensions.xmlwriter.overrideAttrs (attrs: {
              NIX_CFLAGS_COMPILE = attrs.NIX_CFLAGS_COMPILE or "" + cflags;
              patches = (patches.xmlwriter or [ ]) ++ (attrs.patches or []);
            });
          };
        };
      }
      // {
        NIX_CFLAGS_COMPILE = prev.NIX_CFLAGS_COMPILE + cflags;
      }
    );
in
makePhpPackage
