#ifndef A_INCLUDES_CONFIG_H_
#define A_INCLUDES_CONFIG_H_

#define I_AM_THE_REAL_CONFIG_H "a"

#define NEEDED_BY_A "a"

#ifdef SHOW_THE_PROBLEM
#ifdef INSIDE_B_H
#fail "a/include/config.h included by b/b.h"
#endif
#endif

#endif  // A_INCLUDES_CONFIG_H_
