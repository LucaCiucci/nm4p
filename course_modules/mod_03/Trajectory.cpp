
#include "Trajectory.hpp"

namespace nm4p
{
	Trajectory::Trajectory(size_t nComponents, size_t lenght) :
		m_nComponents(nComponents)
	{
		this->resize(lenght);
	}
}