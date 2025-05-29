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
//


#pragma once
#include "lib.h"

/**
 * An arena is a representation of a space in memory used to combine the lifetime
 * management of multiple variables to make memory management easier.
 */
typedef struct { u8_t* ptr; u64_t size; u64_t pos; } arena_t;
typedef struct { char* err; arena_t val; bool nil; } expect_arena_t;
typedef arena_t* arenaptr_t;
typedef struct { char* err; arenaptr_t val; bool nil; }
expect_arenaptr_t; inline expect_arenaptr_t new_arena_t(u64_t size, ...) {
    __builtin_va_list args;
    u64_t len = 0;
    __builtin_va_start(args, 0);
    len = __builtin_va_arg(args, u64_t);
    __builtin_va_end(args);
    void* ptr = alloc(size * len);
    if (ptr) { *(arena_t*)ptr = (arena_t) {};
        return (expect_arenaptr_t) { .val = (arenaptr_t)ptr, }; }
    return (expect_arenaptr_t) { .nil = true, .err = "allocation failed" };
};

/**
 * @brief Wrapper around libc malloc to allocate block of memory.
 * @param size Size of the memory block you want to allocate.
 * @return Returns a voidptr_t pointing to the allocated block.
 */
expect(voidptr_t) mem_alloc(u64_t size);

/**
 * @brief Wrapper around libc's free() to free up an allocated memory block.
 * @param ptr Pointer that should be freed.
 */
void mem_free(voidptr_t ptr);

/**
 * @brief Creates and allocate a new arena of memory.
 * @param size Size of the memory capacity the arena should have.
 * @return Returns the allocated arena.
 */
expect(arena_t) arena_new(u64_t size);

/**
 * @brief Get a memory block out of the arena.
 * @param arena Pointer to the arena the allocation of the new item should happen in.
 * @param size The size of the wanted memory block.
 * @return Returns an expected void pointer to the received block.
 */
expect(voidptr_t) arena_alloc(arena_t arena[static 1], u64_t size);

/**
 * @brief Frees the memory of the arena. 
 * @param arena The arena that should be freed.
 */
void arena_del(arena_t arena[static 1]);

/**
 * @brief Frees the memory of the arena.
 * @param arena The arena that should be freed.
 */
void arena_reset(arena_t arena[static 1]);