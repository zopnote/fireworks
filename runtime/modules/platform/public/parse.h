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

#include "logger.h"

/**
 * @brief Available configuration types of the parse collection.
 */
enum parse_format_e {
    yaml,
    json
};

/**
 * @brief The type the buffer of an entry have.
 *
 * Maps are further ParseEntry arrays which must be
 * already defined and set as buffer of an entry to store
 * the recursive values in it.
 *
 * Lists are an array of unparsed strings of the parsed document.
 * Their buffer should not be set at first definition.
 */
enum parse_type_e {
    map,
    integer,
    string,
    floating,
    list
};


/**
 * @brief Representation of an entry.
 *
 * Define a tree by create an array of entries to load
 * configuration values from a file or write them to a string.
 *
 * All value buffers except the map should not be set.
 * Maps are further ParseEntry arrays. The size value represent
 * the length of an array in case the buffer is an array
 * or the actual size of the value behind the buffer.
 *
 * The parser scans for the key and decide based on the ParseType
 * what the buffer should be and set it. Buffers can be null even after
 * the parse process, if the value was not found.
 */
typedef struct {
    char* key;
    enum parse_type_e type;
    void* buffer;
    size_t size;
} parse_entry_t;

/**
 * @brief Initialize the yaml parser with the input string and continues with the scan.
 *
 * The entries array buffer will be filled with the found values.
 *
 * @param string String that will be parsed in the entries buffer array.
 * @param entries Buffer array that defines for which values will be looked for and processed.
 * @param entries_length Length of the entries array.
 * @param logger Defines where information while the process about the processing should go to.
 */
bool parse_resolve(
    const char* string,
    parse_entry_t* entries,
    size_t entries_length,
    logger_t* logger
);

/**
 * @brief Writes the entries to the string buffer with the desired configuration format.
 *
 * @param buffer String buffer which the emitted yaml will go to.
 * @param entries Buffer array that define which values will be processed.
 * @param entries_length Length of the entries buffer array.
 * @param logger Defines where information while the process about the processing should go to.
 */
void parse_emit(
    char* buffer,
    const parse_entry_t* entries,
    size_t entries_length,
    const logger_t* logger
);
