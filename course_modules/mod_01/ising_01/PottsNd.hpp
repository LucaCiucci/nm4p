
//export module nm4p_a:potts;

#pragma once

#include <vector>
#include <random>
#include <array>
#include <ostream>
#include <string>

#include <stdint.h>

#include <nm4pLib/utils/math.hpp>

namespace nm4p
{
	using std::array;

	template <class T, size_t... Sizes>
	struct SimpleTensor;

	template <class T, size_t S, size_t... Sizes>
	struct SimpleTensor<T, S, Sizes...> : std::array<SimpleTensor<T, Sizes...>, S>
	{
		using std::array<SimpleTensor<T, Sizes...>, S>::array;
	};

	template <class T, size_t S>
	struct SimpleTensor<T, S> : std::array<T, S>
	{
		using std::array<T, S>::array;
	};

	template <size_t _NDim, typename _Ty = std::uint8_t, class _coupling = decltype([](_Ty a, _Ty b) -> double { return a == b ? 1 : 0; }) >
	class PottsNd
	{
	public:

		using Shape = array<size_t, _NDim>;
		using Index = array<size_t, _NDim>;

		static inline constexpr size_t NDim() { return _NDim; };

		static inline auto periodicBoundaryCondition = []() {};

		PottsNd(const _Ty& maxSpin, const Shape& shape);
		PottsNd(const PottsNd& other) = default;
		PottsNd(PottsNd&& other) = default;

		const _Ty& maxSpin() const { return m_maxSpin; }
		const array<size_t, _NDim>& shape() const { return m_shape; }

		size_t spinCount(void) const { return lc::experimental::product(m_shape); }

		void reset(const Shape& shape, const _Ty& value = _Ty(0));

		constexpr size_t elementIdx(const Index& idx) const;

		auto operator[](const Index& idx);
		auto operator[](const Index& idx) const;

		auto at(const Index& idx);
		auto at(const Index& idx) const;

		void randomize(std::default_random_engine& engine);

		void randomize();

	private:

		size_t m_N = 0;
		size_t m_M = 0;

		// we store data in a vector of bool that is PACKED
		std::vector<bool> m_data;

		const _Ty m_maxSpin = 0;
		Shape m_shape;
	};

	// TODO remove?
	enum class Spin : bool {
		Down = 0,
		Up = 1,
	};

	inline constexpr bool to_bool(Spin spin) {
		return spin == Spin::Up;
	}

	inline constexpr Spin to_spin(bool spin) {
		return spin ? Spin::Up : Spin::Down;
	}

	using IsingCoupling = decltype([](Spin a, Spin b) constexpr -> double {
		return to_bool(a) == to_bool(b) ? 1 : -1;
	});

	using IsingCoupling_int = decltype([](bool a, bool b) constexpr -> double {
		return IsingCoupling()(to_spin(a), to_spin(b));
	});

	class Ising2d : public PottsNd<2, bool, IsingCoupling_int>
	{
	public:

		//using BoolReference = std::vector<bool>::reference;

		//struct SpinReference : BoolReference
		//{
		//	using BoolReference::BoolReference;
		//	using BoolReference::operator=;
		//
		//	operator SpinDirection() const {
		//		return ((bool)*this) ? SpinDirection::Up : SpinDirection::Down;
		//	}
		//
		//	SpinReference& operator=(SpinDirection dir) {
		//		*this = (dir == SpinDirection::Up) ? true : false;
		//	}
		//};

		using PottsNd::PottsNd;

		Ising2d(const Shape& shape) :
			PottsNd(1, shape) {
		}

		size_t N() const { return this->shape()[0]; }
		size_t M() const { return this->shape()[1]; }

	private:

	};

	std::ostream& operator<<(std::ostream& os, const Ising2d& ising);
	std::string reset_cursor(const Ising2d& ising);
}

// ================================================================================================================================
// ================================================================================================================================
//                                                              INL
// ================================================================================================================================
// ================================================================================================================================

namespace nm4p
{
	////////////////////////////////////////////////////////////////
	template <size_t _NDim, typename _Ty, class _coupling>
	PottsNd<_NDim, _Ty, _coupling>::PottsNd(const _Ty& maxSpin, const Shape& shape) :
		m_maxSpin(maxSpin),
		m_shape(shape)
	{
		this->reset(shape);
	}

	////////////////////////////////////////////////////////////////
	template <size_t _NDim, typename _Ty, class _coupling>
	void PottsNd<_NDim, _Ty, _coupling>::reset(const Shape& shape, const _Ty& value)
	{
		auto count = this->spinCount();

		m_data.clear();
		m_data.resize(count);
		for (auto&& spin : m_data)
			spin = value;
	}
	////////////////////////////////////////////////////////////////
	template <size_t _NDim, typename _Ty, class _coupling>
	inline constexpr size_t PottsNd<_NDim, _Ty, _coupling>::elementIdx(const Index& idx) const
	{
		size_t e = 0;
		size_t multiplier = 1;

		for (size_t i = 0; i < this->NDim(); ++i)
		{
			size_t ii = this->NDim() - i - 1;
			e += idx[ii] * multiplier;
			multiplier *= this->shape()[ii];
		}

		return e;
	}

	////////////////////////////////////////////////////////////////
	template <size_t _NDim, typename _Ty, class _coupling>
	inline auto PottsNd<_NDim, _Ty, _coupling>::operator[](const Index& idx)
	{
		return m_data.at(this->elementIdx(idx));
	}

	////////////////////////////////////////////////////////////////
	template <size_t _NDim, typename _Ty, class _coupling>
	inline auto PottsNd<_NDim, _Ty, _coupling>::operator[](const Index& idx) const
	{
		return m_data[this->elementIdx(idx)];
	}

	////////////////////////////////////////////////////////////////
	template <size_t _NDim, typename _Ty, class _coupling>
	inline auto PottsNd<_NDim, _Ty, _coupling>::at(const Index& idx)
	{
		return m_data.at(this->elementIdx(idx));
	}

	////////////////////////////////////////////////////////////////
	template <size_t _NDim, typename _Ty, class _coupling>
	inline auto PottsNd<_NDim, _Ty, _coupling>::at(const Index& idx) const
	{
		return m_data.at(this->elementIdx(idx));
	}

	////////////////////////////////////////////////////////////////
	template <size_t _NDim, typename _Ty, class _coupling>
	void PottsNd<_NDim, _Ty, _coupling>::randomize(std::default_random_engine& engine)
	{
		std::uniform_int_distribution<size_t> dist(0, this->maxSpin());

		for (size_t i = 0; i < this->spinCount(); ++i)
			m_data[i] = dist(engine);
	}

	////////////////////////////////////////////////////////////////
	template <size_t _NDim, typename _Ty, class _coupling>
	void PottsNd<_NDim, _Ty, _coupling>::randomize()
	{
		std::default_random_engine engine;
		this->randomize(engine);
	}
}