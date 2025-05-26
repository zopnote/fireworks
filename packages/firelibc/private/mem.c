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
#include <string.h>

#define align_bytes_m 8

expect(voidptr_t) mem_alloc(const u64_t size) {
    void* const ptr = malloc(size);
    if (ptr) return (expect(voidptr_t)) { .value = ptr };

    return (expect(voidptr_t)) {
        .error = error_join(
            error_new( "error while allocating memory" ),
            error_new( strerror(errno) )
        )};
}


void mem_free(void* ptr) { free(ptr); }

expect(arena_t) arena_new(const u64_t size) {
    void* ptr = malloc(size);
    if (!ptr) return ( expect(arena_t) ) {
        .error = error_join(
            error_new( "failed to allocate memory for arena" ),
            error_new( strerror(errno) )
        )
    };
    return ( expect(arena_t) ) {
        .value = (arena_t) {
            .data = ptr,
            .size = size,
            .offset = 0
        }
    };
}

expect(voidptr_t) arena_alloc(arena_t arena[static 1], const u64_t size) {
    if (!arena->data) {
        return (expect(voidptr_t)) {
            .error = error_new( "arena data pointer is invalid" )
        };
    }
    const u64_t aligned = arena->offset + align_bytes_m - 1 & ~(align_bytes_m - 1);
    const u64_t offset = aligned + size;
    if (arena->size < offset) {
        return (expect(voidptr_t)) {
            .error = error_new( "insufficient space in arena" )
        };
    }

    void* ptr = arena->data + aligned;
    arena->offset = offset;
    return (expect(voidptr_t)) {
        .value = ptr
    };
}

void arena_dispose(arena_t arena[static 1]) {
    arena->size = 0;
    arena->offset = 0;
    mem_free(arena->data);
}