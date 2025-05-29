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
// Created by @zopnote on 14.05.2025.
//



#include <stdio.h>


#include "../public/lib.h"
void do_stuff(const u64ptr_t ptr) {
    *ptr = *ptr + 1;
}

int main() {

    const expect(u64ptr_t) num = new(u64_t, 12);
    if (!num.nil) {
        do_stuff(num.val + sizeof(u64_t));
        printf("num.val: %llu", *num.val + sizeof(u64_t));
        del(num.val);
    }
    return 0;
}
