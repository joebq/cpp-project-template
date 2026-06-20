#include <iostream>

#include "utility/utility.hpp"

int main()
{
  std::cout << "hello world\n";
  auto point = Point(10, 20);
  std::cout << point.getPointX();
  
}
