// NOLINTBEGIN
#include <catch2/catch_test_macros.hpp>

import utility;

TEST_CASE("Module: Point stores coordinates", "[module]")
{
  Point p(10, 20);
  REQUIRE(p.getPointX() == 10);
  REQUIRE(p.getPointY() == 20);
}
// NOLINTEND
