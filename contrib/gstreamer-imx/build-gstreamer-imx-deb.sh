#!/usr/bin/env bash
#
# @(#) build-gstreamer-imx-deb.sh
#
# To build gstreamer-imx.deb, run this script while chrooted in rootfs.
#
get-latest-tag ()
{
    local git_repo=$1

    git ls-remote --tags "$git_repo" |
        awk -F/ '{ print  $NF }' |
        egrep -v 'alpha|beta|gamma|delta|\^'  |
        sort -V |
        tail -1
}

fetch-and-extract-archive ()
{
    local git_repo=$1

    local tag=$(get-latest-tag "$git_repo")

    curl -C - -LO "${git_repo}/archive/${tag}.tar.gz"
    tar -zxf "${tag}.tar.gz"
    echo "$tag"
}

prepare-debian-infrastructure ()
{
    local package=$1
    local version=$2

    local debian_archive=${package}-${version}
    local original_archive=${package}_${version}.orig

    mv "${version}.tar.gz" "${original_archive}.tar.gz"
    sed -n '/BEGIN debian patch/,$s/^#//p' $0 | patch -p0 -d "$debian_archive"
    sed -i -e "s;^\(${package} \)(.*);\1(${version}-1);" "${debian_archive}/debian/changelog"
    chmod +x "${debian_archive}/debian/"{repack-waf,rules}
    tar -zcf "${debian_archive}.tar.gz" "$debian_archive"
}

install-build-dependencies ()
{
    apt update

    apt -y install devscripts

    # Assume that build-essential, gcc, etc. are already installed...
    apt -y install autoconf automake libtool pkgconf
    apt -y install gstreamer1.0-x gstreamer1.0-tools
    apt -y install libgstreamer1.0-dev

    # Install videoparserbad for video parsers like h264parse,
    # mpegvideoparse and mpeg4videoparse.
    apt -y install gstreamer1.0-plugins-good gstreamer1.0-plugins-bad
    apt -y install libgstreamer-plugins-base1.0-dev
    apt -y install libgstreamer-plugins-bad1.0-dev
    apt -y install libpango1.0-dev

    # Install ALSA plugin.
    apt -y install gstreamer1.0-alsa
}

if test ."$0" = ."${BASH_SOURCE[0]}"; then
    declare github_url=https://github.com/Freescale
    declare package=gstreamer-imx
    declare package_repo=${github_url}/${package}
    declare version=$(fetch-and-extract-archive "$package_repo")

    prepare-debian-infrastructure "$package" "$version"
    install-build-dependencies
    cd "${package}-${version}"
    dpkg-buildpackage -uc -us
fi

