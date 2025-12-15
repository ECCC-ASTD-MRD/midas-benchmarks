cmake_minimum_required(VERSION 3.16)

#----- Append EC specific module path
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake_rpn/modules $ENV{EC_CMAKE_MODULE_PATH})

include(ec_init)           # Include EC specific cmake utils

project(RPNLIBS DESCRIPTION "RPN libs and utilities" LANGUAGES C Fortran)

include(ec_compiler_presets)

add_subdirectory(rmn rmn)
set(rmn_FOUND TRUE CACHE BOOL "Control whether rmn library was found")
add_subdirectory(tdpack tdpack)
set(tdpack_FOUND TRUE CACHE BOOL "Control whether tdpack library was found")
add_subdirectory(vgrid vgrid)
add_subdirectory(rpncomm rpncomm)
add_subdirectory(random random)
add_subdirectory(cclargs cclargs)
add_subdirectory(burp-tools burp-tools)

