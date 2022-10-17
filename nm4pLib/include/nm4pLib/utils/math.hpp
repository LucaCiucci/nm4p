
#pragma once

#include <ranges>
#include <concepts>

namespace lc::experimental
{
	template <class T>
	inline constexpr auto sqr(const T& x) { return x * x; }

	template <std::ranges::range Range>
	inline constexpr auto product(const Range& range)
	{
		using T = std::ranges::range_value_t<Range>;

		using R = decltype(T() * T());

		R result = R(1);

		for (auto&& v : range)
			result *= v;

		return result;
	}

	template <std::integral T>
	inline constexpr T abs(const T& x) {
		return x >= 0 ? x : -x;
	}
}