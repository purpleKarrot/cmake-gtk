# Copyright (C) 2015-2016 Daniel Pfeifer <daniel@pfeifer-mail.de>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

cmake_minimum_required(VERSION 3.6 FATAL_ERROR)
project(CMakeGTK C)

set(CMAKE_MODULE_PATH "${CMakeGTK_SOURCE_DIR}/CMake")
find_package(Vala 0.32 REQUIRED)

find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED
  glib-2.0
  gobject-2.0
  gtk+-3.0
  json-glib-1.0
  )

vala_precompile(VALA_SRCS
  SOURCES
    add_cache_entry.vala
    cache.vala
    cmake.vala
    cmake_setup.vala
    cacheentry.vala
    cachetype.vala
    toolchain_assistant.vala
    main.vala
    property-editor.vala
  PACKAGES
    gtk+-3.0
    json-glib-1.0
  OPTIONS
    --disable-warnings
    --target-glib=2.48
    --gresources=${CMakeGTK_SOURCE_DIR}/cmake.gresource.xml
  )

set(RC_SRCS "${CMakeGTK_BINARY_DIR}/cmake_gresource.c")
add_custom_command(OUTPUT ${RC_SRCS}
  COMMAND
    glib-compile-resources ${CMakeGTK_SOURCE_DIR}/cmake.gresource.xml
    --target=${RC_SRCS}
    --sourcedir=${CMakeGTK_SOURCE_DIR}
    --generate-source
  DEPENDS
    ${CMakeGTK_SOURCE_DIR}/cmake.gresource.xml
    ${CMakeGTK_SOURCE_DIR}/app-menu.ui
    ${CMakeGTK_SOURCE_DIR}/gears-menu.ui
    ${CMakeGTK_SOURCE_DIR}/add_cache_entry.ui
    ${CMakeGTK_SOURCE_DIR}/toolchain_assistant.ui
    ${CMakeGTK_SOURCE_DIR}/cmake_setup.ui
  )

add_executable(cmake-gtk
  ${VALA_SRCS}
  ${RC_SRCS}
  )

target_include_directories(cmake-gtk PRIVATE
  ${GTK_INCLUDE_DIRS}
  )

target_link_libraries(cmake-gtk PRIVATE
  ${GTK_LIBRARIES}
  )

set(AA_FOOBAR "FOO" CACHE STRING "FOO or BAR")
set_property(CACHE AA_FOOBAR PROPERTY STRINGS
  "FOO"
  "BAR"
  "COW"
  "DOH"
  )
