// NOLINTBEGIN
#include <catch2/catch_test_macros.hpp>
#include <cstdint>
#include "utility/utility.hpp"

uint32_t factorial(uint32_t number)
{
  return number <= 1 ? number : factorial(number - 1) * number;
}

TEST_CASE("Factorials are computed", "[factorial]")
{
  REQUIRE(factorial(1) == 1);
  REQUIRE(factorial(2) == 2);
  REQUIRE(factorial(3) == 6);
  REQUIRE(factorial(10) == 3'628'800);
}

TEST_CASE("Point stores coordinates", "[point]")
{
  Point p(10, 20);
  REQUIRE(p.getPointX() == 10);
  REQUIRE(p.getPointY() == 20);
}

TEST_CASE("Point default constructor", "[point]")
{
  Point p;
  REQUIRE(p.getPointX() == 0);
  REQUIRE(p.getPointY() == 0);
}
// NOLINTEND