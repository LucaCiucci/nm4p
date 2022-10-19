
//export module nm4p_a:NeighborsIterator;

#pragma once

#include <array>

#include <nm4pLib/utils/math.hpp>

#include <assert.h>

namespace nm4p
{
	using std::array;

	template <class Parent, size_t _NDim, class _InternalIndex>
	struct NeighborsIterator {

		using Index = std::array<int, _NDim>;

		struct IdxValuePair {
			Index idx;
			double value = 0;
		};

		// https://www.internalpointers.com/post/writing-custom-iterators-modern-cpp
		using iterator_category = typename std::forward_iterator_tag;
		using difference_type = std::ptrdiff_t;
		using value_type = IdxValuePair;
		using pointer = IdxValuePair*; // TODO see std::vector<bool>::iterator!!!
		using reference = IdxValuePair&; // TODO see std::vector<bool>::iterator!!!

		static constexpr size_t NDim() { return _NDim; }

		constexpr NeighborsIterator(const Parent* parent, _InternalIndex iidx) : parent(parent), iidx(iidx) {}
		constexpr NeighborsIterator(const NeighborsIterator&) = default;
		constexpr NeighborsIterator(NeighborsIterator&&) = default;

		constexpr NeighborsIterator& operator=(const NeighborsIterator&) = default;
		constexpr NeighborsIterator& operator=(NeighborsIterator&&) = default;

		constexpr NeighborsIterator& operator++() {
			parent->increment(*this);
			return *this;
		}

		constexpr IdxValuePair operator*() {
			auto idx = parent->getIndexFromInternal(iidx);
			return { idx, parent->eval(idx) };
		}

		constexpr bool operator==(const NeighborsIterator& other) const { return iidx == other.iidx; }

		const Parent* parent;
		_InternalIndex iidx;

		friend class NeighborsIterator;
		//friend Derived;
	};

	class SimpleIsingField_WRONG
	{
	public:

		using Iterator = NeighborsIterator<SimpleIsingField_WRONG, 2, std::uint8_t>;
		using Index = Iterator::Index;

		// (-1, -1)
		// (-1,  1)
		// ( 1, -1)
		// ( 1,  1)

		constexpr void increment(Iterator& it) const {
			++it.iidx;
		}

		constexpr Index getIndexFromInternal(std::uint8_t iidx) const {
			switch (iidx)
			{
			case 0: return Index({ -1, -1 });
			case 1: return Index({ -1, +1 });
			case 2: return Index({ +1, -1 });
			case 3: return Index({ +1, +1 });
			default: assert(0); return Index({ 0, 0 });
			}
		}

		constexpr double eval(const Index& idx) const {
			using lc::experimental::abs;

			// 0 1 0
			// 1 0 1
			// 0 1 0
			return (abs(idx[0]) == 1 && abs(idx[1]) == 1) ? 1 : 0;
		}

		constexpr Iterator begin() const {
			return Iterator(this, 0);
		}

		constexpr Iterator end() const {
			return Iterator(this, 4);
		}

	private:

	};

	class SimpleIsingField
	{
	public:

		using Iterator = NeighborsIterator<SimpleIsingField, 2, std::uint8_t>;
		using Index = Iterator::Index;

		// (-1, -1)
		// (-1,  1)
		// ( 1, -1)
		// ( 1,  1)

		constexpr void increment(Iterator& it) const {
			++it.iidx;
		}

		constexpr Index getIndexFromInternal(std::uint8_t iidx) const {
			switch (iidx)
			{
			case 0: return Index({ 0, -1 });
			case 1: return Index({ 0, +1 });
			case 2: return Index({ -1, 0 });
			case 3: return Index({ +1, 0 });
			default: assert(0); return Index({ 0, 0 });
			}
		}

		constexpr double eval(const Index& idx) const {
			using lc::experimental::abs;

			// 0 1 0
			// 1 0 1
			// 0 1 0
			return (abs(idx[0]) == 1 != abs(idx[1]) == 1) ? 1 : 0;
		}

		constexpr Iterator begin() const {
			return Iterator(this, 0);
		}

		constexpr Iterator end() const {
			return Iterator(this, 4);
		}

	private:

	};
}