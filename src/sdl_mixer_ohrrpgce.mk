# This file is part of MXE. See LICENSE.md for licensing information.

# Variant on sdl_mixer.mk
# Unfortunately not entirely automated:
# First ensure mxe has compiled sdl, eg run the 'make' command given below.
# Check usr/i686-w64-mingw32.static/lib/libSDL.la contains dlname='../bin/SDL.dll'
# and place a copy of SDL.dll in usr/i686-w64-mingw32.static/bin
# Compile with "make MXE_TARGETS=i686-w64-mingw32.static sdl_mixer_ohrrpgce"
# Strip the resulting .dll:
#  cp usr/i686-w64-mingw32.static/bin/SDL_mixer.dll SDL_mixer.dll
#  strip SDL_mixer.dll
# Check that it links dynamically to SDL.dll:
#  objdump -x SDL_mixer.dll | grep SDL.dll

# FLAC disabled because we don't use it.
# libmad used instead of smpeg because it's smaller and doesn't crash with
# unusual sample rates (probably SDL_mixer's bug).
# libmodplug used instead of mikmod because it's much higher quality; see
# https://www.slimesalad.com/forum/viewtopic.php?t=6810

PKG             := sdl_mixer_ohrrpgce
$(PKG)_WEBSITE  := https://www.libsdl.org/projects/SDL_mixer/
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 1.2.12
$(PKG)_CHECKSUM := 1644308279a975799049e4826af2cfc787cad2abb11aa14562e402521f86992a
$(PKG)_SUBDIR   := SDL_mixer-$($(PKG)_VERSION)
$(PKG)_FILE     := SDL_mixer-$($(PKG)_VERSION).tar.gz
$(PKG)_URL      := https://www.libsdl.org/projects/SDL_mixer/release/$($(PKG)_FILE)
$(PKG)_DEPS     := cc libmodplug ogg sdl libmad vorbis  #libmikmod

define $(PKG)_UPDATE
    $(WGET) -q -O- 'https://hg.libsdl.org/SDL_mixer/tags' | \
    $(SED) -n 's,.*release-\([0-9][^<]*\).*,\1,p' | \
    grep '^1\.' | \
    $(SORT) -V | \
    tail -1
endef

define $(PKG)_BUILD
    $(SED) -i 's,^\(Requires:.*\),\1 vorbisfile,' '$(SOURCE_DIR)/SDL_mixer.pc.in'
    echo \
        'Libs.private:' \
        >> '$(SOURCE_DIR)/SDL_mixer.pc.in'
    $(SED) -i 's,for path in /usr/local; do,for path in; do,' '$(SOURCE_DIR)/configure'

    cd '$(BUILD_DIR)' && $(SOURCE_DIR)/configure \
        $(MXE_CONFIGURE_OPTS) \
        --enable-shared \
        --with-sdl-prefix='$(PREFIX)/$(TARGET)' \
        --disable-sdltest \
        --disable-music-mod \
        --enable-music-mod-modplug \
        --enable-music-ogg \
        --disable-music-flac \
        --disable-music-mp3 \
	--enable-music-mp3-mad-gpl \
        $(if $(BUILD_STATIC), \
            --disable-music-mod-shared \
            --disable-music-ogg-shared \
            --disable-music-flac-shared \
            --disable-music-mp3-shared \
            --disable-smpegtest \
            --with-smpeg-prefix='$(PREFIX)/$(TARGET)' \
            , \
            --without-smpeg) \
	PKG_CONFIG='$(TARGET)-pkg-config' \
	LIBMIKMOD_CONFIG='$(PREFIX)/$(TARGET)/bin/libmikmod-config' \
        WINDRES='$(TARGET)-windres' \
        LIBS='-lvorbis -logg' \
	LDFLAGS='-Wl,-export-all-symbols'
    # Without LIBS, configure doesn't find that libogg and libvorbis are available, and skips them.
    # Without LIBMIKMOD_CONFIG the host libmikmod-config gets used, possibly resulting
    # in errors like -lpulse not found.
    # LDFLAGS actually get passed to libtool which passes them to gcc.

    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)' build/libSDL_mixer.la
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install-hdrs install-lib

    '$(TARGET)-gcc' \
        -W -Wall -Werror -ansi -pedantic \
        '$(TEST_FILE)' -o '$(PREFIX)/$(TARGET)/bin/test-sdl_mixer.exe' \
        `'$(TARGET)-pkg-config' SDL_mixer --cflags --libs`
endef
