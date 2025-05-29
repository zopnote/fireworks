// Copyright (c) 2025 Lenny Siebert
//
// This software is dual-licensed:
//
// 1. Open Source License:
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License version 3
//    as published by the Free Software Foundation.
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY. See the GNU General Public
//    License for more details: https://www.gnu.org/licenses/gpl-3.0.en.html
//
// 2. Commercial License:
//    A commercial license will be available at a later time for use in commercial products.

#include <mem.h>
#include <stdlib.h>

#define align_bytes_m 8

void* alloc(const unsigned __int64 size) {
    return malloc(size);
}

void delete(const voidptr_t ptr) {
    if (ptr) free(ptr);
}

void mem_free(voidptr_t ptr) { free(ptr); }

expect(arena_t) arena_new(const u64_t size) {
    voidptr_t ptr = malloc(size);
    if (!ptr) return (expect(arena_t)) { "failed to allocate memory for arena" };

    return (expect(arena_t)) {
        .nil = true,
        .val = (arena_t) { ptr, size }
    };
}

expect(voidptr_t) arena_alloc(arena_t arena[static 1], const u64_t size) {
    if (!arena->ptr) return (expect(voidptr_t)) { "arena data pointer is invalid" };

    const u64_t aligned = arena->pos + align_bytes_m - 1 & ~(align_bytes_m - 1);
    const u64_t offset = aligned + size;
    if (arena->size < offset) return (expect(voidptr_t)) { "insufficient space in arena" };

    voidptr_t ptr = arena->ptr + aligned;
    arena->pos = offset;
    return (expect(voidptr_t)) { .val = ptr };
}

void arena_del(arena_t arena[static 1]) {
    mem_free(arena->ptr);
    *arena = (arena_t) {};
}