## **** BEGIN debian patch ****
#diff -Nru debian~/README.Debian debian/README.Debian
#--- debian~/README.Debian	1970-01-01 00:00:00.000000000 +0000
#+++ debian/README.Debian	2020-12-22 05:28:15.456585501 +0000
#@@ -0,0 +1,6 @@
#+gstreamer-imx for Debian
#+
#+This is a set of GStreamer 1.0 plugins for NXP's i.MX platform,
#+which make use of the i.MX multimedia capabilities.
#+
#+ -- Andrew L. Moore <andy@revolution-robotics.com>
#diff -Nru debian~/changelog debian/changelog
#--- debian~/changelog	1970-01-01 00:00:00.000000000 +0000
#+++ debian/changelog	2020-12-22 05:28:15.464585313 +0000
#@@ -0,0 +1,5 @@
#+gstreamer-imx (0.13.1-1) UNRELEASED; urgency=low
#+
#+  * Initial release for REVO Roadrunner.
#+
#+ -- Andrew Moore <andy@revolution-robotics.com>  Sat, 19 Dec 2020 04:48:38 +0000
#diff -Nru debian~/compat debian/compat
#--- debian~/compat	1970-01-01 00:00:00.000000000 +0000
#+++ debian/compat	2020-12-22 05:28:15.464585313 +0000
#@@ -0,0 +1 @@
#+11
#diff -Nru debian~/control debian/control
#--- debian~/control	1970-01-01 00:00:00.000000000 +0000
#+++ debian/control	2020-12-22 05:28:15.456585501 +0000
#@@ -0,0 +1,12 @@
#+Source: gstreamer-imx
#+Section: libs
#+Priority: optional
#+Maintainer: Andrew Moore <andy@revolution-robotics.com>
#+Build-Depends: debhelper (>=11~), dh-autoreconf, gstreamer1.0-alsa (>= 1.14.4), gstreamer1.0-plugins-bad (>= 1.14.4), gstreamer1.0-plugins-good (>= 1.14.4), gstreamer1.0-tools (>= 1.14.4), gstreamer1.0-x (>= 1.14.4), libgstreamer-plugins-bad1.0-dev (>= 1.14.4), libgstreamer-plugins-base1.0-dev (>= 1.14.4), libgstreamer1.0-dev (>= 1.14.4), libpango1.0-dev (>= 1.42.4), pkgconf (>= 1.6.0)
#+Standards-Version: 4.1.4
#+Homepage: http://github.com/revolution-robotics/roadrunner-debian
#+
#+Package: gstreamer-imx
#+Architecture: armhf
#+Depends: ${misc:Depends}, ${shlibs:Depends}
#+Description: NXP gstreamer1.0 plugin library
#diff -Nru debian~/copyright debian/copyright
#--- debian~/copyright	1970-01-01 00:00:00.000000000 +0000
#+++ debian/copyright	2020-12-22 05:28:15.456585501 +0000
#@@ -0,0 +1,898 @@
#+Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
#+Upstream-Name: gstreamer-imx-0.13.1
#+Source: <url://example.com>
#+#
#+# Please double check copyright with the licensecheck(1) command.
#+
#+Files:     src/audio/mp3_encoder.c
#+           src/audio/mp3_encoder.h
#+           src/audio/plugin.c
#+           src/audio/uniaudio_codec.c
#+           src/audio/uniaudio_codec.h
#+           src/audio/uniaudio_decoder.c
#+           src/audio/uniaudio_decoder.h
#+           src/blitter/blitter.c
#+           src/blitter/blitter.h
#+           src/blitter/video_sink.c
#+           src/blitter/video_sink.h
#+           src/blitter/video_transform.c
#+           src/blitter/video_transform.h
#+           src/common/phys_mem_allocator.c
#+           src/common/phys_mem_allocator.h
#+           src/common/phys_mem_buffer_pool.c
#+           src/common/phys_mem_buffer_pool.h
#+           src/common/phys_mem_meta.c
#+           src/common/phys_mem_meta.h
#+           src/eglvivsink/eglvivsink.c
#+           src/eglvivsink/eglvivsink.h
#+           src/eglvivsink/plugin.c
#+           src/g2d/allocator.c
#+           src/g2d/allocator.h
#+           src/g2d/blitter.c
#+           src/g2d/blitter.h
#+           src/g2d/compositor.c
#+           src/g2d/compositor.h
#+           src/g2d/plugin.c
#+           src/g2d/video_sink.c
#+           src/g2d/video_sink.h
#+           src/g2d/video_transform.c
#+           src/g2d/video_transform.h
#+           src/ipu/allocator.c
#+           src/ipu/allocator.h
#+           src/ipu/blitter.c
#+           src/ipu/blitter.h
#+           src/ipu/compositor.c
#+           src/ipu/compositor.h
#+           src/ipu/device.c
#+           src/ipu/device.h
#+           src/ipu/plugin.c
#+           src/ipu/video_sink.c
#+           src/ipu/video_sink.h
#+           src/ipu/video_transform.c
#+           src/ipu/video_transform.h
#+           src/pxp/allocator.c
#+           src/pxp/allocator.h
#+           src/pxp/blitter.c
#+           src/pxp/blitter.h
#+           src/pxp/device.c
#+           src/pxp/device.h
#+           src/pxp/plugin.c
#+           src/pxp/video_sink.c
#+           src/pxp/video_sink.h
#+           src/pxp/video_transform.c
#+           src/pxp/video_transform.h
#+           src/v4l2video/plugin.c
#+           src/v4l2video/v4l2_buffer_pool.c
#+           src/v4l2video/v4l2_buffer_pool.h
#+           src/v4l2video/v4l2src.c
#+           src/v4l2video/v4l2src.h
#+           src/vpu/allocator.c
#+           src/vpu/allocator.h
#+           src/vpu/decoder.c
#+           src/vpu/decoder.h
#+           src/vpu/decoder_context.c
#+           src/vpu/decoder_context.h
#+           src/vpu/decoder_framebuffer_pool.c
#+           src/vpu/decoder_framebuffer_pool.h
#+           src/vpu/device.c
#+           src/vpu/device.h
#+           src/vpu/encoder_base.c
#+           src/vpu/encoder_base.h
#+           src/vpu/encoder_h263.c
#+           src/vpu/encoder_h263.h
#+           src/vpu/encoder_h264.c
#+           src/vpu/encoder_h264.h
#+           src/vpu/encoder_mjpeg.c
#+           src/vpu/encoder_mjpeg.h
#+           src/vpu/encoder_mpeg4.c
#+           src/vpu/encoder_mpeg4.h
#+           src/vpu/framebuffer_array.c
#+           src/vpu/framebuffer_array.h
#+           src/vpu/plugin.c
#+           src/vpu/vpu_framebuffer_meta.c
#+           src/vpu/vpu_framebuffer_meta.h
#+Copyright: 2013-2014 Black Moth Technologies
#+           2013-2014 Black Moth Technologies, Philip Craig <phil@blackmoth.com.au>
#+           2013-2015 Carlos Rafael Giani
#+License:   LGPL-2.0+
#+ This library is free software; you can redistribute it and/or
#+ modify it under the terms of the GNU Library General Public
#+ License as published by the Free Software Foundation; either
#+ version 2 of the License, or (at your option) any later version.
#+ .
#+ This library is distributed in the hope that it will be useful,
#+ but WITHOUT ANY WARRANTY; without even the implied warranty of
#+ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#+ Library General Public License for more details.
#+ .
#+ You should have received a copy of the GNU Library General Public
#+ License along with this library; if not, write to the Free
#+ Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#+ .
#+ The FSF address in the above text is the old one.
#+ .
#+ On Debian systems, the complete text of the GNU Library General Public License
#+ Version 2 can be found in `/usr/share/common-licenses/LGPL-2'.
#+
#+Files:     README.md
#+           compositor-example.png
#+           docs/blitter-architecture.md
#+           docs/debian-ubuntu.md
#+           docs/faq.md
#+           docs/zerocopy.md
#+           src/audio/wscript
#+           src/blitter/compositor.c
#+           src/blitter/compositor.h
#+           src/blitter/wscript
#+           src/common/canvas.c
#+           src/common/canvas.h
#+           src/common/fd_object.c
#+           src/common/fd_object.h
#+           src/common/gstimxcommon.pc.in
#+           src/common/phys_mem_addr.h
#+           src/common/region.c
#+           src/common/region.h
#+           src/common/wscript
#+           src/compositor/compositor.c
#+           src/compositor/compositor.h
#+           src/compositor/gst-backport/backport-notes.txt
#+           src/compositor/wscript
#+           src/eglvivsink/egl_misc.c
#+           src/eglvivsink/egl_misc.h
#+           src/eglvivsink/egl_platform.h
#+           src/eglvivsink/egl_platform_fb.c
#+           src/eglvivsink/egl_platform_wayland.c
#+           src/eglvivsink/egl_platform_x11.c
#+           src/eglvivsink/gl_headers.c
#+           src/eglvivsink/gl_headers.h
#+           src/eglvivsink/gles2_renderer.c
#+           src/eglvivsink/gles2_renderer.h
#+           src/eglvivsink/wscript
#+           src/g2d/pango/textrender.h
#+           src/g2d/pango/wscript
#+           src/g2d/wscript
#+           src/ipu/wscript
#+           src/pxp/wscript
#+           src/v4l2video/wscript
#+           src/vpu/wscript
#+           wscript
#+Copyright: __NO_COPYRIGHT_NOR_LICENSE__
#+License:   __NO_COPYRIGHT_NOR_LICENSE__
#+
#+Files:     src/compositor/gst-backport/gstimxbpaggregator.h
#+           src/compositor/gst-backport/gstimxbpvideoaggregator.h
#+           src/compositor/gst-backport/gstimxbpvideoaggregatorpad.h
#+           src/g2d/pango/basetextoverlay.c
#+           src/g2d/pango/basetextoverlay.h
#+           src/g2d/pango/clockoverlay.h
#+           src/g2d/pango/textoverlay.h
#+           src/g2d/pango/timeoverlay.h
#+           src/v4l2video/v4l2sink.c
#+           src/v4l2video/v4l2sink.h
#+Copyright: 2008 Wim Taymans <wim@fluendo.com>
#+           2010-2011 Sebastian Dröge <sebastian.droege@collabora.co.uk>
#+           2014 Mathieu Duponchelle <mathieu.duponchelle@oencreed.com>
#+           2014 Thibault Saunier <tsaunier@gnome.org>
#+           2017 Sebastian Dröge <sebastian@centricular.com>
#+           <1999> Erik Walthinsen <omega@cse.ogi.edu>
#+           <2003> David Schleef <ds@schleef.org>
#+           <2005> Tim-Philipp Müller <tim@centricular.net>
#+           <2006-2008> Tim-Philipp Müller <tim centricular net>
#+           <2006> Julien Moutte <julien@moutte.net>
#+           <2006> Zeeshan Ali <zeeshan.ali@nokia.com>
#+           <2009> Young-Ho Cha <ganadist@gmail.com>
#+License:   LGPL-2.0+
#+ This library is free software; you can redistribute it and/or
#+ modify it under the terms of the GNU Library General Public
#+ License as published by the Free Software Foundation; either
#+ version 2 of the License, or (at your option) any later version.
#+ .
#+ This library is distributed in the hope that it will be useful,
#+ but WITHOUT ANY WARRANTY; without even the implied warranty of
#+ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#+ Library General Public License for more details.
#+ .
#+ You should have received a copy of the GNU Library General Public
#+ License along with this library; if not, write to the
#+ Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
#+ Boston, MA 02110-1301, USA.
#+ .
#+ On Debian systems, the complete text of the GNU Library General Public License
#+ Version 2 can be found in `/usr/share/common-licenses/LGPL-2'.
#+
#+Files:     src/compositor/gst-backport/gstimxbpvideoaggregator.c
#+Copyright: 2004-2008 Wim Taymans <wim@fluendo.com>
#+           2010 Sebastian Dröge <sebastian.droege@collabora.co.uk>
#+License:   LGPL-2.0+
#+ This library is free software; you can redistribute it and/or
#+ modify it under the terms of the GNU Library General Public
#+ License as published by the Free Software Foundation; either
#+ version 2 of the License, or (at your option) any later version.
#+ .
#+ This library is distributed in the hope that it will be useful,
#+ but WITHOUT ANY WARRANTY; without even the implied warranty of
#+ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#+ Library General Public License for more details.
#+ .
#+ You should have received a copy of the GNU Library General Public
#+ License along with this library; if not, write to the
#+ Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
#+ Boston, MA 02110-1301, USA.
#+ .
#+ SECTION:gstvideoaggregator
#+ .
#+ On Debian systems, the complete text of the GNU Library General Public License
#+ Version 2 can be found in `/usr/share/common-licenses/LGPL-2'.
#+
#+Files:     src/compositor/gst-backport/gstimxbpaggregator.c
#+Copyright: 2014 Mathieu Duponchelle <mathieu.duponchelle@opencreed.com>
#+           2014 Thibault Saunier <tsaunier@gnome.org>
#+License:   LGPL-2.0+
#+ gstaggregator.c:
#+ .
#+ This library is free software; you can redistribute it and/or
#+ modify it under the terms of the GNU Library General Public
#+ License as published by the Free Software Foundation; either
#+ version 2 of the License, or (at your option) any later version.
#+ .
#+ This library is distributed in the hope that it will be useful,
#+ but WITHOUT ANY WARRANTY; without even the implied warranty of
#+ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#+ Library General Public License for more details.
#+ .
#+ You should have received a copy of the GNU Library General Public
#+ License along with this library; if not, write to the
#+ Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
#+ Boston, MA 02110-1301, USA.
#+ .
#+ SECTION: gstaggregator
#+ .
#+ On Debian systems, the complete text of the GNU Library General Public License
#+ Version 2 can be found in `/usr/share/common-licenses/LGPL-2'.
#+
#+Files:     src/g2d/pango/clockoverlay.c
#+Copyright: <1999> Erik Walthinsen <omega@cse.ogi.edu>
#+           <2005> Tim-Philipp Müller <tim@centricular.net>
#+License:   LGPL-2.0+
#+ This library is free software; you can redistribute it and/or
#+ modify it under the terms of the GNU Library General Public
#+ License as published by the Free Software Foundation; either
#+ version 2 of the License, or (at your option) any later version.
#+ .
#+ This library is distributed in the hope that it will be useful,
#+ but WITHOUT ANY WARRANTY; without even the implied warranty of
#+ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#+ Library General Public License for more details.
#+ .
#+ You should have received a copy of the GNU Library General Public
#+ License along with this library; if not, write to the
#+ Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
#+ Boston, MA 02110-1301, USA.
#+ .
#+ SECTION:element-clockoverlay
#+ .
#+ On Debian systems, the complete text of the GNU Library General Public License
#+ Version 2 can be found in `/usr/share/common-licenses/LGPL-2'.
#+
#+Files:     src/eglvivsink/egl_platform_android.c
#+Copyright: 2013 Carlos Rafael Giani
#+           2015 PULSE ORIGIN SAS
#+License:   LGPL-2.0+
#+ EGL/Android platform file.
#+ .
#+ This library is free software; you can redistribute it and/or
#+ modify it under the terms of the GNU Library General Public
#+ License as published by the Free Software Foundation; either
#+ version 2 of the License, or (at your option) any later version.
#+ .
#+ This library is distributed in the hope that it will be useful,
#+ but WITHOUT ANY WARRANTY; without even the implied warranty of
#+ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#+ Library General Public License for more details.
#+ .
#+ You should have received a copy of the GNU Library General Public
#+ License along with this library; if not, write to the Free
#+ Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#+ .
#+ The FSF address in the above text is the old one.
#+ .
#+ On Debian systems, the complete text of the GNU Library General Public License
#+ Version 2 can be found in `/usr/share/common-licenses/LGPL-2'.
#+
#+Files:     src/g2d/pango/timeoverlay.c
#+Copyright: 1999 Erik Walthinsen <omega@cse.ogi.edu>
#+           2005-2014 Tim-Philipp Müller <tim@centricular.net>
#+License:   LGPL-2.0+
#+ This library is free software; you can redistribute it and/or
#+ modify it under the terms of the GNU Library General Public
#+ License as published by the Free Software Foundation; either
#+ version 2 of the License, or (at your option) any later version.
#+ .
#+ This library is distributed in the hope that it will be useful,
#+ but WITHOUT ANY WARRANTY; without even the implied warranty of
#+ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#+ Library General Public License for more details.
#+ .
#+ You should have received a copy of the GNU Library General Public
#+ License along with this library; if not, write to the
#+ Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
#+ Boston, MA 02110-1301, USA.
#+ .
#+ SECTION:element-timeoverlay
#+ .
#+ On Debian systems, the complete text of the GNU Library General Public License
#+ Version 2 can be found in `/usr/share/common-licenses/LGPL-2'.
#+
#+Files:     src/g2d/pango/textrender.c
#+Copyright: <1999> Erik Walthinsen <omega@cse.ogi.edu>
#+           <2003> David Schleef <ds@schleef.org>
#+           <2009> Young-Ho Cha <ganadist@gmail.com>
#+License:   LGPL-2.0+
#+ This library is free software; you can redistribute it and/or
#+ modify it under the terms of the GNU Library General Public
#+ License as published by the Free Software Foundation; either
#+ version 2 of the License, or (at your option) any later version.
#+ .
#+ This library is distributed in the hope that it will be useful,
#+ but WITHOUT ANY WARRANTY; without even the implied warranty of
#+ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#+ Library General Public License for more details.
#+ .
#+ You should have received a copy of the GNU Library General Public
#+ License along with this library; if not, write to the
#+ Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
#+ Boston, MA 02110-1301, USA.
#+ .
#+ SECTION:element-textrender
#+ .
#+ On Debian systems, the complete text of the GNU Library General Public License
#+ Version 2 can be found in `/usr/share/common-licenses/LGPL-2'.
#+
#+Files:     src/g2d/pango/textoverlay.c
#+Copyright: <1999> Erik Walthinsen <omega@cse.ogi.edu>
#+           <2003> David Schleef <ds@schleef.org>
#+           <2006-2008> Tim-Philipp Müller <tim centricular net>
#+           <2006> Julien Moutte <julien@moutte.net>
#+           <2006> Zeeshan Ali <zeeshan.ali@nokia.com>
#+           <2009> Young-Ho Cha <ganadist@gmail.com>
#+           <2011> Sebastian Dröge <sebastian.droege@collabora.co.uk>
#+License:   LGPL-2.0+
#+ This library is free software; you can redistribute it and/or
#+ modify it under the terms of the GNU Library General Public
#+ License as published by the Free Software Foundation; either
#+ version 2 of the License, or (at your option) any later version.
#+ .
#+ This library is distributed in the hope that it will be useful,
#+ but WITHOUT ANY WARRANTY; without even the implied warranty of
#+ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#+ Library General Public License for more details.
#+ .
#+ You should have received a copy of the GNU Library General Public
#+ License along with this library; if not, write to the
#+ Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
#+ Boston, MA 02110-1301, USA.
#+ .
#+ SECTION:element-textoverlay
#+ .
#+ On Debian systems, the complete text of the GNU Library General Public License
#+ Version 2 can be found in `/usr/share/common-licenses/LGPL-2'.
#+
#+Files:     waf
#+Copyright: __NO_COPYRIGHT__ in: waf
#+License:   BSD-3-Clause
#+ Redistribution and use in source and binary forms, with or without
#+ modification, are permitted provided that the following conditions
#+ are met:
#+ .
#+ 1. Redistributions of source code must retain the above copyright
#+ notice, this list of conditions and the following disclaimer.
#+ .
#+ 2. Redistributions in binary form must reproduce the above copyright
#+ notice, this list of conditions and the following disclaimer in the
#+ documentation and/or other materials provided with the distribution.
#+ .
#+ 3. The name of the author may not be used to endorse or promote products
#+ derived from this software without specific prior written permission.
#+ .
#+ THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
#+ IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#+ WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#+ DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
#+ INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#+ (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#+ SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
#+ HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
#+ STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
#+ IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#+ POSSIBILITY OF SUCH DAMAGE.
#+ .
#+ On Debian systems, the complete text of the BSD 3-clause "New" or "Revised"
#+ License can be found in `/usr/share/common-licenses/BSD'.
#+
#+#----------------------------------------------------------------------------
#+# Files marked as NO_LICENSE_TEXT_FOUND may be covered by the following
#+# license/copyright files.
#+
#+#----------------------------------------------------------------------------
#+# License file: LICENSE
#+                GNU LIBRARY GENERAL PUBLIC LICENSE
#+                     Version 2, June 1991
#+ .
#+  Copyright (C) 1991 Free Software Foundation, Inc.
#+                     675 Mass Ave, Cambridge, MA 02139, USA
#+  Everyone is permitted to copy and distribute verbatim copies
#+  of this license document, but changing it is not allowed.
#+ .
#+ [This is the first released version of the library GPL.  It is
#+  numbered 2 because it goes with version 2 of the ordinary GPL.]
#+ .
#+                          Preamble
#+ .
#+   The licenses for most software are designed to take away your
#+ freedom to share and change it.  By contrast, the GNU General Public
#+ Licenses are intended to guarantee your freedom to share and change
#+ free software--to make sure the software is free for all its users.
#+ .
#+   This license, the Library General Public License, applies to some
#+ specially designated Free Software Foundation software, and to any
#+ other libraries whose authors decide to use it.  You can use it for
#+ your libraries, too.
#+ .
#+   When we speak of free software, we are referring to freedom, not
#+ price.  Our General Public Licenses are designed to make sure that you
#+ have the freedom to distribute copies of free software (and charge for
#+ this service if you wish), that you receive source code or can get it
#+ if you want it, that you can change the software or use pieces of it
#+ in new free programs; and that you know you can do these things.
#+ .
#+   To protect your rights, we need to make restrictions that forbid
#+ anyone to deny you these rights or to ask you to surrender the rights.
#+ These restrictions translate to certain responsibilities for you if
#+ you distribute copies of the library, or if you modify it.
#+ .
#+   For example, if you distribute copies of the library, whether gratis
#+ or for a fee, you must give the recipients all the rights that we gave
#+ you.  You must make sure that they, too, receive or can get the source
#+ code.  If you link a program with the library, you must provide
#+ complete object files to the recipients so that they can relink them
#+ with the library, after making changes to the library and recompiling
#+ it.  And you must show them these terms so they know their rights.
#+ .
#+   Our method of protecting your rights has two steps: (1) copyright
#+ the library, and (2) offer you this license which gives you legal
#+ permission to copy, distribute and/or modify the library.
#+ .
#+   Also, for each distributor's protection, we want to make certain
#+ that everyone understands that there is no warranty for this free
#+ library.  If the library is modified by someone else and passed on, we
#+ want its recipients to know that what they have is not the original
#+ version, so that any problems introduced by others will not reflect on
#+ the original authors' reputations.
#+ .
#+   Finally, any free program is threatened constantly by software
#+ patents.  We wish to avoid the danger that companies distributing free
#+ software will individually obtain patent licenses, thus in effect
#+ transforming the program into proprietary software.  To prevent this,
#+ we have made it clear that any patent must be licensed for everyone's
#+ free use or not licensed at all.
#+ .
#+   Most GNU software, including some libraries, is covered by the ordinary
#+ GNU General Public License, which was designed for utility programs.  This
#+ license, the GNU Library General Public License, applies to certain
#+ designated libraries.  This license is quite different from the ordinary
#+ one; be sure to read it in full, and don't assume that anything in it is
#+ the same as in the ordinary license.
#+ .
#+   The reason we have a separate public license for some libraries is that
#+ they blur the distinction we usually make between modifying or adding to a
#+ program and simply using it.  Linking a program with a library, without
#+ changing the library, is in some sense simply using the library, and is
#+ analogous to running a utility program or application program.  However, in
#+ a textual and legal sense, the linked executable is a combined work, a
#+ derivative of the original library, and the ordinary General Public License
#+ treats it as such.
#+ .
#+   Because of this blurred distinction, using the ordinary General
#+ Public License for libraries did not effectively promote software
#+ sharing, because most developers did not use the libraries.  We
#+ concluded that weaker conditions might promote sharing better.
#+ .
#+   However, unrestricted linking of non-free programs would deprive the
#+ users of those programs of all benefit from the free status of the
#+ libraries themselves.  This Library General Public License is intended to
#+ permit developers of non-free programs to use free libraries, while
#+ preserving your freedom as a user of such programs to change the free
#+ libraries that are incorporated in them.  (We have not seen how to achieve
#+ this as regards changes in header files, but we have achieved it as regards
#+ changes in the actual functions of the Library.)  The hope is that this
#+ will lead to faster development of free libraries.
#+ .
#+   The precise terms and conditions for copying, distribution and
#+ modification follow.  Pay close attention to the difference between a
#+ "work based on the library" and a "work that uses the library".  The
#+ former contains code derived from the library, while the latter only
#+ works together with the library.
#+ .
#+   Note that it is possible for a library to be covered by the ordinary
#+ General Public License rather than by this special one.
#+ .
#+                GNU LIBRARY GENERAL PUBLIC LICENSE
#+    TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#+ .
#+   0. This License Agreement applies to any software library which
#+ contains a notice placed by the copyright holder or other authorized
#+ party saying it may be distributed under the terms of this Library
#+ General Public License (also called "this License").  Each licensee is
#+ addressed as "you".
#+ .
#+   A "library" means a collection of software functions and/or data
#+ prepared so as to be conveniently linked with application programs
#+ (which use some of those functions and data) to form executables.
#+ .
#+   The "Library", below, refers to any such software library or work
#+ which has been distributed under these terms.  A "work based on the
#+ Library" means either the Library or any derivative work under
#+ copyright law: that is to say, a work containing the Library or a
#+ portion of it, either verbatim or with modifications and/or translated
#+ straightforwardly into another language.  (Hereinafter, translation is
#+ included without limitation in the term "modification".)
#+ .
#+   "Source code" for a work means the preferred form of the work for
#+ making modifications to it.  For a library, complete source code means
#+ all the source code for all modules it contains, plus any associated
#+ interface definition files, plus the scripts used to control compilation
#+ and installation of the library.
#+ .
#+   Activities other than copying, distribution and modification are not
#+ covered by this License; they are outside its scope.  The act of
#+ running a program using the Library is not restricted, and output from
#+ such a program is covered only if its contents constitute a work based
#+ on the Library (independent of the use of the Library in a tool for
#+ writing it).  Whether that is true depends on what the Library does
#+ and what the program that uses the Library does.
#+ .
#+   1. You may copy and distribute verbatim copies of the Library's
#+ complete source code as you receive it, in any medium, provided that
#+ you conspicuously and appropriately publish on each copy an
#+ appropriate copyright notice and disclaimer of warranty; keep intact
#+ all the notices that refer to this License and to the absence of any
#+ warranty; and distribute a copy of this License along with the
#+ Library.
#+ .
#+   You may charge a fee for the physical act of transferring a copy,
#+ and you may at your option offer warranty protection in exchange for a
#+ fee.
#+ .
#+   2. You may modify your copy or copies of the Library or any portion
#+ of it, thus forming a work based on the Library, and copy and
#+ distribute such modifications or work under the terms of Section 1
#+ above, provided that you also meet all of these conditions:
#+ .
#+     a) The modified work must itself be a software library.
#+ .
#+     b) You must cause the files modified to carry prominent notices
#+     stating that you changed the files and the date of any change.
#+ .
#+     c) You must cause the whole of the work to be licensed at no
#+     charge to all third parties under the terms of this License.
#+ .
#+     d) If a facility in the modified Library refers to a function or a
#+     table of data to be supplied by an application program that uses
#+     the facility, other than as an argument passed when the facility
#+     is invoked, then you must make a good faith effort to ensure that,
#+     in the event an application does not supply such function or
#+     table, the facility still operates, and performs whatever part of
#+     its purpose remains meaningful.
#+ .
#+     (For example, a function in a library to compute square roots has
#+     a purpose that is entirely well-defined independent of the
#+     application.  Therefore, Subsection 2d requires that any
#+     application-supplied function or table used by this function must
#+     be optional: if the application does not supply it, the square
#+     root function must still compute square roots.)
#+ .
#+ These requirements apply to the modified work as a whole.  If
#+ identifiable sections of that work are not derived from the Library,
#+ and can be reasonably considered independent and separate works in
#+ themselves, then this License, and its terms, do not apply to those
#+ sections when you distribute them as separate works.  But when you
#+ distribute the same sections as part of a whole which is a work based
#+ on the Library, the distribution of the whole must be on the terms of
#+ this License, whose permissions for other licensees extend to the
#+ entire whole, and thus to each and every part regardless of who wrote
#+ it.
#+ .
#+ Thus, it is not the intent of this section to claim rights or contest
#+ your rights to work written entirely by you; rather, the intent is to
#+ exercise the right to control the distribution of derivative or
#+ collective works based on the Library.
#+ .
#+ In addition, mere aggregation of another work not based on the Library
#+ with the Library (or with a work based on the Library) on a volume of
#+ a storage or distribution medium does not bring the other work under
#+ the scope of this License.
#+ .
#+   3. You may opt to apply the terms of the ordinary GNU General Public
#+ License instead of this License to a given copy of the Library.  To do
#+ this, you must alter all the notices that refer to this License, so
#+ that they refer to the ordinary GNU General Public License, version 2,
#+ instead of to this License.  (If a newer version than version 2 of the
#+ ordinary GNU General Public License has appeared, then you can specify
#+ that version instead if you wish.)  Do not make any other change in
#+ these notices.
#+ .
#+   Once this change is made in a given copy, it is irreversible for
#+ that copy, so the ordinary GNU General Public License applies to all
#+ subsequent copies and derivative works made from that copy.
#+ .
#+   This option is useful when you wish to copy part of the code of
#+ the Library into a program that is not a library.
#+ .
#+   4. You may copy and distribute the Library (or a portion or
#+ derivative of it, under Section 2) in object code or executable form
#+ under the terms of Sections 1 and 2 above provided that you accompany
#+ it with the complete corresponding machine-readable source code, which
#+ must be distributed under the terms of Sections 1 and 2 above on a
#+ medium customarily used for software interchange.
#+ .
#+   If distribution of object code is made by offering access to copy
#+ from a designated place, then offering equivalent access to copy the
#+ source code from the same place satisfies the requirement to
#+ distribute the source code, even though third parties are not
#+ compelled to copy the source along with the object code.
#+ .
#+   5. A program that contains no derivative of any portion of the
#+ Library, but is designed to work with the Library by being compiled or
#+ linked with it, is called a "work that uses the Library".  Such a
#+ work, in isolation, is not a derivative work of the Library, and
#+ therefore falls outside the scope of this License.
#+ .
#+   However, linking a "work that uses the Library" with the Library
#+ creates an executable that is a derivative of the Library (because it
#+ contains portions of the Library), rather than a "work that uses the
#+ library".  The executable is therefore covered by this License.
#+ Section 6 states terms for distribution of such executables.
#+ .
#+   When a "work that uses the Library" uses material from a header file
#+ that is part of the Library, the object code for the work may be a
#+ derivative work of the Library even though the source code is not.
#+ Whether this is true is especially significant if the work can be
#+ linked without the Library, or if the work is itself a library.  The
#+ threshold for this to be true is not precisely defined by law.
#+ .
#+   If such an object file uses only numerical parameters, data
#+ structure layouts and accessors, and small macros and small inline
#+ functions (ten lines or less in length), then the use of the object
#+ file is unrestricted, regardless of whether it is legally a derivative
#+ work.  (Executables containing this object code plus portions of the
#+ Library will still fall under Section 6.)
#+ .
#+   Otherwise, if the work is a derivative of the Library, you may
#+ distribute the object code for the work under the terms of Section 6.
#+ Any executables containing that work also fall under Section 6,
#+ whether or not they are linked directly with the Library itself.
#+ .
#+   6. As an exception to the Sections above, you may also compile or
#+ link a "work that uses the Library" with the Library to produce a
#+ work containing portions of the Library, and distribute that work
#+ under terms of your choice, provided that the terms permit
#+ modification of the work for the customer's own use and reverse
#+ engineering for debugging such modifications.
#+ .
#+   You must give prominent notice with each copy of the work that the
#+ Library is used in it and that the Library and its use are covered by
#+ this License.  You must supply a copy of this License.  If the work
#+ during execution displays copyright notices, you must include the
#+ copyright notice for the Library among them, as well as a reference
#+ directing the user to the copy of this License.  Also, you must do one
#+ of these things:
#+ .
#+     a) Accompany the work with the complete corresponding
#+     machine-readable source code for the Library including whatever
#+     changes were used in the work (which must be distributed under
#+     Sections 1 and 2 above); and, if the work is an executable linked
#+     with the Library, with the complete machine-readable "work that
#+     uses the Library", as object code and/or source code, so that the
#+     user can modify the Library and then relink to produce a modified
#+     executable containing the modified Library.  (It is understood
#+     that the user who changes the contents of definitions files in the
#+     Library will not necessarily be able to recompile the application
#+     to use the modified definitions.)
#+ .
#+     b) Accompany the work with a written offer, valid for at
#+     least three years, to give the same user the materials
#+     specified in Subsection 6a, above, for a charge no more
#+     than the cost of performing this distribution.
#+ .
#+     c) If distribution of the work is made by offering access to copy
#+     from a designated place, offer equivalent access to copy the above
#+     specified materials from the same place.
#+ .
#+     d) Verify that the user has already received a copy of these
#+     materials or that you have already sent this user a copy.
#+ .
#+   For an executable, the required form of the "work that uses the
#+ Library" must include any data and utility programs needed for
#+ reproducing the executable from it.  However, as a special exception,
#+ the source code distributed need not include anything that is normally
#+ distributed (in either source or binary form) with the major
#+ components (compiler, kernel, and so on) of the operating system on
#+ which the executable runs, unless that component itself accompanies
#+ the executable.
#+ .
#+   It may happen that this requirement contradicts the license
#+ restrictions of other proprietary libraries that do not normally
#+ accompany the operating system.  Such a contradiction means you cannot
#+ use both them and the Library together in an executable that you
#+ distribute.
#+ .
#+   7. You may place library facilities that are a work based on the
#+ Library side-by-side in a single library together with other library
#+ facilities not covered by this License, and distribute such a combined
#+ library, provided that the separate distribution of the work based on
#+ the Library and of the other library facilities is otherwise
#+ permitted, and provided that you do these two things:
#+ .
#+     a) Accompany the combined library with a copy of the same work
#+     based on the Library, uncombined with any other library
#+     facilities.  This must be distributed under the terms of the
#+     Sections above.
#+ .
#+     b) Give prominent notice with the combined library of the fact
#+     that part of it is a work based on the Library, and explaining
#+     where to find the accompanying uncombined form of the same work.
#+ .
#+   8. You may not copy, modify, sublicense, link with, or distribute
#+ the Library except as expressly provided under this License.  Any
#+ attempt otherwise to copy, modify, sublicense, link with, or
#+ distribute the Library is void, and will automatically terminate your
#+ rights under this License.  However, parties who have received copies,
#+ or rights, from you under this License will not have their licenses
#+ terminated so long as such parties remain in full compliance.
#+ .
#+   9. You are not required to accept this License, since you have not
#+ signed it.  However, nothing else grants you permission to modify or
#+ distribute the Library or its derivative works.  These actions are
#+ prohibited by law if you do not accept this License.  Therefore, by
#+ modifying or distributing the Library (or any work based on the
#+ Library), you indicate your acceptance of this License to do so, and
#+ all its terms and conditions for copying, distributing or modifying
#+ the Library or works based on it.
#+ .
#+   10. Each time you redistribute the Library (or any work based on the
#+ Library), the recipient automatically receives a license from the
#+ original licensor to copy, distribute, link with or modify the Library
#+ subject to these terms and conditions.  You may not impose any further
#+ restrictions on the recipients' exercise of the rights granted herein.
#+ You are not responsible for enforcing compliance by third parties to
#+ this License.
#+ .
#+   11. If, as a consequence of a court judgment or allegation of patent
#+ infringement or for any other reason (not limited to patent issues),
#+ conditions are imposed on you (whether by court order, agreement or
#+ otherwise) that contradict the conditions of this License, they do not
#+ excuse you from the conditions of this License.  If you cannot
#+ distribute so as to satisfy simultaneously your obligations under this
#+ License and any other pertinent obligations, then as a consequence you
#+ may not distribute the Library at all.  For example, if a patent
#+ license would not permit royalty-free redistribution of the Library by
#+ all those who receive copies directly or indirectly through you, then
#+ the only way you could satisfy both it and this License would be to
#+ refrain entirely from distribution of the Library.
#+ .
#+ If any portion of this section is held invalid or unenforceable under any
#+ particular circumstance, the balance of the section is intended to apply,
#+ and the section as a whole is intended to apply in other circumstances.
#+ .
#+ It is not the purpose of this section to induce you to infringe any
#+ patents or other property right claims or to contest validity of any
#+ such claims; this section has the sole purpose of protecting the
#+ integrity of the free software distribution system which is
#+ implemented by public license practices.  Many people have made
#+ generous contributions to the wide range of software distributed
#+ through that system in reliance on consistent application of that
#+ system; it is up to the author/donor to decide if he or she is willing
#+ to distribute software through any other system and a licensee cannot
#+ impose that choice.
#+ .
#+ This section is intended to make thoroughly clear what is believed to
#+ be a consequence of the rest of this License.
#+ .
#+   12. If the distribution and/or use of the Library is restricted in
#+ certain countries either by patents or by copyrighted interfaces, the
#+ original copyright holder who places the Library under this License may add
#+ an explicit geographical distribution limitation excluding those countries,
#+ so that distribution is permitted only in or among countries not thus
#+ excluded.  In such case, this License incorporates the limitation as if
#+ written in the body of this License.
#+ .
#+   13. The Free Software Foundation may publish revised and/or new
#+ versions of the Library General Public License from time to time.
#+ Such new versions will be similar in spirit to the present version,
#+ but may differ in detail to address new problems or concerns.
#+ .
#+ Each version is given a distinguishing version number.  If the Library
#+ specifies a version number of this License which applies to it and
#+ "any later version", you have the option of following the terms and
#+ conditions either of that version or of any later version published by
#+ the Free Software Foundation.  If the Library does not specify a
#+ license version number, you may choose any version ever published by
#+ the Free Software Foundation.
#+ .
#+   14. If you wish to incorporate parts of the Library into other free
#+ programs whose distribution conditions are incompatible with these,
#+ write to the author to ask for permission.  For software which is
#+ copyrighted by the Free Software Foundation, write to the Free
#+ Software Foundation; we sometimes make exceptions for this.  Our
#+ decision will be guided by the two goals of preserving the free status
#+ of all derivatives of our free software and of promoting the sharing
#+ and reuse of software generally.
#+ .
#+                          NO WARRANTY
#+ .
#+   15. BECAUSE THE LIBRARY IS LICENSED FREE OF CHARGE, THERE IS NO
#+ WARRANTY FOR THE LIBRARY, TO THE EXTENT PERMITTED BY APPLICABLE LAW.
#+ EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR
#+ OTHER PARTIES PROVIDE THE LIBRARY "AS IS" WITHOUT WARRANTY OF ANY
#+ KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
#+ IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#+ PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
#+ LIBRARY IS WITH YOU.  SHOULD THE LIBRARY PROVE DEFECTIVE, YOU ASSUME
#+ THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.
#+ .
#+   16. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN
#+ WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY
#+ AND/OR REDISTRIBUTE THE LIBRARY AS PERMITTED ABOVE, BE LIABLE TO YOU
#+ FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR
#+ CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
#+ LIBRARY (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
#+ RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
#+ FAILURE OF THE LIBRARY TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
#+ SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
#+ DAMAGES.
#+ .
#+                   END OF TERMS AND CONDITIONS
#+ .
#+      Appendix: How to Apply These Terms to Your New Libraries
#+ .
#+   If you develop a new library, and you want it to be of the greatest
#+ possible use to the public, we recommend making it free software that
#+ everyone can redistribute and change.  You can do so by permitting
#+ redistribution under these terms (or, alternatively, under the terms of the
#+ ordinary General Public License).
#+ .
#+   To apply these terms, attach the following notices to the library.  It is
#+ safest to attach them to the start of each source file to most effectively
#+ convey the exclusion of warranty; and each file should have at least the
#+ "copyright" line and a pointer to where the full notice is found.
#+ .
#+     <one line to give the library's name and a brief idea of what it does.>
#+     Copyright (C) <year>  <name of author>
#+ .
#+     This library is free software; you can redistribute it and/or
#+     modify it under the terms of the GNU Library General Public
#+     License as published by the Free Software Foundation; either
#+     version 2 of the License, or (at your option) any later version.
#+ .
#+     This library is distributed in the hope that it will be useful,
#+     but WITHOUT ANY WARRANTY; without even the implied warranty of
#+     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#+     Library General Public License for more details.
#+ .
#+     You should have received a copy of the GNU Library General Public
#+     License along with this library; if not, write to the Free
#+     Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#+ .
#+ Also add information on how to contact you by electronic and paper mail.
#+ .
#+ You should also get your employer (if you work as a programmer) or your
#+ school, if any, to sign a "copyright disclaimer" for the library, if
#+ necessary.  Here is a sample; alter the names:
#+ .
#+   Yoyodyne, Inc., hereby disclaims all copyright interest in the
#+   library `Frob' (a library for tweaking knobs) written by James Random Hacker.
#+ .
#+   <signature of Ty Coon>, 1 April 1990
#+   Ty Coon, President of Vice
#+ .
#+ That's all there is to it!
#diff -Nru debian~/patches/series debian/patches/series
#--- debian~/patches/series	1970-01-01 00:00:00.000000000 +0000
#+++ debian/patches/series	2020-12-22 05:28:15.456585501 +0000
#@@ -0,0 +1 @@
#+# You must remove unused comment lines for the released package.
#diff -Nru debian~/repack-waf debian/repack-waf
#--- debian~/repack-waf	1970-01-01 00:00:00.000000000 +0000
#+++ debian/repack-waf	2020-12-22 05:28:15.456585501 +0000
#@@ -0,0 +1,88 @@
#+#!/usr/bin/env bash
#+#
#+# Repack an upstream tarball, unpacking waf files inside it.
#+
#+# Meant to be run by uscan(1) as the "command param", after repacking
#+# (if any) by mk-origtargz. So you shouldn't give "repacksuffix" to
#+# debian/watch; instead you should set it below; however this should
#+# still match the dversionmangle in that file.
#+
#+repacksuffix="+dfsg1"
#+unwaf_paths=.
#+
#+# You shouldn't need to change anything below here.
#+
#+USAGE="Usage: $0 --upstream-version version filename"
#+
#+test "$1" = "--upstream-version" || { echo >&2 "$USAGE"; exit 2; }
#+upstream="$2"
#+filename="$3"
#+
#+source="$(dpkg-parsechangelog -SSource)"
#+newups="${upstream}${repacksuffix}"
#+basedir="$(dirname "$filename")"
#+
#+unpack_waf() {
#+    local olddir="$PWD"
#+
#+    cd "$1"
#+    test -x ./waf || return 1
#+    ./waf --help > /dev/null
#+    mv .waf*/* .
#+    sed -i '/^#==>$/,$d' waf
#+    rmdir .waf*
#+    find waf* -name "*.pyc" -delete
#+    cd "$olddir"
#+}
#+
#+set -e
#+
#+tar -xzf "$basedir/${source}_${upstream}.orig.tar.gz"
#+cd "${source}-${upstream}"
#+for i in $unwaf_paths; do unpack_waf "$i"; done
#+cd ..
#+mv "${source}-${upstream}" "${source}-${newups}"
#+GZIP="-9fn" tar -czf "$basedir/${source}_${newups}.orig.tar.gz" "${source}-${newups}"
#+rm -rf "${source}-${newups}"
#+
#+# Meant to be run by uscan(1) as the "command param", after repacking
#+# (if any) by mk-origtargz. So you shouldn't give "repacksuffix" to
#+# debian/watch; instead you should set it below; however this should
#+# still match the dversionmangle in that file.
#+
#+repacksuffix="+dfsg1"
#+unwaf_paths=.
#+
#+# You shouldn't need to change anything below here.
#+
#+USAGE="Usage: $0 --upstream-version version filename"
#+
#+test "$1" = "--upstream-version" || { echo >&2 "$USAGE"; exit 2; }
#+upstream="$2"
#+filename="$3"
#+
#+source="$(dpkg-parsechangelog -SSource)"
#+newups="${upstream}${repacksuffix}"
#+basedir="$(dirname "$filename")"
#+
#+unpack_waf() {
#+    local olddir="$PWD"
#+    cd "$1"
#+    test -x ./waf || return 1
#+    ./waf --help > /dev/null
#+    mv .waf*/* .
#+    sed -i '/^#==>$/,$d' waf
#+    rmdir .waf*
#+    find waf* -name "*.pyc" -delete
#+    cd "$olddir"
#+}
#+
#+set -e
#+
#+tar -xzf "$basedir/${source}_${upstream}.orig.tar.gz"
#+cd "${source}-${upstream}"
#+for i in $unwaf_paths; do unpack_waf "$i"; done
#+cd ..
#+mv "${source}-${upstream}" "${source}-${newups}"
#+GZIP="-9fn" tar -czf "$basedir/${source}_${newups}.orig.tar.gz" "${source}-${newups}"
#+rm -rf "${source}-${newups}"
#diff -Nru debian~/rules debian/rules
#--- debian~/rules	1970-01-01 00:00:00.000000000 +0000
#+++ debian/rules	2020-12-22 05:28:15.456585501 +0000
#@@ -0,0 +1,29 @@
#+#!/usr/bin/make -f
#+export DH_VERBOSE = 1
#+
#+%:
#+	dh $@
#+
#+override_dh_auto_configure:
#+	./waf configure --prefix=/usr --kernel-headers=/usr/include
#+
#+override_dh_auto_build:
#+	./waf
#+
#+override_dh_install:
#+	./waf --destdir=$$(pwd)/debian/gstreamer-imx install
#+
#+upstream_version ?= $(shell dpkg-parsechangelog  --show-field=Version | sed -rne 's/^([0-9.]+)(\+dfsg\d+)?.*$$/\1/p')
#+dfsg_version = $(upstream_version)+dfsg1
#+pkg = $(shell dpkg-parsechangelog --show-field=Source)
#+
#+get-orig-source:
#+	uscan --noconf --force-download --rename --repack --download-current-version --destdir=.
#+	tar -xzf $(pkg)_$(upstream_version).orig.tar.gz
#+	mv $(pkg)-$(upstream_version) $(pkg)-$(dfsg_version)
#+	cd $(pkg)-$(dfsg_version) ; python waf --help > /dev/null
#+	mv $(pkg)-$(dfsg_version)/.waf*/* $(pkg)-$(dfsg_version)
#+	sed -i '/^#==>$$/,$$d' $(pkg)-$(dfsg_version)/waf
#+	rmdir $(pkg)-$(dfsg_version)/.waf*
#+	GZIP="-9fn" tar -czf $(pkg)_$(dfsg_version).orig.tar.gz $(pkg)-$(dfsg_version)
#+	rm -rf $(pkg)-$(dfsg_version)
#diff -Nru debian~/source/format debian/source/format
#--- debian~/source/format	1970-01-01 00:00:00.000000000 +0000
#+++ debian/source/format	2020-12-22 05:28:15.456585501 +0000
#@@ -0,0 +1 @@
#+3.0 (quilt)
#diff -Nru debian~/watch debian/watch
#--- debian~/watch	1970-01-01 00:00:00.000000000 +0000
#+++ debian/watch	2020-12-22 05:28:15.456585501 +0000
#@@ -0,0 +1,3 @@
#+version=3
#+opts="dversionmangle=s/\+dfsg\d+$//" \
#+  debian debian/repack-waf
