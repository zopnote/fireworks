
/**
 * @brief Lowercases a string independent of platform.
 * @param string Input string.
 * @return Output string.
 */
char* str_to_lower(const char* string);

/**
 * @brief Gets the parent path of a path.
 * @param path Path of entity which parent path will be written to the buffer.
 * @param buffer Buffer that will get the parent path.
 * @return Returns if the process was successful.
 */
bool superior_path(char* buffer, const char* path);


/**
 * @brief Writes the content of the file to the buffer.
 * @param file The file that content will be get.
 * @param buffer Pointer to the buffer.
 * @param buffer_size Max length of the buffer.
 * @return If the function proceed successful.
 */
bool fcontent(
    char* buffer, size_t buffer_size, FILE* file
);

/**
 * @brief Copies a file.
 * @param source_file File content that will be copied.
 * @param destination_path Full path of the file that will be created.
 * @return Returns if the process was successful.
 */
bool fcopy(FILE* source_file, const char* destination_path);

/**
 * @brief Gets the directory the program runs at.
 *
 * @param buffer The buffer the path will be written to.
 * @param buffer_size Size of the buffer.
 * @return Returns if the buffer is set.
 */
bool work_dir(char* buffer, size_t buffer_size);


/**
 * @brief Gets the directory the executable is in.
 *
 * @param buffer The buffer the path will be written to.
 * @param buffer_size Size of the buffer.
 * @return Returns if the buffer is set.
 */
bool exe_dir(char* buffer, size_t buffer_size);


/**
 * @brief Tests if a file system entity exists.
 *
 * @param path Path of the entity that will be tested for.
 * @return Returns if the entity exists.
 */
bool can_access(const char* path);


/**
 * @brief Creates a directory.
 *
 * @param path Path of the directory that should be created.
 * @return Returns if the creation of the directory succeeded.
 */
bool make_dir(const char* path);


/**
 * @brief Gets the files by path in a directory.
 *
 * @param buffer Buffer the found file paths will be saved to.
 * @param dir_path Path of the directory that will be scanned.
 * @return Returns the length of the buffer array, which is the count of found files.
 */
int list_files(const char* dir_path, char*** buffer);

