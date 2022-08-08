# The standard set of gems in nixpkgs including potential fixes.
#
# The gemset is derived from two points of entry:
# - An attrset describing a gem, including version, source and dependencies
#   This is just meta data, most probably automatically generated by a tool
#   like Bundix (https://github.com/aflatter/bundix).
#   {
#     name = "bundler";
#     version = "1.6.5";
#     sha256 = "1s4x0f5by9xs2y24jk6krq5ky7ffkzmxgr4z1nhdykdmpsi2zd0l";
#     dependencies = [ "rake" ];
#   }
# - An optional derivation that may override how the gem is built. For popular
#   gems that don't behave correctly, fixes are already provided in the form of
#   derivations.
#
# This seperates "what to build" (the exact gem versions) from "how to build"
# (to make gems behave if necessary).

{ lib, fetchurl, writeScript, ruby, libkrb5, libxml2, libxslt, python2, stdenv, which
, libiconv, postgresql, v8, clang, sqlite, zlib, imagemagick, lasem
, pkg-config , ncurses, xapian, gpgme, util-linux, tzdata, icu, libffi
, cmake, libssh2, openssl, libmysqlclient, git, perl, pcre, gecode_3, curl
, msgpack, libsodium, snappy, libossp_uuid, lxc, libpcap, xorg, gtk2, buildRubyGem
, cairo, re2, rake, gobject-introspection, gdk-pixbuf, zeromq, czmq, graphicsmagick, libcxx
, file, libvirt, glib, vips, taglib, libopus, linux-pam, libidn, protobuf, fribidi, harfbuzz
, bison, flex, pango, python3, patchelf, binutils, freetds, wrapGAppsHook, atk
, bundler, libsass, libexif, libselinux, libsepol, shared-mime-info, libthai, libdatrie
, CoreServices, DarwinTools, cctools, libtool, discount, exiv2, libmaxminddb
}@args:

let
  rainbow_rake = buildRubyGem {
    pname = "rake";
    gemName = "rake";
    source.sha256 = "01j8fc9bqjnrsxbppncai05h43315vmz9fwg28qdsgcjw9ck1d7n";
    type = "gem";
    version = "12.0.0";
  };
in

