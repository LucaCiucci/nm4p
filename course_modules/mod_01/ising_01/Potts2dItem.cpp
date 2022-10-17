

#include "Potts2dItem.hpp"

#include <iostream>

namespace nm4p
{
	Potts2dItem::Potts2dItem()
	{
		connect(this, &Potts2dItem::newImage, this, &Potts2dItem::onNewImage);
	}

	QRectF Potts2dItem::boundingRect() const
	{
		return QRectF(0, 0, m_img.width() * 3, m_img.height() * 3);
	}

	void Potts2dItem::paint(QPainter* painter, const QStyleOptionGraphicsItem* option, QWidget* widget)
	{
		//painter->drawRoundedRect(0, 0, m_img.width(), m_img.height(), 5, 5);
		for (int x = 0; x < 3; ++x)
		{
			for (int y = 0; y < 3; ++y)
			{
				painter->save();
				painter->setRenderHint(QPainter::Antialiasing);
				painter->drawImage(m_img.width() * x, m_img.height() * y, m_img);
				QPen pen;
				pen.setColor(Qt::red);
				pen.setCosmetic(true);
				painter->setPen(pen);
				painter->drawRect(m_img.width() * x, m_img.height() * y, m_img.width(), m_img.height());
				painter->restore();
			}
		}

		//painter->drawImage(this->pos(), m_img);
	}

	void Potts2dItem::showModel(const Ising2d& model)
	{
		QImage img(model.M(), model.N(), QImage::Format::Format_ARGB32);

		for (size_t y = 0; y < model.N(); ++y)
			for (size_t x = 0; x < model.M(); ++x)
			{
				//auto color = model[{x, y}] ? qRgb(255, 0, 0) : qRgb(0, 255, 0);
				auto color = model[{x, y}] ? qRgb(255, 255, 255) : qRgb(0, 0, 0);
				img.setPixel(QPoint{ (int)x, (int)y }, color);
			}

		emit this->newImage(img);
	}

	void Potts2dItem::onNewImage(QImage img)
	{
		this->prepareGeometryChange();
		//std::cout << std::this_thread::get_id() << std::endl;
		m_img = img;
		this->update();
	}
}