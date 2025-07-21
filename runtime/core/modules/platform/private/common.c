

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

char* str_to_lower(const char* string)
{
    char* temp = strdup(string);
    for (char* cur = temp; *cur; ++cur) *cur = tolower(*cur);
    return temp;
}

bool superior_path(char* buffer, const char* path) {
    bool terminated = false;
    size_t i = strlen(path) + 1;
    while (i > 0) {
        i--;
        buffer[i] = path[i];

        if (terminated) {
            continue;
        }

        if (buffer[i] == '\\' || buffer[i] == '/') {
            buffer[i] = '\0';
            terminated = true;
        }

        if (i == 1) {
            return false;
        }
    }
    return true;
}

bool fcontent(
    char* buffer,
    const size_t buffer_size,
    FILE* file
) {
    if (!file) {
        perror("File cannot be opened");
        return false;
    }

    const int result = fseek(file, 0, SEEK_SET);
    if (result != 0) {
        perror("File cannot be read");
        return false;
    }

    char read;
    size_t i = 0;
    while ((read = fgetc(file)) != EOF) {
        if (i >= buffer_size) break;
        buffer[i] = read;
        i++;
    }
    buffer[i] = '\0';

    return true;
}

bool fcopy(
    FILE* source_file, const char* destination_path
) {
    FILE* target_file = fopen(destination_path, "w");
    if (!target_file) {
        return false;
    }

    const int result = fseek(source_file, 0, SEEK_SET);

    if (result != 0) {
        return false;
    }
    char read;
    while ((read = fgetc(source_file)) != EOF) {
        fputc(read, target_file);
    }

    fclose(target_file);
    return true;
}

void str_replace(char* target, const char* needle, const char* replacement)
{
    char buffer[1024] = { 0 };
    char *insert_point = &buffer[0];
    const char *tmp = target;
    const size_t needle_len = strlen(needle);
    const size_t repl_len = strlen(replacement);

    while (1) {
        const char* p = strstr(tmp, needle);

        if (p == NULL) {
            strcpy(insert_point, tmp);
            break;
        }

        memcpy(insert_point, tmp, p - tmp);
        insert_point += p - tmp;

        memcpy(insert_point, replacement, repl_len);
        insert_point += repl_len;

        tmp = p + needle_len;
    }
    strcpy(target, buffer);
}




#ifdef _WIN32
#include <direct.h>
#include <io.h>
#include <windows.h>

bool work_dir(char* buffer, const size_t buffer_size) {
    return _getcwd(buffer, buffer_size);
}

bool exe_dir(char* buffer, const size_t buffer_size) {

    char path[MAX_PATH];

    const auto str_len = GetModuleFileName(
        NULL,
        path,
        MAX_PATH
    );

    if (str_len == 0) {
        return false;
    }

    for (size_t i = str_len; i > 0; i--) {
        if (
            path[i] == '\\' ||
            path[i] == '/'
        ) {
            path[i] = '\0';
            break;
        }
    }
    strcpy_s(buffer, buffer_size, path);

    return true;
}

bool can_access(const char* path) {
    return _access(path, 4) == 0;
}

bool make_dir(const char* path) {
    return _mkdir(path) == 0;
}


int list_files(const char* dir_path, char*** buffer) {
    WIN32_FIND_DATA found_file_data;
    auto found_file = INVALID_HANDLE_VALUE;
    int total_count = 0;

    char search_path[MAX_PATH];
    snprintf(search_path, MAX_PATH, "%s\\*", dir_path);

    found_file = FindFirstFile(search_path, &found_file_data);
    if (found_file == INVALID_HANDLE_VALUE) {
        return 0;
    }

    char** list = NULL;
    while (FindNextFile(found_file, &found_file_data)) {

        if (!strcmp(found_file_data.cFileName, ".")) {
            continue;
        }

        if (!strcmp(found_file_data.cFileName, "..")) {
            continue;
        }

        if (found_file_data.dwFileAttributes &FILE_ATTRIBUTE_DIRECTORY) {
            continue;
        }

        void* old_list = list;
        list = realloc(
            list,
            sizeof(char*) *
            (total_count + 1)
        );
        if (!list) {
            free(old_list);
            continue;
        }

        list[total_count] = strdup(
            found_file_data.cFileName
        );

        total_count++;
    }

    FindClose(found_file);
    *buffer = list;
    return total_count;
}


#else

#include <dirent.h>
#include <libgen.h>
#include <unistd.h>
#include <sys/stat.h>

bool work_dir(char* buffer, const size_t buffer_size) {
     return getcwd(buffer, buffer_size) == 0;
}

bool exe_dir(char* buffer, const size_t buffer_size) {
    const size_t path_len = readlink(
        "/proc/self/exe",
        buffer,
        buffer_size - 1
    );

    if (path_len != (long unsigned int)-1) {
        buffer[path_len] = '\0';
        const char* dir = dirname(buffer);
        strncpy(buffer, dir, buffer_size);
        return true;
    }
    return false;
}

bool can_access(const char* path) {
    return access(path, R_OK) == 0;
}

bool make_dir(const char* path) {
    return mkdir(path, 0755) == 0;
}

int list_files(const char* dir_path, char*** buffer) {

    struct dirent* dir_entity;
    int total_entities = 0;
    struct stat file_attributes;
    char** temp_buffer = NULL;

    DIR* dir = opendir(dir_path);
    if (!dir) {
        return 0;
    }

    while ((dir_entity = readdir(dir)) != NULL) {
        char full_path[1024];
        snprintf(
            full_path,
            sizeof(full_path),
            "%s/%s",
            dir_path,
            dir_entity->d_name
        );
        if (
            stat(full_path, &file_attributes) == 0 &&
            S_ISREG(file_attributes.st_mode)
        ) {
            total_entities++;
        }
    }

    temp_buffer = (char**)malloc(total_entities * sizeof(char*));
    if (!temp_buffer) {
        closedir(dir);
        return 0;
    }

    rewinddir(dir);
    int index = 0;
    while ((dir_entity = readdir(dir)) != NULL) {
        char full_path[1024];
        snprintf(
            full_path,
            sizeof(full_path),
            "%s/%s",
            dir_path,
            dir_entity->d_name
        );

        if (
            stat(full_path, &file_attributes) == 0 &&
            S_ISREG(file_attributes.st_mode)
        ) {
            temp_buffer[index] = strdup(full_path);
            index++;
        }
    }

    closedir(dir);
    *buffer = temp_buffer;
    return total_entities;
}

#endif
