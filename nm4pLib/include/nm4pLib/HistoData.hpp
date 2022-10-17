
#pragma once

#include <vector>

#include <nm4pLib/utils/ranges.hpp>

namespace nm4pLib
{
	struct HistoData
	{
		double minX = 0;
		double maxX = 1;
		std::vector<size_t> bins{ 10 };

		constexpr double delta(void) const { assert(bins.size() > 0);  return (maxX - minX) / bins.size(); }

		void push(double value) {
			if (value < minX || value > maxX) return;
			++bins[to_index(value)];
		}

		template <lc::experimental::RangeOfValueType<double> Range>
		void push(const Range& range) {
			for (const auto& x : range)
				this->push(x);
		}

		size_t to_index(double value) {
			assert(bins.size() > 0);
			return (value - minX) / (maxX - minX) * bins.size();
		}

		template <lc::experimental::RangeOfValueType<double> Range>
		static HistoData from(const Range& range, double minX, double maxX, size_t bins)
		{
			HistoData d;
			d.minX = minX;
			d.maxX = maxX;
			d.bins.resize(bins);
			d.push(range);
			return d;
		}
	};
}