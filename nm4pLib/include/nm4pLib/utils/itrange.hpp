
#pragma once

#include <ranges>

namespace lc::experimental
{
	// TODO move

	namespace details
	{
		// TODO usa la standard class che non ricordo come si chiama
		template <class Iterator>
		class RangeHelper
		{
		public:

			constexpr RangeHelper(const RangeHelper&) = default;
			constexpr RangeHelper(RangeHelper&&) = default;
			constexpr RangeHelper(Iterator begin, Iterator end) : m_begin(begin), m_end(end) {};

			constexpr auto begin() const { return m_begin; }
			constexpr auto end() const { return m_end; }

			constexpr size_t size() const {
				return std::distance(m_begin, m_end);
			}

		private:
			Iterator m_begin;
			Iterator m_end;
		};
	}

	template <class Iterator>
	auto itrange(Iterator begin, Iterator end)
	{
		return details::RangeHelper(begin, end);
	}
}