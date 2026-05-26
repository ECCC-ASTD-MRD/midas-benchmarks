message(STATUS "(EC) Generating cclargs Makefile")

add_definitions(-DNOUI)

add_executable(cclargs cclargs_lite.c)

install(TARGETS cclargs RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
