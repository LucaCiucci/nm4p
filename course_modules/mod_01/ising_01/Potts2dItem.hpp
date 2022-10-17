

#pragma once

#include <QGraphicsItem>
#include <QImage>
#include <QObject>

// !!!
#include <QPainter>
#include <QGraphicsView>
#include <qevent.h>
#include <iostream>

#include "PottsNd.hpp"

namespace nm4p
{
	class Potts2dItem : public QObject, public QGraphicsItem
	{
		Q_OBJECT
	public:

		Potts2dItem();

		QRectF boundingRect() const override;

		void paint(QPainter* painter, const QStyleOptionGraphicsItem* option, QWidget* widget) override;

		void showModel(const Ising2d& model);

		void adjsaioff() {
		}

	signals:

		void newImage(QImage img);

	public:

		void onNewImage(QImage img);

	private:
		QImage m_img;
	};

	class PottsGraphicsView : public QGraphicsView
	{
	public:

		using QGraphicsView::QGraphicsView;

		void wheelEvent(QWheelEvent* e) override
		{
			if (e->modifiers() & Qt::ControlModifier) {
				if (e->angleDelta().y() > 0)
				{
					//m_parent->zoomIn(6);
				}
				else
				{
					//m_parent->zoomOut(6);
				}
				{
					constexpr double factor = 1.125;
					const double delta = e->angleDelta().y() / 120.0 / 2;
					const double f = pow(factor, delta);

					auto anchor = this->transformationAnchor();
					this->setTransformationAnchor(QGraphicsView::ViewportAnchor::AnchorUnderMouse);
					this->scale(f, f);
					this->setTransformationAnchor(anchor);
				}
				e->accept();
			}
			else {
				QGraphicsView::wheelEvent(e);
			}
		}

	private:

	};
}