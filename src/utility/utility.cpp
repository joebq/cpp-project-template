#include "utility.hpp"

Point::Point(int pointX, int pointY) noexcept
:   pointX(pointX), 
    pointY(pointY) 
{}

[[nodiscard]]
int Point::getPointX() const noexcept { return pointX; }

[[nodiscard]]
int Point::getPointY() const noexcept { return pointY; }


