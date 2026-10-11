#include "utility/utility.hpp"

#include <iostream>

[[nodiscard]] int sum(int one, int two)
{
    return one + two;
}

int main()
{
    std::cout << "hello world\n";
    const auto point = Point(10, 20);
    std::cout << point.getPointX();

    const auto mypoint = Point(30, 40);
    const auto summation = sum(2, 4);
    std::cout << summation;
}
