#include <iostream>

#include "experimental/users/aiuto/bazel/config_include/a/a.h"
#include "experimental/users/aiuto/bazel/config_include/b/b.h"

#ifdef SHOW_THE_PROBLEM
#ifndef B_INCLUDES_CONFIG_H_
#fail "Where was b/includes/config.h"
#endif
#endif

int main(int argc, char* argv[]) {
  std::cout << "a=" << a() << " and b=" << b() << std::endl;
  std::cout << "The real config is " << I_AM_THE_REAL_CONFIG_H << std::endl;
}
