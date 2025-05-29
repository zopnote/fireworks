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


/**
 * A void pointer points to data without the need to specify a type.
 * Its usage can be found when working with data of an unknown type at runtime.
 */
typedef void* voidptr_t;
typedef struct {
    char* err;
    void* val;
    bool nil;
} expect_voidptr_t;

void* alloc(unsigned __int64 size);

void delete(voidptr_t ptr);

/**
 * @brief Type definition macro for improved value handling.
 * @param type Type that should be defined.
 * @param name Name that will be defined with type.
*/
#define typedef(type, name)                                                 \
typedef type name##_t;                                                      \
typedef struct {                                                            \
    char* err;                                                              \
    name##_t val;                                                           \
    bool nil;                                                               \
} expect_##name##_t;                                                        \
typedef name##_t* name##ptr_t;                                              \
typedef struct {                                                            \
    char* err;                                                              \
    name##ptr_t val;                                                        \
    bool nil;                                                               \
} expect_##name##ptr_t;                                                     \
inline expect_##name##ptr_t new_##name##_t(unsigned __int64 size, ...) {    \
    __builtin_va_list args;                                                 \
    int len = 0;                                                            \
    __builtin_va_start(args, 0);                                            \
    len = __builtin_va_arg(args, int);                                      \
    __builtin_va_end(args);                                                 \
    void* ptr = alloc(size * len);                                          \
    if (ptr) {                                                              \
        *(name##_t*)ptr = (name##_t) {};                                    \
        return (expect_##name##ptr_t) {                                     \
            .val = (name##ptr_t)ptr,                                        \
        };                                                                  \
    }                                                                       \
    return (expect_##name##ptr_t) {                                         \
        .nil = true,                                                        \
        .err = "allocation failed"                                          \
    };                                                                      \
}

#define new(name, ...) new_##name(sizeof(name), ##__VA_ARGS__)

#define del(name) delete(name);

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
#define expect(name) expect_##name



typedef(char, char);

typedef(__int64, i64);

typedef(__int32, i32);

typedef(__int16, i16);

typedef(__int8, i8);

typedef(unsigned __int64, u64);

typedef(unsigned __int32, u32);

typedef(unsigned __int16, u16);

typedef(unsigned __int8, u8);

typedef(double, f32);

typedef(double, f64);

typedef(struct {
    char* val;
    u32_t len;
}, str);