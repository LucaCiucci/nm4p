
#include <nm4pLib/ext/pocketfft_hdronly.h>

#include <nm4pLib/utils/stat.hpp>

#include <nm4pLib/utils/itrange.hpp>

//#include <nm4pLib/utils/math.hpp>

namespace lc::experimental
{
	////////////////////////////////////////////////////////////////
	void autocorrFFT(const double* data, double* out_corr, size_t count, double mean, size_t padding)
	{
		using namespace pocketfft;

		shape_t shape = { count + padding };
		stride_t strideDouble = { sizeof(double) };
		stride_t strideComplexDouble = { sizeof(std::complex<double>) };

		// if a mean is not zeor or a padding is set, we have to create another array
		std::vector<double> data_vector;
		if (mean != 0 || padding != 0)
		{
			data_vector.resize(count + padding);
			for (size_t i = 0; i < count; ++i)
				data_vector[i] = data[i] - mean;
			data = data_vector.data();
		}

		std::vector<double> out_data_vector;
		double* tmp_out_corr = out_corr;
		if (padding != 0)
		{
			out_data_vector.resize(count + padding);
			tmp_out_corr = out_data_vector.data();
		}

		std::vector<std::complex<double>> ft(count + padding);

		// Note about normalization:
		// The FFT should be normalized by a factor 1/sqrt(N), where N = count + padding, the number of FFT input data.
		// Since FFT is linear, we could just use a factor 1/N on the first FFT and 1 on the FFt^-1.
		// This is unnecessary in our algorithm since we will normalize the correlation after this prrocess so that
		// c[0] = 1 and this is the same as doing the following at the same time:
		//  - putting the normalization factor into the FFT
		//  - dividing by the data variance

		// FT
		pocketfft::r2c<double>(shape, strideDouble, strideComplexDouble, pocketfft::shape_t{ 0 }, pocketfft::FORWARD, data, ft.data(), 1.0);

		// ft <- (ft*)(ft) = |ft|^2
		for (auto& c : ft)
			c = std::conj(c) * c;

		// FT^-1
		pocketfft::c2r<double>(shape, strideComplexDouble, strideDouble, pocketfft::shape_t{ 0 }, pocketfft::BACKWARD, ft.data(), tmp_out_corr, 1.0);

		// counting factor
		for (size_t k = 0; k < count; ++k)
			tmp_out_corr[k] /= (count - k);

		// normalization
		// note that we could 
		auto tmp_out_corr_0 = tmp_out_corr[0];
		for (size_t k = 0; k < count; ++k)
			tmp_out_corr[k] /= tmp_out_corr_0;

		if (tmp_out_corr != out_corr)
			std::copy(tmp_out_corr, tmp_out_corr + count, out_corr);
	}

	////////////////////////////////////////////////////////////////
	std::vector<double> autocorrFFT(const double* data, size_t count, double mean, size_t padding)
	{
		std::vector<double> result(count);
		autocorrFFT(data, result.data(), count, mean, padding);
		return result;
	}

	////////////////////////////////////////////////////////////////
	void autocorrFFT(const std::vector<double>& data, std::vector<double>& out_corr, double mean, size_t padding)
	{
		autocorrFFT(data.data(), out_corr.data(), data.size(), mean, padding);
	}

	////////////////////////////////////////////////////////////////
	std::vector<double> autocorrFFT(const std::vector<double>& data, double mean, size_t padding)
	{
		return autocorrFFT(data.data(), data.size(), mean, padding);
	}
}