
#include <vector>
#include <string>

namespace lc::experimental
{
	template <class Tout, class T>
	std::vector<Tout> map_(const vector<T>& vec, function<Tout(const T& element, size_t i)> transformer)
	{
		std::vector<Tout> result;
		result.reserve(vec.size());

		size_t c = 0;
		for (const auto& e : vec)
			result.push_back(transformer(e, c++));

		return result;
	}

	std::string join(const vector<string>& vec, string j)
	{
		std::string r;
		for (int i = 0; i < vec.size(); ++i)
		{
			r += vec[i];
			if (i + 1 < vec.size())
				r += j;
		}
		return r;
	}
}