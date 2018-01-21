# This file is part of MXE. See LICENSE.md for licensing information.

# Variant on sdl2_mixer.mk
# Unfortunately not entirely automated:
# First ensure mxe has compiled sdl2, eg run the 'make' command given below,
# or just delete 'sdl2' from the DEPS.
# You need to provide SDL2.dll, to prevent mxe from statically linking it.
# You can either compile sdl2 yourself:
#   make MXE_TARGETS=i686-w64-mingw32.shared sdl2
# (note the 'shared') which will compile gcc, etc, a second time, or just
# download the SDL2 development libraries:
#   wget https://www.libsdl.org/release/SDL2-devel-2.0.7-mingw.tar.gz
#   tar xf SDL2-devel-2.0.7-mingw.tar.gz
#   cp SDL2-2.0.7/i686-w64-mingw32/lib/libSDL2*  usr/i686-w64-mingw32.static/lib/
#   cp SDL2-2.0.7/i686-w64-mingw32/bin/*  usr/i686-w64-mingw32.static/bin/
#   sed -i -e "s|^libdir=.*$|libdir='$(pwd)/usr/i686-w64-mingw32.static/lib'|" usr/i686-w64-mingw32.static/lib/libSDL2.la
# (usr/i686-w64-mingw32.static/lib/libSDL2.la needs to contain correct
# dlname='../bin/SDL2.dll' and library_names='libSDL2.dll.a')
# Compile:
#   make MXE_TARGETS=i686-w64-mingw32.static sdl_mixer_ohrrpgce
# Strip the resulting .dll:
#   cp usr/i686-w64-mingw32.static/bin/SDL2_mixer.dll SDL2_mixer.dll
#   strip SDL2_mixer.dll
# Check that it links dynamically to SDL2.dll:
#   objdump -x SDL2_mixer.dll | grep SDL2.dll

# FLAC disabled because we don't use it.
# libmad used just because it produces a smaller .dll (~750KB vs ~950KB)
# and because we've been using it for a while.
# But mpg123 is the default, and is actually maintained and faster.
# smpeg is very bad, doesn't work at most bitrates, and is crashy.
# libmodplug used instead of mikmod because it's much higher quality; see
# https://www.slimesalad.com/forum/viewtopic.php?t=6810

PKG             := sdl2_mixer_ohrrpgce
$(PKG)_WEBSITE  := https://www.libsdl.org/projects/SDL_mixer/
$(PKG)_DESCR    := SDL2_mixer
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 2.0.2
$(PKG)_CHECKSUM := 4e615e27efca4f439df9af6aa2c6de84150d17cbfd12174b54868c12f19c83bb
$(PKG)_SUBDIR   := SDL2_mixer-$($(PKG)_VERSION)
$(PKG)_FILE     := SDL2_mixer-$($(PKG)_VERSION).tar.gz
$(PKG)_URL      := https://www.libsdl.org/projects/SDL_mixer/release/$($(PKG)_FILE)
$(PKG)_DEPS     := cc libmap libmodplug ogg sdl2 vorbis # mpg123 smpeg2

define $(PKG)_UPDATE
    $(WGET) -q -O- 'https://hg.libsdl.org/SDL_mixer/tags' | \
    $(SED) -n 's,.*release-\([0-9][^<]*\).*,\1,p' | \
    head -1
endef

define $(PKG)_BUILD
    $(SED) -i 's,^\(Requires:.*\),\1 vorbisfile,' '$(1)/SDL2_mixer.pc.in'
    echo \
        'Libs.private:' \
        >> '$(1)/SDL2_mixer.pc.in'
    $(SED) -i 's,for path in /usr/local; do,for path in; do,' '$(1)/configure'
    cd '$(1)' && ./configure \
        $(MXE_CONFIGURE_OPTS) \
        --enable-shared \
        --with-sdl-prefix='$(PREFIX)/$(TARGET)' \
        --disable-sdltest \
        --enable-music-mod \
        --enable-music-mod-modplug \
        --enable-music-ogg \
        --disable-music-ogg-shared \
        --disable-music-flac \
        --disable-music-flac-shared \
        --enable-music-mp3 \
        --disable-music-mp3-smpeg \
        --disable-music-mp3-mpg123 \
        --disable-music-mp3-mpg123-shared \
        --enable-music-mp3-mad-gpl \
        --enable-music-mp3-mad-gpl-dithering \
        --disable-music-mp3-mad-gpl-shared \
        --disable-smpegtest \
        SMPEG_CONFIG='$(PREFIX)/$(TARGET)/bin/smpeg2-config' \
        WINDRES='$(TARGET)-windres' \
        LIBS='-lvorbis -logg' \
	LDFLAGS='-Wl,-export-all-symbols'

    $(MAKE) -C '$(1)' -j '$(JOBS)' install-lib install-hdrs $(MXE_DISABLE_CRUFT)

    '$(TARGET)-gcc' \
        -W -Wall -Werror -ansi -pedantic \
        '$(TOP_DIR)/src/sdl_mixer-test.c' -o '$(PREFIX)/$(TARGET)/bin/test-sdl2_mixer.exe' \
        `'$(TARGET)-pkg-config' SDL2_mixer --cflags --libs`
endef


