# This file is part of MXE. See LICENSE.md for licensing information.

# Variant on sdl_mixer.mk
# (Update to 1.2.13 from hg)

# This script should be used by running win32/build_sdl_mixer.sh from the
# OHRRPGCE source tree, because otherwise a lot of manual steps are required:
# You need to provide SDL.dll (with matching libSDL.la), to prevent mxe from
# statically linking it, but mxe doesn't build it for the static target.
# You can either compile sdl yourself:
#   make MXE_TARGETS=i686-w64-mingw32.shared sdl
# (note the 'shared') which will compile gcc, etc, a second time, (or just edit
# sdl.mk) followed by
#   cp usr/i686-w64-mingw32.shared/lib/libSDL_mixer.* usr/i686-w64-mingw32.static/lib/
#   cp usr/i686-w64-mingw32.shared/bin/SDL_mixer.dll usr/i686-w64-mingw32.static/bin
# or just download the SDL development libraries and then fixup libSDL.la.
# See build_sdl_mixer.sh

# FLAC disabled because we don't use it, and likewise Timidity. (Fluidsynth is already
# disabled by default.)
# libmad used instead of mpg123 because it's smaller. (SDL_mixer 1.2.13 drops smpeg)
# libmodplug used instead of mikmod because it's much higher quality; see
# https://www.slimesalad.com/forum/viewtopic.php?t=6810
# Also, there are some modplug-specific features like randomised volume, panning,
# filtering which certain users (Foxley) may rely upon.

PKG             := sdl_mixer_ohrrpgce
$(PKG)_WEBSITE  := https://www.libsdl.org/projects/SDL_mixer/
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 1.2.13
$(PKG)_HG_REV   := aa1005bea119
#$(PKG)_HG_REV  := SDL-1.2
$(PKG)_CHECKSUM := 8405225775ed08484a3ade107feb2f59557f07b7010bcf4025c8374f1d5a0a09
$(PKG)_SUBDIR   := SDL_mixer-$($(PKG)_HG_REV)
$(PKG)_FILE     := SDL_mixer-$($(PKG)_HG_REV).tar.gz
$(PKG)_URL      := https://hg.libsdl.org/SDL_mixer/archive/$($(PKG)_HG_REV).tar.gz
# sdl omitted because we copy the sdl libs from i686-w64-mingw32.shared
$(PKG)_DEPS     := cc libmodplug ogg libmad vorbis  #libmikmod mpg123

# define $(PKG)_UPDATE
#     $(WGET) -q -O- 'https://hg.libsdl.org/SDL_mixer/tags' | \
#     $(SED) -n 's,.*release-\([0-9][^<]*\).*,\1,p' | \
#     grep '^1\.' | \
#     $(SORT) -V | \
#     tail -1
# endef

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
        --disable-music-timidity-midi \
        --disable-music-fluidsynth-midi \
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
