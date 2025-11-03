#include <gtest/gtest.h>
#include "../math_operations.h"

TEST(MathTest, BasicAddition) {
    EXPECT_EQ(add(2, 3), 5);
}


int main(int argc, char **argv) {
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
