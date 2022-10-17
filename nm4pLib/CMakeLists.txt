
add_library("nm4pLib")

target_sources("nm4pLib" PRIVATE "./src/tmp.cpp" "src/stat.cpp")
target_include_directories("nm4pLib" PUBLIC "./include/")

set_target_properties(nm4pLib PROPERTIES CXX_STANDARD 20)

file(DOWNLOAD "https://raw.githubusercontent.com/hayguen/pocketfft/cpp/pocketfft_hdronly.h" ${CMAKE_CURRENT_SOURCE_DIR}/include/nm4pLib/ext/pocketfft_hdronly.h)