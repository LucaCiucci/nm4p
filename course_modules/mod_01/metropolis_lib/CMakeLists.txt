

add_library(metropolis_lib)


target_sources(metropolis_lib PRIVATE "src/metropolis.cpp")

target_include_directories(metropolis_lib PUBLIC "include")

set_property(TARGET metropolis_lib PROPERTY CXX_STANDARD 20)