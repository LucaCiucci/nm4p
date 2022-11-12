
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

	// periodi index
	inline int periodicIndex(int i, int N) {
		if (i < 0)
			return (N + (i % N)) % N;
		return i % N;
	}
}

namespace nm4p
{
	template <class T = double>
	class AverageAccumulator
	{
	public:

		AverageAccumulator& operator<< (const T& x) {
			m_sum += x;
			++m_count;
			return *this;
		}

		T average() const {
			return m_sum / m_count;
		}

		T value() const { return this->average(); }
		T operator()() const { return this->average(); }

	private:

		T m_sum = 0;
		size_t m_count = 0;
	};
	// deduction guideline (i.e. default is double) https://en.cppreference.com/w/cpp/language/class_template_argument_deduction
	AverageAccumulator()->AverageAccumulator<>;
}