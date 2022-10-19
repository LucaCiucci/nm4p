

find_package(Qt6 REQUIRED COMPONENTS Core Widgets)
qt_standard_project_setup()


add_executable(ising_demo_01)

target_sources(ising_demo_01 PRIVATE
	"main_demo.cpp"
	"PottsNd.hpp"
	"PottsNd.cpp"
	"opencl_utils.cpp"
	"NeighborsIterator.hpp"
    "Potts2dItem.cpp"
    "Potts2dItem.hpp"
	"steppers.cpp"
	"steppers.hpp"
)

# just a test, not used
if (FALSE)
	enable_language(CUDA)
	include(CheckLanguage)
	check_language(CUDA)
	message(STATUS "CUDA support: ${CMAKE_CUDA_COMPILER}")
	if(NOT DEFINED CMAKE_CUDA_STANDARD)
		set(CMAKE_CUDA_STANDARD 17)
		set(CMAKE_CUDA_STANDARD_REQUIRED ON)
	endif()

	target_sources(ising_demo_01 PRIVATE
		"a.cu"
	)
endif()



find_package(OpenCL) # find_package(OpenCL REQUIRED)
if (OpenCL_FOUND)
	message("OpenCL found, linking ising_demo_01 to OpenCL")
	target_link_libraries(ising_demo_01 PRIVATE OpenCL::OpenCL)
	target_compile_definitions(ising_demo_01 PRIVATE ISING_OPENCL)
endif()

qt_add_resources(ising_demo_01 "opencl_programs"
    PREFIX "/opencl/"
    FILES
        a.ocl
)

set_property(TARGET ising_demo_01 PROPERTY CXX_STANDARD 20)

target_link_libraries(ising_demo_01 PRIVATE nm4pLib)

#find_package(gnuplotpp REQUIRED)
#target_link_libraries(ising_demo_01 PRIVATE gnuplotpp)


set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON) #??
set(CMAKE_AUTORCC ON) #??


target_link_libraries(ising_demo_01 PRIVATE Qt6::Core Qt6::Widgets)



# !!!!!!!!!!!!!!!!!!11
add_executable(tmp)
target_sources(tmp PRIVATE tmp.cpp "opencl_utils.cpp"    "Potts2dItem.cpp" "steppers.cpp")
set_property(TARGET tmp PROPERTY CXX_STANDARD 20)

find_package(ROOT)
message("ROOT_FOUND: ${ROOT_FOUND}")
target_include_directories(tmp PRIVATE ${ROOT_INCLUDE_DIRS})
message(${ROOT_INCLUDE_DIRS})
foreach(lib IN LISTS ROOT_LIBRARIES)
	#message("${lib}")
	target_link_libraries(tmp PRIVATE ${lib})
endforeach()
#find_package(Qt6 REQUIRED COMPONENTS Widgets)
#target_link_libraries(tmp PRIVATE Qt6::Widgets)