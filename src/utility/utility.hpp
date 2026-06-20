#pragma once

class Point
{
    public:
    Point() = default;
    Point(int pointX, int pointY) noexcept;
    [[nodiscard]] int getPointX() const noexcept;
    [[nodiscard]] int getPointY() const noexcept;

    private:
    int pointX = 0;
    int pointY = 0;
};
