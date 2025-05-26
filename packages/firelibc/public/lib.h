// Copyright (c) 2025 Lenny Siebert
//
// This software is dual-licensed:
//
// 1. Open Source License:
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY. See the GNU General Public License for
//    more details: https://www.gnu.org/licenses/gpl-3.0.en.html
//
// 2. Commercial License:
//    A commercial license will be available at a later time for use in commercial products.


#pragma once
#include "strings.h"

typedef struct {
    str_t value;
} error_t;



/**
 * @brief Simple generic macro to define expected types easier
 * @param type The type the expected struct will be generated for.
 *
 * Whenever you have a pointer, you should typedef it.
 * The * would violate the type definition of the struct.
 * @code
 *      typedef player_t* playerptr_t
 *      define_expect(playerptr_t)
 * @endcode
 */
#define define_expect(type)   \
struct expected_##type {      \
    type value;               \
    bool valid;               \
    error_t error;            \
}

/**
 * @brief Expect a type and handle errors that may occur.
 * @param type The type you expect.
 *
 * After receiving an expect(type), you have to check its validity before you can use its value safely.
 * @code
 *      expect(player_t) expect_player = world_spawn(goal.pos)
 *      if (!expect_player.valid) {
 *          return error_join(error_new("error of player spawn"), expect_player.error)
 *      }
 *      player_t player = expect_player.value;
 *      f32_t health = player.health;
 * @endcode
 */
#define expect(type) struct expected_##type

/**
 * A void pointer points to data without the need to specify a type.
 * Its usage can be found when working with data of an unknown type at runtime.
 */
typedef void* voidptr_t;
define_expect(voidptr_t);

/**
 * @brief Create an error.
 * @param value The string which describes the error that happened.
 * @return Returns the error.
 */
error_t error_new(char const value[static 1]);

/**
 * @brief Joins two errors together.
 * @param parent The superior error.
 * @param child The lower error.
 * @return Returns a new error which consists of both inferior errors.
 */
error_t error_join(error_t parent, error_t child);

