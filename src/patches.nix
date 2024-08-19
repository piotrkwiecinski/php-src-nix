{ fetchpatch }:
{
  libxmlpatch = (
    fetchpatch {
      url = "https://github.com/php/php-src/commit/0a39890c967aa57225bb6bdf4821aff7a3a3c082.patch";
      hash = "sha256-HvpTL7aXO9gr4glFdhqUWQPrG8TYTlvbNINq33M3zS0=";
    }
  );
  libxmlpatch8300only = ./patches/0001-php8.3.0-only-libxml-fix.patch;
  ext_sqlite3 = (
    fetchpatch {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/development/interpreters/php/skip-sqlite3_bind_bug68849.phpt.patch";
      hash = "sha256-D4UeUTHlSVJqcHiyj7smvhPnOyV51S2OloWcUmRWwJY=";
    }
  );
  # https://github.com/php/php-src/commit/2a4775d6a73e9f6d4fc8e7df6f052aa18790a8e9
  ext_sqlite3_tests = (
    fetchpatch {
      url = "https://github.com/php/php-src/commit/2a4775d6a73e9f6d4fc8e7df6f052aa18790a8e9.patch";
      hash = "sha256-2VNfURGZmIEXtoLxOLX5wec9mqNGEWPY3ofCMw4E7S0=";
      excludes = [ "NEWS" ];
    }
  );
  ext_dom = (
    fetchpatch {
      url = "https://github.com/php/php-src/commit/061058a9b1bbd90d27d97d79aebcf2b5029767b0.patch";
      hash = "sha256-0hOlAG+pOYp/gUU0MUMZvzWpgr0ncJi5GB8IeNxxyEU=";
      excludes = [ "NEWS" ];
    }
  );
  ext_dom_tests_php8118 = ./patches/0001-php8118-libxml212-tests.patch;
  ext_dom_tests_php8120 = ./patches/0001-php8120-libxml212-tests.patch;
  ext_dom_tests = (
    fetchpatch {
      url = "https://raw.githubusercontent.com/fossar/nix-phps/master/pkgs/patches/libxml-ext.patch";
      hash = "sha256-hDoxYTOf+cDo3CeTdDc6aNe+uIBqnjlXAq54agjmSqI=";
    }
  );
  ext_dom_tests_php83 = (
    fetchpatch {
      url = "https://github.com/php/php-src/commit/061058a9b1bbd90d27d97d79aebcf2b5029767b0.patch";
      hash = "sha256-0hOlAG+pOYp/gUU0MUMZvzWpgr0ncJi5GB8IeNxxyEU=";
      excludes = [ "NEWS" ];
    }
  );
  ext_libxml_php8214 = (
    fetchpatch {
      url = "https://github.com/php/php-src/commit/e2d97314ab342d434e778cd00a2f34e4bdb07664.patch";
      hash = "sha256-w0hyYUgbRGpvIBfWeDTSEUGpiJdyrtNjKy+Fn1vyAO0=";
    }
  );
  ext_libxml_php830_832 = (
    fetchpatch {
      url = "https://github.com/php/php-src/commit/120bd364aaa8093bb592dcab4badba61d3103158.patch";
      hash = "sha256-+BClPkQHsI9zyeQvCH1IuZcabByy7uPHcFS1iTmBHKU=";
    }
  );
  ext_dom_memory_leak = (
    fetchpatch {
      url = "https://github.com/php/php-src/commit/20ac42e1b065e23376e7ea548995636369809a7d.patch";
      hash = "sha256-IBsaHj7tP3UdchPk9e5kUcIxdRW1nmTbRGsWOqKG1aE=";
    }
  );
}
