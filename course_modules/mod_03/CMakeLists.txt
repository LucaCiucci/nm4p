

add_executable(metro_1p)

target_sources(
	metro_1p
	PRIVATE
		"main.cpp"
		"Trajectory.hpp"
		"Trajectory.cpp"
		"metropolis.hpp"
		"metropolis.cpp"
		"actions/AbstractMultiParticleAction.hpp"
		"actions/AbstractMultiParticleAction.cpp"
		"actions/HO_1P_Action.hpp"
		"actions/HO_1P_Action.cpp"
		"actions/MultiParticleAction.hpp"
		"actions/MultiParticleAction.cpp"
)
set_property(TARGET metro_1p PROPERTY CXX_STANDARD 20)

find_package(Eigen3 REQUIRED)
target_link_libraries(metro_1p PRIVATE Eigen3::Eigen)

target_link_libraries(metro_1p PRIVATE nm4pLib)

find_package(Qt6 REQUIRED COMPONENTS Core Widgets)
qt_standard_project_setup()
target_link_libraries(metro_1p PRIVATE Qt6::Core Qt6::Widgets)