
#pragma once

#include <optional>

#include <nm4pLib/utils/ranges.hpp>
#include <nm4pLib/utils/math.hpp>
#include <nm4pLib/utils/itrange.hpp>

namespace lc::experimental
{
	template <RangeOfValueType<double> Range>
	double mean(const Range& range)
	{
		double sum_v = 0;
		const size_t N = std::ranges::size(range);

		for (const auto& x : range)
			sum_v += x;

		return sum_v / N;
	}

	inline double mean(const std::vector<double>& v) {
		return mean<std::vector<double>>(v);
	}

	template <class It>
	double mean(It first, const It& last) {
		return mean(itrange(first, last));
	}

	// varianza campionaria (diversa che sulla media campionaria)
	template <RangeOfValueType<double> Range>
	double var(const Range& range)
	{
		const auto N = std::ranges::size(range);

		double x2 = 0;
		double mean = 0;
		for (const auto& x : range)
		{
			x2 += sqr(x);
			mean += x;
		}

		x2 /= N;
		mean /= N;

		// TODO semplifica con quello sopra
		return (x2 - sqr(mean)) * (N / (N - 1));
	}

	// NOTE: no correction factor
	template <RangeOfValueType<double> Range>
	double var(const Range& range, const double mean)
	{
		const auto N = std::ranges::size(range);

		double x2 = 0;
		for (const auto& x : range)
		{
			x2 += sqr(x);
			mean += x;
		}

		x2 /= N;
		mean /= N;

		// TODO semplifica con quello sopra
		return (x2 - sqr(mean));
	}

	template <RangeOfValueType<double> Range>
	std::vector<double> autocorrVec(const Range& range, size_t kMax)
	{
		const auto N = std::ranges::size(range);

		// TODO the approximation mu = const for each K is
		// to relax
		const double mu = mean(range);
		const double sigma2 = var(range);

		std::vector<double> c(kMax + 1);

		for (size_t k = 0; k <= kMax; ++k)
		{
			//c[k] = 0;

			// ! ????
			if (k == 1) { c[k] = 1;  continue; }

			for (size_t i = 0; i + k < N; ++i)
				c[k] += (range[i] - mu) * (range[i + k] - mu);

			c[k] /= ((N - k) * sigma2);
		}

		return c;
	}

	/**
	 * @brief compute the autocorrelation vector using the FFT method
	 * 
	 * This function is used to compure the...
	 * TODO ...
	 * 
	 * @param data      input data
	 * @param out_corr  computed output autocorrelation
	 * @param count     number of points
	 * @param mean      the mean value of the data
	 * @param padding   the number of zeros to append to the data
	*/
	void autocorrFFT(const double* data, double* out_corr, size_t count, double mean = 0, size_t padding = 0);

	/**
	 * @brief compute the autocorrelation vector using the FFT method
	 * 
	 * see `autocorrFFT(double* data, double* out_corr, size_t count, double mean, size_t padding)` for details
	 * 
	 * @param data 
	 * @param count 
	 * @param mean 
	 * @param padding 
	 * @return 
	*/
	std::vector<double> autocorrFFT(const double* data, size_t count, double mean = 0, size_t padding = 0);

	/**
	 * @brief compute the autocorrelation vector using the FFT method
	 *
	 * see `autocorrFFT(double* data, double* out_corr, size_t count, double mean, size_t padding)` for details
	 *
	 * @param data
	 * @param count
	 * @param mean
	 * @param padding
	 * @return
	*/
	void autocorrFFT(const std::vector<double>& data, std::vector<double>& out_corr, double mean = 0, size_t padding = 0);

	/**
	 * @brief compute the autocorrelation vector using the FFT method
	 *
	 * see `autocorrFFT(double* data, double* out_corr, size_t count, double mean, size_t padding)` for details
	 *
	 * @param data
	 * @param count
	 * @param mean
	 * @param padding
	 * @return
	*/
	std::vector<double> autocorrFFT(const std::vector<double>& data, double mean = 0, size_t padding = 0);
}