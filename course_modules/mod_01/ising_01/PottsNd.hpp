
//export module nm4p_a:potts;

#pragma once

#include <vector>
#include <random>
#include <array>
#include <ostream>
#include <string>
//#include <bitset>
#include <cassert>

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

	template <class T>
	struct PackedVector : std::vector<T>
	{
		using std::vector<T>::vector;

		T* rawData() { return this->data(); }
		const T* rawData() const { return this->data(); }
	};

	// TODO su libreria
	template <class T>
	struct BitReference
	{
		constexpr BitReference(BitReference&&) = default;
		constexpr BitReference(const BitReference&) = default;

		constexpr BitReference(T* data, int idx) : m_data(data), m_idx(idx) {
			//assert(idx > 0);
			//assert(idx < sizeof(T));
		};

		constexpr operator bool() const {
			auto p8 = (const uint8_t*)(const void*)m_data;
			p8 += m_idx / 8;
			return (*p8) & (1 << (m_idx % 8));
		}

		constexpr BitReference& operator=(bool value) /*requires (!std::is_const<T>)*/ {
			auto p8 = (uint8_t*)(void*)m_data;
			p8 += m_idx / 8;
			if (value)
				*p8 |= 1 << (m_idx % 8);
			else
				*p8 &= ~(1 << (m_idx % 8));
			return *this;
		}

	private:
		T* const m_data = nullptr;
		const int m_idx = 0;
	};

	template <class T>
	struct BitReferenceIt
	{
		using iterator_category = typename std::forward_iterator_tag;
		using difference_type = std::ptrdiff_t;
		using value_type = BitReference<T>;
		using pointer = BitReference<T>*; // TODO see std::vector<bool>::iterator!!!
		using reference = BitReference<T>&; // TODO see std::vector<bool>::iterator!!!

		constexpr BitReferenceIt(BitReferenceIt&&) = default;
		constexpr BitReferenceIt(const BitReferenceIt&) = default;

		constexpr BitReferenceIt(T* data, int idx) : m_data(data), m_idx(idx) {};

		constexpr BitReferenceIt& operator=(BitReferenceIt&&) = default;
		constexpr BitReferenceIt& operator=(const BitReferenceIt&) = default;

		constexpr BitReferenceIt& operator++() {
			++m_idx;
			return *this;
		}

		constexpr bool operator==(const BitReferenceIt& other) const { return m_data == other.m_data && m_idx == other.m_idx; }

		constexpr value_type operator*() {
			return BitReference<T>(m_data, m_idx);
		}

	private:
		T* const m_data = nullptr;
		int m_idx = 0;
	};

	// we do not use bitsets because its size is platform dependant
	template <>
	struct PackedVector<bool> : private std::vector<uint8_t>
	{
		using reference = BitReference<uint8_t>;
		using const_reference = BitReference<const uint8_t>;

		reference operator[](size_t index) {
			return reference(this->data() + index / 8, index % 8);
		}
		const_reference operator[](size_t index) const {
			return const_reference(this->data() + index / 8, index % 8);
		}

		reference at(size_t index) {
			// TODO checks
			return (*this)[index];
		}
		const_reference at(size_t index) const {
			// TODO checks
			return (*this)[index];
		}

		void clear() {
			_base::clear();
			m_size = 0;
		}

		void resize(size_t size) {
			_base::resize((size + 7) / 8);
			m_size = size;
		}

		size_t size() const {
			return m_size;
		}

		BitReferenceIt<uint8_t> begin() {
			return BitReferenceIt<uint8_t>(this->data(), 0);
		}

		BitReferenceIt<const uint8_t> begin() const {
			return BitReferenceIt<const uint8_t>(this->data(), 0);
		}

		BitReferenceIt<uint8_t> end() {
			return BitReferenceIt<uint8_t>(this->data(), this->size());
		}

		BitReferenceIt<const uint8_t> end() const {
			return BitReferenceIt<const uint8_t>(this->data(), this->size());
		}

		uint8_t* rawData() { return (uint8_t*)this->data(); }
		const uint8_t* rawData() const { return (uint8_t*)this->data(); }

	private:
		using _base = std::vector<uint8_t>;
		size_t m_size = 0;
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
		const Shape& shape() const { return m_shape; }

		size_t spinCount(void) const { return lc::experimental::product(m_shape); }

		void reset(const Shape& shape, const _Ty& value = _Ty(0));

		constexpr size_t elementIdx(const Index& idx) const;

		auto operator[](const Index& idx);
		auto operator[](const Index& idx) const;

		auto at(const Index& idx);
		auto at(const Index& idx) const;

		auto& dataContainer() {
			return m_data;
		}

		const auto& dataContainer() const {
			return m_data;
		}

		void randomize(std::default_random_engine& engine);

		void randomize();

		auto rawData() {
			return m_data.rawData();
		}
		auto rawData() const {
			return m_data.rawData();
		}

		static constexpr double coupling(const _Ty& first, const _Ty& second) { return _coupling()(first, second); }
		double coupling(const Index& first, const Index& second) { return this->coupling((*this)[first], (*this)[second]); }

	private:

		size_t m_N = 0;
		size_t m_M = 0;

		// we store data in a vector of bool that is PACKED
		PackedVector<_Ty> m_data;

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

	// computes the average of the spins in the lattice
	double magnetization(const Ising2d& model);
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