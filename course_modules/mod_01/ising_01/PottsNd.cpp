

#include "PottsNd.hpp"

#include <ostream>

//import nm4p_a;

//import :potts;

#include <nm4pLib/utils/strings.hpp>

namespace nm4p
{
	std::ostream& operator<<(std::ostream& os, const Ising2d& ising)
	{
		for (size_t i = 0; i < ising.N(); ++i)
		{
			for (size_t j = 0; j < ising.M(); ++j)
			{
				os << (ising[{i, j}] ? '+' : ' ') << " ";
			}
			os << "\n";
		}
		return os;
	}

	std::string reset_cursor(const Ising2d& ising)
	{
		std::string result;
		for (size_t i = 0; i < ising.N(); ++i)
			result += cursor_up;
		return result;
	}

	double magnetization(const Ising2d& model)
	{
		double sum = 0;
		for (bool s : model.dataContainer())
			sum += s ? 1 : -1;
		return sum / lc::experimental::product(model.shape());
	}
}