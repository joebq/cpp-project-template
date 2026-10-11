#include <iostream>

import utility;

int main()
{
    const auto point = Point(10, 20);
    std::cout << point.getPointX() << ' ' << point.getPointY() << '\n';
}