{
  ZenTest = attrs: {
    meta.mainProgram = "zentest";
  };

  atk = attrs: {
    dependencies = attrs.dependencies ++ [ "gobject-introspection" ];
    nativeBuildInputs = [ rake bundler pkg-config ]
      ++ lib.optionals stdenv.isDarwin [ DarwinTools ];
    propagatedBuildInputs = [ gobject-introspection wrapGAppsHook atk ];
  };

  bundler = attrs:
    let
      templates = "${attrs.ruby.gemPath}/gems/${attrs.gemName}-${attrs.version}/lib/bundler/templates/";
    in {
      # patching shebangs would fail on the templates/Executable file, so we
      # temporarily remove the executable flag.
      preFixup  = "chmod -x $out/${templates}/Executable";
      postFixup = ''
        chmod +x $out/${templates}/Executable

        # Allows to load another bundler version
        sed -i -e "s/activate_bin_path/bin_path/g" $out/bin/bundle
      '';
    };

  cairo = attrs: {
    nativeBuildInputs = [ pkg-config ]
      ++ lib.optionals stdenv.isDarwin [ DarwinTools ];
    buildInputs = [ gtk2 pcre xorg.libpthreadstubs xorg.libXdmcp];
  };

  cairo-gobject = attrs: {
    nativeBuildInputs = [ pkg-config ]
      ++ lib.optionals stdenv.isDarwin [ DarwinTools ];
    buildInputs = [ cairo pcre xorg.libpthreadstubs xorg.libXdmcp ];
  };

  charlock_holmes = attrs: {
    buildInputs = [ which icu zlib ];
  };

  cld3 = attrs: {
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ protobuf ];
  };

  cocoapods-acknowledgements = attrs: {
    dependencies = attrs.dependencies ++ [ "cocoapods" ];
  };

  cocoapods-deploy = attrs: {
    dependencies = [ "cocoapods" ];
  };

  cocoapods-disable-podfile-validations = attrs: {
    dependencies = [ "cocoapods" ];
  };

  cocoapods-generate = attrs: {
    dependencies = attrs.dependencies ++ [ "cocoapods" ];
  };

  cocoapods-git_url_rewriter = attrs: {
    dependencies = [ "cocoapods" ];
  };

  cocoapods-keys = attrs: {
    dependencies = attrs.dependencies ++ [ "cocoapods" ];
  };

  cocoapods-open = attrs: {
    dependencies = [ "cocoapods" ];
  };

  cocoapods-try-release-fix = attrs: {
    dependencies = [ "cocoapods" ];
  };

  curb = attrs: {
    buildInputs = [ curl ];
  };

  curses = attrs: {
    buildInputs = [ ncurses ];
  };

  dep-selector-libgecode = attrs: {
    USE_SYSTEM_GECODE = true;
    postInstall = ''
      installPath=$(cat $out/nix-support/gem-meta/install-path)
      sed -i $installPath/lib/dep-selector-libgecode.rb -e 's@VENDORED_GECODE_DIR =.*@VENDORED_GECODE_DIR = "${gecode_3}"@'
    '';
  };

  digest-sha3 = attrs: {
    hardeningDisable = [ "format" ];
  };

  rdiscount = attrs: {
    # Use discount from nixpkgs instead of vendored version
    dontBuild = false;
    buildInputs = [ discount ];
    patches = [
      # Adapted from Debian:
      # https://sources.debian.org/data/main/r/ruby-rdiscount/2.1.8-1/debian/patches/01_use-system-libmarkdown.patch
      ./rdiscount-use-nixpkgs-libmarkdown.patch
    ];
  };

  ethon = attrs: {
    dontBuild = false;
    postPatch = ''
      substituteInPlace lib/ethon/curls/settings.rb \
        --replace "libcurl" "${curl.out}/lib/libcurl${stdenv.hostPlatform.extensions.sharedLibrary}"
    '';
  };

  exiv2 = attrs: {
    buildFlags = [ "--with-exiv2-lib=${exiv2}/lib" "--with-exiv2-include=${exiv2.dev}/include" ];
  };

  fog-dnsimple = attrs:
    lib.optionalAttrs (lib.versionOlder attrs.version "1.0.1") {
      postInstall = ''
        cd $(cat $out/nix-support/gem-meta/install-path)
        rm {$out/bin,bin,../../bin}/{setup,console}
      '';
    };

  redis-rack = attrs: {
    dontBuild = false;
    preBuild = ''
      exec 3>&1
      output="$(gem build $gemspec | tee >(cat - >&3))"
      exec 3>&-
      sed -i 's!"rake".freeze!!' $gemspec
    '';
  };

  ffi-rzmq-core = attrs: {
    postInstall = ''
      installPath=$(cat $out/nix-support/gem-meta/install-path)
      sed -i $installPath/lib/ffi-rzmq-core/libzmq.rb -e 's@inside_gem =.*@inside_gem = "${zeromq}/lib"@'
    '';
  };

  mimemagic = attrs: {
    FREEDESKTOP_MIME_TYPES_PATH = "${shared-mime-info}/share/mime/packages/freedesktop.org.xml";
  };

  mini_magick = attrs: {
    postInstall = ''
      installPath=$(cat $out/nix-support/gem-meta/install-path)
      echo -e "\nENV['PATH'] += ':${graphicsmagick}/bin'\n" >> $installPath/lib/mini_magick/configuration.rb
    '';
  };

  do_sqlite3 = attrs: {
    buildInputs = [ sqlite ];
  };

  eventmachine = attrs: {
    buildInputs = [ openssl ];
  };

  exif = attrs: {
    buildFlags = [ "--with-exif-dir=${libexif}" ];
    buildInputs = [ libexif ];
  };

  ffi = attrs: {
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ libffi ];
  };

  gdk_pixbuf2 = attrs: {
    nativeBuildInputs = [ pkg-config bundler rake ]
      ++ lib.optionals stdenv.isDarwin [ DarwinTools ];
    propagatedBuildInputs = [ gobject-introspection wrapGAppsHook gdk-pixbuf ];
  };

  gpgme = attrs: {
    buildInputs = [ gpgme ];
    buildFlags = [ "--use-system-libraries" ];
  };

  gio2 = attrs: {
    nativeBuildInputs = [ pkg-config ]
      ++ lib.optionals stdenv.isDarwin [ DarwinTools ];
    buildInputs = [ gtk2 pcre gobject-introspection ] ++ lib.optionals stdenv.isLinux [ util-linux libselinux libsepol ];
  };

  gitlab-markup = attrs: { meta.priority = 1; };

  gitlab-pg_query = attrs: lib.optionalAttrs (attrs.version == "1.3.1") {
    dontBuild = false;
    postPatch = ''
      sed -i "s;'https://codeload.github.com.*';'${fetchurl {
        url = "https://codeload.github.com/lfittl/libpg_query/tar.gz/10-1.0.3";
        sha256 = "0jfij8apzxsdabl70j42xgd5f3ka1gdcrk764nccp66164gpcchk";
      }}';" ext/pg_query/extconf.rb
    '';
  };

  parser = attrs: {
    meta.mainProgram = "ruby-parse";
  };

  pg_query = attrs: lib.optionalAttrs (attrs.version == "2.0.2") {
    dontBuild = false;
    postPatch = ''
      sed -i "s;'https://codeload.github.com.*';'${fetchurl {
        url = "https://codeload.github.com/lfittl/libpg_query/tar.gz/13-2.0.2";
        sha256 = "0ms2s6hmy8qyzv4g1hj4i2p5fws1v8lrj73b2knwbp2ipd45yj7y";
      }}';" ext/pg_query/extconf.rb
    '';
  } // lib.optionalAttrs (attrs.version == "1.3.0") {
    # Needed for gitlab
    dontBuild = false;
    postPatch = ''
      sed -i "s;'https://codeload.github.com.*';'${fetchurl {
        url = "https://codeload.github.com/lfittl/libpg_query/tar.gz/10-1.0.4";
        sha256 = "0f0kshhai0pnkqj0w4kgz3fssnvwidllc31n1fysxjjzdqlr1k48";
      }}';" ext/pg_query/extconf.rb
    '';
  };

  prettier = attrs: {
    meta.mainProgram = "rbprettier";
  };

  glib2 = attrs: {
    nativeBuildInputs = [ pkg-config ]
      ++ lib.optionals stdenv.isDarwin [ DarwinTools ];
    buildInputs = [ gtk2 pcre ];
  };

  gtk2 = attrs: {
    nativeBuildInputs = [
      binutils pkg-config
    ] ++ lib.optionals stdenv.isLinux [
      util-linux libselinux libsepol
    ] ++ lib.optionals stdenv.isDarwin [ DarwinTools ];
    propagatedBuildInputs = [
      atk
      gdk-pixbuf
      fribidi
      gobject-introspection
      gtk2
      harfbuzz
      libdatrie
      libthai
      pcre
      xorg.libpthreadstubs
      xorg.libXdmcp
    ];
    dontStrip = stdenv.isDarwin;
  };

  gobject-introspection = attrs: {
    nativeBuildInputs = [ pkg-config pcre ]
      ++ lib.optionals stdenv.isDarwin [ DarwinTools ];
    propagatedBuildInputs = [ gobject-introspection wrapGAppsHook glib ];
  };

  gollum = attrs: {
    dontBuild = false;
    postPatch = ''
      substituteInPlace bin/gollum \
        --replace "/usr/bin/env -S ruby" "${ruby}/bin/ruby"
    '';
  };

  grpc = attrs: {
    nativeBuildInputs = [ pkg-config ] ++ lib.optional stdenv.isDarwin libtool;
    buildInputs = [ openssl ];
    hardeningDisable = [ "format" ];
    NIX_CFLAGS_COMPILE = toString [
      "-Wno-error=stringop-overflow"
      "-Wno-error=implicit-fallthrough"
      "-Wno-error=sizeof-pointer-memaccess"
      "-Wno-error=cast-function-type"
      "-Wno-error=class-memaccess"
      "-Wno-error=ignored-qualifiers"
      "-Wno-error=tautological-compare"
      "-Wno-error=stringop-truncation"
    ];
    dontBuild = false;
    postPatch = ''
      substituteInPlace Makefile \
        --replace '-Wno-invalid-source-encoding' ""
    '' + lib.optionalString stdenv.isDarwin ''
      # For < v1.48.0
      substituteInPlace src/ruby/ext/grpc/extconf.rb \
        --replace "ENV['AR'] = 'libtool -o' if RUBY_PLATFORM =~ /darwin/" ""
      # For >= v1.48.0
      substituteInPlace src/ruby/ext/grpc/extconf.rb \
        --replace 'apple_toolchain = ' 'apple_toolchain = false && '
    '';
  };

  hitimes = attrs: {
    buildInputs = lib.optionals stdenv.isDarwin [ CoreServices ];
  };

  iconv = attrs: {
    buildFlags = lib.optional stdenv.isDarwin "--with-iconv-dir=${libiconv}";
  };

  idn-ruby = attrs: {
    buildInputs = [ libidn ];
  };

  # disable bundle install as it can't install anything in addition to what is
  # specified in pkgs/applications/misc/jekyll/Gemfile anyway. Also do chmod_R
  # to compensate for read-only files in site_template in nix store.
  jekyll = attrs: {
    postInstall = ''
      installPath=$(cat $out/nix-support/gem-meta/install-path)
      sed -i $installPath/lib/jekyll/commands/new.rb \
          -e 's@Exec.run("bundle", "install"@Exec.run("true"@' \
          -e 's@FileUtils.cp_r site_template + "/.", path@FileUtils.cp_r site_template + "/.", path; FileUtils.chmod_R "u+w", path@'
    '';
  };

  # note that you need version >= v3.16.14.8,
  # otherwise the gem will fail to link to the libv8 binary.
  # see: https://github.com/cowboyd/libv8/pull/161
  libv8 = attrs: {
    buildInputs = [ which v8 python2 ];
    buildFlags = [ "--with-system-v8=true" ];
    dontBuild = false;
    postPatch = ''
      substituteInPlace ext/libv8/extconf.rb \
        --replace "location = Libv8::Location::Vendor.new" \
                  "location = Libv8::Location::System.new"
    '';
  };

  execjs = attrs: {
    propagatedBuildInputs = [ v8 ];
  };

  libxml-ruby = attrs: {
    buildFlags = [
      "--with-xml2-lib=${libxml2.out}/lib"
      "--with-xml2-include=${libxml2.dev}/include/libxml2"
    ];
  };

  mathematical = attrs: {
    nativeBuildInputs = [
      ruby
      cmake
      bison
      flex
      pkg-config
      python3
      patchelf
    ];

    buildInputs = [
      cairo
      fribidi
      gdk-pixbuf
      glib
      libxml2
      pango
    ];

    strictDeps = true;

    # The ruby build script takes care of this
    dontUseCmakeConfigure = true;

    postInstall = ''
      # Reduce output size by a lot, and remove some unnecessary references.
      # The ext directory should only be required at build time, so
      # can be deleted now.
      rm -r $out/${ruby.gemPath}/gems/mathematical-${attrs.version}/ext \
            $out/${ruby.gemPath}/extensions/*/*/mathematical-${attrs.version}/gem_make.out
    '';

    # For some reason 'mathematical.so' is missing cairo, glib, and
    # lasem in its RPATH, add them explicitly here
    postFixup = lib.optionalString stdenv.isLinux ''
      soPath="$out/${ruby.gemPath}/gems/mathematical-${attrs.version}/lib/mathematical/mathematical.so"
      rpath="$(patchelf --print-rpath "$soPath")"
      patchelf --set-rpath "${lib.makeLibraryPath [ lasem glib cairo ]}:$rpath" "$soPath"
      patchelf --replace-needed liblasem.so liblasem-0.4.so "$soPath"
    '';
  };

  magic = attrs: {
    buildInputs = [ file ];
    postInstall = ''
      installPath=$(cat $out/nix-support/gem-meta/install-path)
      sed -e 's@ENV\["MAGIC_LIB"\] ||@ENV\["MAGIC_LIB"\] || "${file}/lib/libmagic.so" ||@' -i $installPath/lib/magic/api.rb
    '';
  };

  maxmind_geoip2 = attrs: {
    buildFlags = [ "--with-maxminddb-lib=${libmaxminddb}/lib" "--with-maxminddb-include=${libmaxminddb}/include" ];
  };

  metasploit-framework = attrs: {
    preInstall = ''
      export HOME=$TMPDIR
    '';
  };

  msgpack = attrs: {
    buildInputs = [ msgpack ];
  };

  mysql = attrs: {
    buildInputs = [ libmysqlclient zlib openssl ];
  };

  mysql2 = attrs: {
    buildInputs = [ libmysqlclient zlib openssl ];
  };

  ncursesw = attrs: {
    buildInputs = [ ncurses ];
    buildFlags = [
      "--with-cflags=-I${ncurses.dev}/include"
      "--with-ldflags=-L${ncurses.out}/lib"
    ];
  };

  nokogiri = attrs: {
    buildFlags = [
      "--use-system-libraries"
      "--with-zlib-lib=${zlib.out}/lib"
      "--with-zlib-include=${zlib.dev}/include"
      "--with-xml2-lib=${libxml2.out}/lib"
      "--with-xml2-include=${libxml2.dev}/include/libxml2"
      "--with-xslt-lib=${libxslt.out}/lib"
      "--with-xslt-include=${libxslt.dev}/include"
      "--with-exslt-lib=${libxslt.out}/lib"
      "--with-exslt-include=${libxslt.dev}/include"
    ] ++ lib.optionals stdenv.isDarwin [
      "--with-iconv-dir=${libiconv}"
      "--with-opt-include=${libiconv}/include"
    ];
  };

  openssl = attrs: {
    buildInputs = [ openssl ];
  };

  opus-ruby = attrs: {
    dontBuild = false;
    postPatch = ''
      substituteInPlace lib/opus-ruby.rb \
        --replace "ffi_lib 'opus'" \
                  "ffi_lib '${libopus}/lib/libopus${stdenv.hostPlatform.extensions.sharedLibrary}'"
    '';
  };

  ovirt-engine-sdk = attrs: {
    buildInputs = [ curl libxml2 ];
  };

  pango = attrs: {
    nativeBuildInputs = [
      pkg-config
      fribidi
      harfbuzz
      pcre
      xorg.libpthreadstubs
      xorg.libXdmcp
    ] ++ lib.optionals stdenv.isDarwin [ DarwinTools ];
    buildInputs = [ libdatrie libthai ]
      ++ lib.optionals stdenv.isLinux [ libselinux libsepol util-linux ];
    propagatedBuildInputs = [ gobject-introspection wrapGAppsHook gtk2 ];
  };

  patron = attrs: {
    buildInputs = [ curl ];
  };

  pcaprub = attrs: {
    buildInputs = [ libpcap ];
  };

  pg = attrs: {
    buildFlags = [
      "--with-pg-config=${postgresql}/bin/pg_config"
    ];
  };

  puma = attrs: {
    buildInputs = [ openssl ];
  };

  rack = attrs: {
    meta.mainProgram = "rackup";
  };

  railties = attrs: {
    meta.mainProgram = "rails";
  };

  rainbow = attrs: {
    buildInputs = [ rainbow_rake ];
  };

  rbczmq = { ... }: {
    buildInputs = [ zeromq czmq ];
    buildFlags = [ "--with-system-libs" ];
  };

  rbnacl = spec:
    if lib.versionOlder spec.version "6.0.0" then {
      postInstall = ''
        sed -i $(cat $out/nix-support/gem-meta/install-path)/lib/rbnacl.rb -e "2a \
        RBNACL_LIBSODIUM_GEM_LIB_PATH = '${libsodium.out}/lib/libsodium${stdenv.hostPlatform.extensions.sharedLibrary}'
        "
      '';
    } else {
      dontBuild = false;
      postPatch = ''
        substituteInPlace lib/rbnacl/sodium.rb \
          --replace 'ffi_lib ["sodium"' \
                    'ffi_lib ["${libsodium}/lib/libsodium${stdenv.hostPlatform.extensions.sharedLibrary}"'
      '';
    };

  re2 = attrs: {
    buildInputs = [ re2 ];
  };

  rest-client = attrs: {
    meta.mainProgram = "restclient";
  };

  rmagick = attrs: {
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ imagemagick which ];
  };

  rouge = attrs: {
    meta.mainProgram = "rougify";
  };

  rpam2 = attrs: {
    buildInputs = [ linux-pam ];
  };

  rspec-core = attrs: {
    meta.mainProgram = "rspec";
  };

  ruby-libvirt = attrs: {
    buildInputs = [ libvirt pkg-config ];
    buildFlags = [
      "--with-libvirt-include=${libvirt}/include"
      "--with-libvirt-lib=${libvirt}/lib"
    ];
  };

  ruby-lxc = attrs: {
    buildInputs = [ lxc ];
  };

  ruby-terminfo = attrs: {
    buildInputs = [ ncurses ];
    buildFlags = [
      "--with-cflags=-I${ncurses.dev}/include"
      "--with-ldflags=-L${ncurses.out}/lib"
    ];
  };

  ruby-vips = attrs: {
    postInstall = ''
      cd "$(cat $out/nix-support/gem-meta/install-path)"

      substituteInPlace lib/vips.rb \
        --replace 'library_name("vips", 42)' '"${lib.getLib vips}/lib/libvips${stdenv.hostPlatform.extensions.sharedLibrary}"' \
        --replace 'library_name("glib-2.0", 0)' '"${glib.out}/lib/libglib-2.0${stdenv.hostPlatform.extensions.sharedLibrary}"' \
        --replace 'library_name("gobject-2.0", 0)' '"${glib.out}/lib/libgobject-2.0${stdenv.hostPlatform.extensions.sharedLibrary}"'
    '';
  };

  rugged = attrs: {
    nativeBuildInputs = [ cmake pkg-config which ] ++ lib.optional stdenv.isDarwin libiconv;
    buildInputs = [ openssl libssh2 zlib ];
    dontUseCmakeConfigure = true;
  };

  sassc = attrs: {
    nativeBuildInputs = [ rake ];
    dontBuild = false;
    SASS_LIBSASS_PATH = toString libsass;
    postPatch = ''
      substituteInPlace lib/sassc/native.rb \
        --replace 'gem_root = spec.gem_dir' 'gem_root = File.join(__dir__, "../../")'
    '';
  } // (lib.optionalAttrs stdenv.isDarwin {
    # https://github.com/NixOS/nixpkgs/issues/19098
    buildFlags = [ "--disable-lto" ];
  });

  scrypt = attrs: lib.optionalAttrs stdenv.isDarwin {
    dontBuild = false;
    postPatch = ''
      sed -i -e "s/-arch i386//" Rakefile ext/scrypt/Rakefile
    '';
  };

  semian = attrs: {
    buildInputs = [ openssl ];
  };

  sequel_pg = attrs: {
    buildInputs = [ postgresql ];
  };

  snappy = attrs: {
    buildInputs = [ args.snappy ];
  };

  sqlite3 = attrs: {
    buildFlags = [
      "--with-sqlite3-include=${sqlite.dev}/include"
      "--with-sqlite3-lib=${sqlite.out}/lib"
    ];
  };

  rb-readline = attrs: {
    dontBuild = false;
    postPatch = ''
      substituteInPlace lib/rbreadline.rb \
        --replace 'infocmp' '${ncurses}/bin/infocmp'
    '';
  };

  taglib-ruby = attrs: {
    buildInputs = [ taglib ];
  };

  timfel-krb5-auth = attrs: {
    buildInputs = [ libkrb5 ];
  };

  tiny_tds = attrs: {
    nativeBuildInputs = [ pkg-config openssl ];
    buildInputs = [ freetds ];
  };

  treetop = attrs: {
    meta.mainProgram = "tt";
  };

  typhoeus = attrs: {
    buildInputs = [ curl ];
  };

  tzinfo = attrs: lib.optionalAttrs (lib.versionAtLeast attrs.version "1.0") {
    dontBuild = false;
    postPatch =
      let
        path = if lib.versionAtLeast attrs.version "2.0"
               then "lib/tzinfo/data_sources/zoneinfo_data_source.rb"
               else "lib/tzinfo/zoneinfo_data_source.rb";
      in
        ''
          substituteInPlace ${path} \
            --replace "/usr/share/zoneinfo" "${tzdata}/share/zoneinfo"
        '';
  };

  uuid4r = attrs: {
    buildInputs = [ which libossp_uuid ];
  };

  whois = attrs: {
    meta.mainProgram = "whoisrb";
  };

  xapian-ruby = attrs: {
    # use the system xapian
    dontBuild = false;
    nativeBuildInputs = [ rake pkg-config bundler ];
    buildInputs = [ xapian zlib ];
    postPatch = ''
      cp ${./xapian-Rakefile} Rakefile
    '';
    preInstall = ''
      export XAPIAN_CONFIG=${xapian}/bin/xapian-config
    '';
  };

  zlib = attrs: {
    buildInputs = [ zlib ];
  };

  zookeeper = attrs: {
    buildInputs = lib.optionals stdenv.isDarwin [ cctools ];
  };
}
