
#pragma once


#include <ranges>

namespace lc::experimental
{
	template <typename R, class T>
	concept RangeOfValueType = std::ranges::range<R> && std::same_as<std::ranges::range_value_t<R>, T>;
}