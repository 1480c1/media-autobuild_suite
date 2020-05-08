#!/bin/bash

# shellcheck source=build/media-suite_helper.sh
source "$LOCALBUILDDIR"/media-suite_helper.sh

_check=(lzlib.h share/info/lzlib.info liblz.a)
if ! files_exist "${_check[@]}" &&
    do_wget -h ca58122a089612562b659d287e1400c88422b45c674d00db7f4acc790c97dc90 \
        "http://download.savannah.gnu.org/releases/lzip/lzlib/lzlib-1.9.tar.lz"; then
    do_uninstall "${_check[@]}"
    do_configure
    do_makeinstall
    do_checkIfExist
fi

_check=(bin-global/hsts.exe libhsts.{h,pc,{l,}a})
if do_vcs "https://gitlab.com/rockdaboot/libhsts.git"; then
    do_uninstall "${_check[@]}"
    do_autoreconf
    do_separate_confmakeinstall global
    do_checkIfExist
fi

_check=(libunistring.{l,}a
    uni{str,conv,stdio,name,ctype,width,wbrk,lbrk,norm,case}.h)
if ! files_exist "${_check[@]}" &&
    do_wget -h a82e5b333339a88ea4608e4635479a1cfb2e01aafb925e1290b65710d43f610b \
        "https://ftp.gnu.org/gnu/libunistring/libunistring-0.9.10.tar.gz"; then
    do_uninstall include/unistring "${_check[@]}"
    do_separate_confmakeinstall
    do_checkIfExist
fi

_deps=(libunistring.a)
_check=(libidn2.{{,l}a,pc} idn2.h bin-global/idn2.exe)
if test_newer installed "${_deps[@]}" "${_check[0]}" &&
    do_wget -h e1cb1db3d2e249a6a3eb6f0946777c2e892d5c5dc7bd91c74394fc3a01cab8b5 \
        "https://ftp.gnu.org/gnu/libidn/libidn2-2.3.0.tar.gz"; then
    do_uninstall "${_check[@]}"
    # unistring also depends on iconv
    grep_or_sed '@LTLIBUNISTRING@ @LTLIBICONV@' libidn2.pc.in \
        's|(@LTLIBICONV@) (@LTLIBUNISTRING@)|\2 \1|'
    do_separate_confmakeinstall global --disable-{doc,rpath}
    do_checkIfExist
fi

_deps=(libidn2.a)
_check=(libpsl.{a,h,pc})
if do_vcs "https://github.com/rockdaboot/libpsl.git"; then
    do_uninstall "${_check[@]}"
    do_autogen
    CFLAGS+=" -liconv" do_mesoninstall global
    do_checkIfExist
fi

_check=(libnettle.a libhogweed.a nettle.pc hogweed.pc
    bin-global/{sexp-conv,nettle-hash,nettle-pbkdf2,nettle-lfib-stream,pkcs1-conv}.exe)
if do_pkgConfig "nettle = 3.6" &&
    do_wget -h d24c0d0f2abffbc8f4f34dcf114b0f131ec3774895f3555922fe2f40f3d5e3f1 \
        "https://ftp.gnu.org/gnu/nettle/nettle-3.6.tar.gz"; then
    do_uninstall include/nettle
    do_separate_confmakeinstall global
    do_checkIfExist
fi

_deps=(libnettle.a)
_check=(libgnutls.{,l}a gnutls.pc)
if { test_newer installed "${_deps[@]}" "${_check[0]}" ||
    do_pkgConfig "gnutls = 3.6.13"; } &&
    do_wget -h 32041df447d9f4644570cf573c9f60358e865637d69b7e59d1159b7240b52f38 \
        "https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-3.6.13.tar.xz"; then
    do_uninstall include/gnutls "${_check[@]}"
    grep_or_sed crypt32 lib/gnutls.pc.in 's/Libs.private.*/& -lcrypt32/'
    do_separate_confmakeinstall \
        --disable-{cxx,doc,tools,tests,rpath,libdane,guile,gcc-warnings} \
        --without-{p11-kit,tpm} --enable-local-libopts \
        --disable-code-coverage \
        LDFLAGS="$LDFLAGS -L${LOCALDESTDIR}/lib -L${MINGW_PREFIX}/lib"
    do_checkIfExist
fi

_deps=(libgnutls.a)
_check=(libmicrohttpd.{pc,{,l}a})
if do_vcs "https://git.gnunet.org/libmicrohttpd.git"; then
    do_uninstall "${_check[@]}"
    do_autogen
    CFLAGS+=" -DGNUTLS_INTERNAL_BUILD" do_separate_confmakeinstall global
    do_checkIfExist
fi

# fix retarded google naming schemes for brotli
pacman -Qs "$MINGW_PACKAGE_PREFIX-brotli" > /dev/null 2>&1 &&
    grep_or_sed '-static' "$MINGW_PREFIX"/lib/pkgconfig/libbrotlidec.pc 's;-lbrotli.*;&-static;' \
        "$MINGW_PREFIX"/lib/pkgconfig/libbrotli{enc,dec,common}.pc

# For bootstrapping purposes
do_vcs "https://git.savannah.gnu.org/git/gnulib.git"

_check=(bin-global/wget2{,_noinstall}.exe
        wget{,ver}.h
        libwget.{pc,{,l}a})
if do_vcs "https://gitlab.com/gnuwget/wget2.git"; then
    do_pacman_install pcre2
    # functions in canonicalize-lgpl is already in libintl
    canonicalize=$(nm -CAg --defined-only "$MINGW_PREFIX/lib/libintl.a" |
        grep -- canonicalize_file_name | cut -d: -f3 | sort -u)
    ar x "$MINGW_PREFIX/lib/libintl.a" "$canonicalize"
    # Just weaken the whole object, the symbols can come from gnulib in wget2
    objcopy --weaken "$canonicalize"
    ar r "$MINGW_PREFIX/lib/libintl.a" "$canonicalize"
    rm "$canonicalize"
    unset canonicalize
    do_uninstall "${_check[@]}"
    log "bootstrap" ./bootstrap --skip-po --gnulib-srcdir="$LOCALBUILDDIR"/gnulib-git
    CFLAGS+=" -DNGHTTP2_STATICLIB -DIN_LIBUNISTRING -DGNUTLS_INTERNAL_BUILD -DPCRE2_STATIC -L${LOCALDESTDIR}/lib -lnettle" \
        do_separate_confmakeinstall global \
        --disable-{manylibs,doc}
    do_checkIfExist
fi
