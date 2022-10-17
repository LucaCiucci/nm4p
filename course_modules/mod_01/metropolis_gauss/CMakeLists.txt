


add_executable(metropolis_gauss)

target_sources(metropolis_gauss PRIVATE main.cpp)

set_property(TARGET metropolis_gauss PROPERTY CXX_STANDARD 20)

#find_package(LC REQUIRED)
#target_link_libraries(00_test_integratore_custom PRIVATE LC)

#find_package(gnuplotpp REQUIRED)
#target_link_libraries(metropolis_gauss PRIVATE gnuplotpp)

target_link_libraries(metropolis_gauss PRIVATE metropolis_lib)

find_package(ROOT COMPONENTS Core Graf Hist Gui)
target_link_libraries(metropolis_gauss PUBLIC ROOT::Core ROOT::Graf ROOT::Hist ROOT::Gui)


target_link_libraries(metropolis_gauss PRIVATE nm4pLib)