
/**
 * @brief The importance of a message.
 *
 * Notes will only be printed to verbose targets.
 */
typedef enum {
    critical,
    error,
    warning,
    status,
    info
} logger_significance_t;


typedef struct logger_s logger_t;


/**
 * @brief Callback for a logger function.
 *
 * Returns if an error occurs, either an error message
 * from the logger or if the callback has experienced an error.
 */
typedef bool (*logger_callback_t) (
    logger_t* logger, logger_significance_t significance,
    const char* format, ...);


/**
 * @brief Represents a logger, its conditionals and targets.
 *
 * The time is the last time a message was sent.
 * If the file is set, it will get the messages.
 */
typedef struct logger_s {
    const char* name;
    struct tm* time;
    FILE* file;
    bool own_file;
    bool verbose;
    bool print_out;
    logger_callback_t log;
} logger_t;



/**
 * @brief Creates a new logger.
 *
 * It is regardless if your set verbose and should_print_in_console,
 * if you create your own logger_log_function that ignores the fields of the
 * structure they are.
 *
 * @param name Name of the logger that will be printed.
 * @param verbose If logger_significance_e::note messages should be printed to stdout.
 * @param print_stdout If anything should be printed to stdout.
 * @param log_func Function that will receive all messages the logger gets.
 * @return A new logger with the processed values.
 */
logger_t* logger_create(
    const char* name, bool verbose, bool print_stdout,
    logger_callback_t log_func
);


/**
 * @brief Creates and add a file target to the logger.
 *
 * Note, that it always depends on the
 * logger_log_function() where messages go.
 *
 * This function is simply a wrapper to create a file,
 * checks if the file exists before and then continues with placement
 * as well as sets the logger file field.
 *
 * @param logger The logger which will get a file target.
 * @param named If the file should be named after the name field of the logger structure.
 * @param dir_path The path where the logger file and its predecessors will be placed.
 */
void logger_mk_file(
    logger_t* logger,
    bool named,
    const char* dir_path
);


/**
 * @brief Adds a file target to the logger.
 *
 * Note, that it always depends on the
 * logger_log_function() where messages go.
 *
 * Let the file write down messages to a specific file pointer.
 *
 * @param logger The logger which will get a file target.
 * @param file The file that the logger will write to.
 */
void logger_add_file(logger_t* logger, FILE* file);


/**
 * @brief Cleans the given directory by last time logs was written.
 *
 * @param log_dir_path The directory in which logs will be cleaned up.
 * @param max_log_files How many log files are allowed to exist before the function will clean them up. Default should be around 25.
 */
void logger_clean_logs(
    const char* log_dir_path, int max_log_files
);


/**
 * @brief Writes in a formatted string to the logger targets.
 *
 * If the logger file is set, all messages are written to the file.
 * Printing to the stdout depends on should_print_in_console of logger.
 * Verbose messages will always be written into the file,
 * but if it would be printed in the stdout depends on verbose of logger.
 *
 * @param logger Logger which consists of the conditions.
 * @param sign Importance of the messages that will be printed.
 * @param format String that will be formated with the arguments.
 * @param ... Arguments that will be inserted in the print call.
 * @return Returns result for error handling.
 */
bool logger_write(
    logger_t* logger, logger_significance_t sign,
    const char* format, ...);


bool logger_write_sequence(
    logger_t* logger, logger_significance_t significance,
    char** messages, size_t message_count
);



/**
 * @brief Disposes the logger and closes the file if set.
 *
 * No values of logger should be used after disposal.
 *
 * @param logger The logger which fields will be freed.
 */
void logger_del(logger_t* logger);

