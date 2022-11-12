
#pragma once

#include <vector>
#include <span>

namespace nm4p
{
	using std::vector;
	using std::span;

	class Trajectory final
	{
	public:

		//using Point = Eigen::VectorXd;
		using Point = vector<double>;
		using PointRef = span<double>;
		using CPointRef = span<const double>;

		Trajectory(size_t nComponents, size_t lenght = 0);

		size_t nComponents() const { return m_nComponents; }

		void resize(size_t size) {
			m_data.resize(size * this->nComponents());
			Point p;
		}

		void push_back(const CPointRef& p) {
			for (size_t i = 0; i < this->nComponents(); ++i)
				if (i < p.size())
					m_data.push_back(p[i]);
				else
					m_data.push_back(0);
		}

		PointRef operator[](size_t i) {
			return PointRef(m_data.data() + i * this->nComponents(), this->nComponents());
		}

		CPointRef operator[](size_t i) const {
			return CPointRef(m_data.data() + i * this->nComponents(), this->nComponents());
		}

		size_t lenght(void) const {
			return m_data.size() / this->nComponents();
		}

	private:

		vector<double> m_data;
		const size_t m_nComponents = 0;
	};

	class TrajectoryAction
	{
	public:

		// evaluates the action on a trajectory
		virtual double eval(const Trajectory& t) const = 0;

		// evaluates the action difference between the trajectory with the modified point and the original trajectory
		// by default, a copy of the trajectory is done and a value is modified
		// for performance reason, sublcasses shoud override this function
		virtual double evalDiff(const Trajectory& t, size_t i0, const Trajectory::Point& testPoint) const {
			Trajectory copy = t;
			std::copy(testPoint.begin(), testPoint.end(), copy[i0].begin());
			return this->eval(copy) - this->eval(t);
		}

	private:

	};
}