


find_package(Eigen3 REQUIRED)

add_executable(aaa tmp.cpp)

target_link_libraries(aaa PRIVATE Eigen3::Eigen)