# This file is part of MXE. See LICENSE.md for licensing information.

# Variant on sdl2_mixer.mk

# This script should be used by running win32/build_sdl_mixer.sh from the
# OHRRPGCE source tree, because otherwise a lot of manual steps are required:
# You need to provide SDL2.dll (and libSDL2.la), to prevent mxe from statically
# linking it. See sdl_mixer_ohrrpgce.mk and build_sdl_mixer.sh

# FLAC disabled because we don't use it.
# (Timidity and Fluidsynth are disabled by default.)
# libmad used just because it produces a smaller .dll (~780KB vs ~980KB)
# and because we've been using it for a while.
# But mpg123 is the default, and is actually maintained and faster.
# smpeg is very bad, doesn't work at most bitrates, and is crashy.
# libmodplug (OpenMPT) used instead of mikmod because it's much higher quality; see
# https://www.slimesalad.com/forum/viewtopic.php?t=6810
# (libmodplug was made the default starting in SDL_mixer 2.0 anyway.)
# Also, there are some OpenMPT-specific features like randomised volume, panning, filtering
# which certain users (Foxley) may rely upon.

PKG             := sdl2_mixer_ohrrpgce
$(PKG)_WEBSITE  := https://www.libsdl.org/projects/SDL_mixer/
$(PKG)_DESCR    := SDL2_mixer
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 2.0.5
$(PKG)_HG_REV   := b0afe341a91d
#$(PKG)_HG_REV  := tip
$(PKG)_CHECKSUM := bf6c627e9894a71534cf000d3658d3cc8cad32cb694974763611f25cc14d3efa
$(PKG)_SUBDIR   := SDL_mixer-$($(PKG)_HG_REV)
$(PKG)_FILE     := SDL2_mixer-$($(PKG)_HG_REV).tar.gz
$(PKG)_URL      := https://hg.libsdl.org/SDL_mixer/archive/$($(PKG)_HG_REV).tar.gz
# sdl2 omitted because we copy the sdl libs from i686-w64-mingw32.shared
$(PKG)_DEPS     := cc libmad libmodplug ogg vorbis # mpg123 opusfile

define $(PKG)_UPDATE
    $(WGET) -q -O- 'https://hg.libsdl.org/SDL_mixer/tags' | \
    $(SED) -n 's,.*release-\([0-9][^<]*\).*,\1,p' | \
    head -1
endef

define $(PKG)_BUILD
    #$(SED) -i 's,^\(Requires:.*\),\1 opusfile vorbisfile,' '$(1)/SDL2_mixer.pc.in'
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
        --disable-music-timidity-midi \
        --disable-music-fluidsynth-midi \
        --enable-music-mod \
        --enable-music-mod-modplug \
        --enable-music-ogg \
        --disable-music-ogg-shared \
        --disable-music-flac \
        --disable-music-flac-shared \
        --enable-music-mp3 \
        --disable-music-mp3-mpg123 \
        --disable-music-mp3-mpg123-shared \
        --enable-music-mp3-mad-gpl \
        --enable-music-mp3-mad-gpl-dithering \
        SMPEG_CONFIG='$(PREFIX)/$(TARGET)/bin/smpeg2-config' \
        WINDRES='$(TARGET)-windres' \
	LDFLAGS='-Wl,-export-all-symbols' \
        LIBS="`$(TARGET)-pkg-config libmodplug libmad vorbisfile --libs-only-l`"
        #  libmpg123 opusfile

    $(MAKE) -C '$(1)' -j '$(JOBS)' install $(MXE_DISABLE_CRUFT)

    '$(TARGET)-gcc' \
        -W -Wall -Werror -ansi -pedantic \
        '$(TOP_DIR)/src/sdl_mixer-test.c' -o '$(PREFIX)/$(TARGET)/bin/test-sdl2_mixer.exe' \
        `'$(TARGET)-pkg-config' SDL2_mixer --cflags --libs`
endef


