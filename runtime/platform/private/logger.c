#include "logger.h"
#include "common.h"


static bool str_of_time(const struct tm* time, char* buffer) {
    return sprintf(
        buffer, "%02d:%02d:%02d, %02d-%02d-%d",
        time->tm_hour, time->tm_min, time->tm_sec,
        time->tm_mday, time->tm_mon + 1, time->tm_year + 1900
    );
}



static struct tm* time_of_str(const char* str) {
    struct tm* time = malloc(sizeof(struct tm));
    if (!time) {
        perror("Error while parsing time for the logger");
        return NULL;
    }

    if (sscanf(
        str, "%d-%d-%d__%d-%d-%d_",
        &time->tm_hour, &time->tm_min, &time->tm_sec,
        &time->tm_mday, &time->tm_mon, &time->tm_year
    ) == 6) return time;

    if (sscanf(
        str, "%d:%d:%d, %d-%d-%d ",
        &time->tm_hour, &time->tm_min, &time->tm_sec,
        &time->tm_mday, &time->tm_mon, &time->tm_year
    ) == 6) return time;

    perror("Error while parsing time for the logger");
    free(time);
    return NULL;
}



static void replace_unknown_chars(char* buffer) {
    for (size_t i = 0; i < strlen(buffer); i++) {
        if (buffer[i] == ',' || buffer[i] == ' ') buffer[i] = '_';
        else if (buffer[i] == ':') buffer[i] = '-';
    }
}

struct name_s {
    int sign;
    char* name;
    bool print_out;
};

static struct name_s get_name(
    const logger_significance_t sign, const logger_t* logger
) {
    const struct name_s names[] = {
        {critical, "CRITICAL", true},
        {error, "ERROR", true},
        {warning, "WARNING", logger->print_out},
        {status, "STATUS", logger->print_out},
        {info, "INFO", logger->print_out && logger->verbose}
    };
    return names[sign];
}

static bool get_meta(
    char* buffer, const size_t buffer_length, FILE* file
) {
    fseek(file, 0, SEEK_END);
    const long file_size = ftell(file);
    if (file_size == -1) {
        perror("Error while seeking file size");
        return false;
    }

    int end = -1, start = -1;
    for (long i = file_size - 1; i >= 0; i--) {
        fseek(file, i, SEEK_SET);
        char cur;
        if (fread(&cur, 1, 1, file) != 1) {
            perror("Error while reading file");
            return false;
        }

        if (cur == ')' && end == -1) end = i;
        else if (cur == '(') {
            start = i;
            break;
        }
    }

    if (start == -1 || end == -1 || start >= end)
        return false;

    const size_t size = (end - start - 1);
    if (size >= buffer_length) return false;

    fseek(file, start + 1, SEEK_SET);
    if (fread(buffer, 1, size, file) != size) {
        perror("Error while reading file content");
        return false;
    }

    buffer[size] = '\0';
    return true;
}



static bool archive(const char* file_path) {
    FILE* old_file = fopen(file_path, "r");
    if (!old_file) {
        fprintf(stderr,
            "Can't open log file to archive its content."
        );
        return false;
    }
    const size_t meta_size = 64;
    char meta[meta_size];
    if (!get_meta(meta, meta_size, old_file)) {
        fprintf(stderr, "No valid meta in %s.\n", file_path);
        fclose(old_file);
        return false;
    }

    const size_t archived_path_size = strlen(file_path) +
        strlen(meta) + 6;
    char* archived_path = malloc(archived_path_size);
    if (!superior_path(archived_path, file_path)) {
        fclose(file_path);
        return false;
    }
    strcat(archived_path, "/logs");
    make_dir(archived_path);

    replace_unknown_chars(meta);
    strcat(meta, ".log");
    sprintf(archived_path, "%s/%s", archived_path, meta);

    if (!fcopy(old_file, archived_path)) {
        fprintf(stderr, "File %s can't be copied.\n", file_path);
        fclose(old_file);
        return false;
    }
    fclose(old_file);
    bool result = true;
    if (can_access(file_path)) result = remove(file_path);
    return result;
}



static void compute_time_stamp(
    const char* log_path, unsigned long long* stamp_buffer
) {
    size_t start;
    for (start = strlen(log_path); start > 0; start--)
        if (log_path[start - 1] == '/' ||
            log_path[start - 1] == '\\'
        ) break;

    size_t end;
    for (end = strlen(log_path); end > 0; end--)
        if (log_path[end - 1] == '_') break;

    if (end <= start) {
        fprintf(stderr, "Error: end_index <= start_index.\n");
        return;
    }

    char* file_name = malloc(end - start + 1);
    strncpy(file_name, log_path + start, end - start);
    file_name[end - start] = '\0';

    struct tm* time = time_of_str(file_name);
    if (!time) {
        free(file_name);
        free(time);
        fprintf(stderr, "An error occurred while parsing the time.\n");
        return;
    }
    const unsigned long long time_stamp =
        time->tm_year * pow(10, 10) +
        time->tm_mon * pow(10, 8) +
        time->tm_mday * pow(10, 6) +
        time->tm_hour * pow(10, 4) +
        time->tm_min * pow(10, 2) +
        time->tm_sec;
    free(time);

    *stamp_buffer = time_stamp;
}



logger_t* logger_create(
    const char* name, const bool verbose,
    const bool print_stdout, const logger_callback_t log_func
) {

    time_t raw_time;
    time(&raw_time);
    const struct tm* time_info = localtime(&raw_time);
    if (!time_info) {
        perror("Can't create logger. Can't get the local time");
        return NULL;
    }

    logger_t* logger = malloc(sizeof(logger_t));
    if (!logger) {
        perror("Failed to create logger");
        return NULL;
    }

    logger->time = malloc(sizeof(struct tm));
    if (!logger->time) {
        perror("Failed to create logger time");
        free(logger);
        return NULL;
    }

    *logger->time = *time_info;
    *logger = (logger_t) {
        .name = name,
        .verbose = verbose,
        .print_out = print_stdout,
        .log = log_func,
        .own_file = false,
        .file = NULL
    };

    return logger;
}

void logger_add_file(logger_t* logger, FILE* file) {
    logger->own_file = false;
    logger->file = file;
}

void logger_mk_file(
    logger_t* logger, const bool named, const char* dir_path
) {
    const char* unnamed = "latest";
    char* name = strdup(unnamed);
    if (named) name = str_to_lower(logger->name);

    strcat(name, ".log");
    char* path = malloc(strlen(dir_path) + strlen(name) + 1);
    sprintf(path, "%s/%s", dir_path, name);

    bool success = false;
    if (can_access(path)) success = archive(path);
    else success = true;

    if (!success && !remove(path)) {
        if (!named) logger_mk_file(logger, true, dir_path);
        return;
    }
    logger->own_file = true;
    logger->file = fopen(path, "a");
    logger->log(logger, info, "Logger mounted to file.");
}

bool logger_write(
    logger_t* logger, const logger_significance_t sign,
    const char* format, ...
) {
    bool found_arg = false;
    for (size_t i = 0; i < strlen(format); i++)
        if (format[i] == '%') found_arg = true;

    char* msg;

    if (found_arg) {
        va_list args;
        va_start(args, format);
        #if _WIN32
        const int size = _vscprintf(format, args);
        #else
        const int size = vsnprintf(NULL, 0, format, args);
        #endif

        va_end(args);

        if (size < 0) return NULL;

        msg = malloc(size + 1);
        if (!msg) return NULL;

        va_start(args, format);
        vsnprintf(msg, size + 1, format, args);
        va_end(args);
    }
    else msg = strdup(format);

    char* meta = malloc(strlen(logger->name) + 24);
    time_t raw_time;
    time(&raw_time);
    struct tm* time = localtime(&raw_time);
    if (!time) {
        perror("Time cannot be initialized");
        free(msg);
        free(meta);
        return false;
    }
    if (!str_of_time(time, meta)) {
        perror("Time cannot be converted to valid string");
        free(msg);
        free(meta);
        return false;
    }
    sprintf(meta, "%s, %s", meta, logger->name);
    if (logger->time) free(logger->time);
    logger->time = malloc(sizeof(struct tm));
    if (!logger->time) {
        perror("Allocation of logger time failed");
        free(msg);
        free(meta);
        return false;
    }
    *logger->time = *time;

    if (get_name(sign, logger).print_out) printf("%s\n", msg);

    if (!logger->file) {
        free(msg);
        free(meta);
        return sign != error;
    }

    char* final_msg = malloc(
        strlen(msg) + strlen(logger->name) +
        strlen(get_name(sign, logger).name) + 30
    );
    sprintf(
        final_msg, "(%s)  %s  %s\n",
        meta, get_name(sign, logger).name, msg
    );
    fwrite(
        final_msg, sizeof(char),
        strlen(final_msg), logger->file
    );

    free(meta);
    free(msg);
    free(final_msg);
    return sign != error;
}

bool logger_write_sequence(
    logger_t* logger, const logger_significance_t sign,
    char** messages, const size_t message_count
) {

    size_t msg_size = 0;
    for (size_t i = 0; i < message_count; i++) {
        msg_size += strlen(messages[i]);
        msg_size += 6;
    }

    char* stdout_msg = malloc(msg_size + 1);
    stdout_msg[0] = '\0';
    char* msg = malloc(msg_size + 1);
    msg[0] = '\0';
    for (size_t i = 0; i < message_count; i++) {
        strcat(msg, "     ");
        strcat(msg, messages[i]);
        strcat(msg, "\n");
        strcat(stdout_msg, messages[i]);
        strcat(stdout_msg, "\n");
    }

    char* meta = malloc(strlen(logger->name) + 24);
    time_t raw_time;
    time(&raw_time);
    struct tm* time = localtime(&raw_time);
    if (!time) {
        perror("Time cannot be initialized");
        free(msg);
        free(stdout_msg);
        free(meta);
        return false;
    }
    if (!str_of_time(time, meta)) {
        perror("Time cannot be converted to valid string");
        free(msg);
        free(stdout_msg);
        free(meta);
        return false;
    }
    sprintf(meta, "%s, %s", meta, logger->name);
    if (logger->time) free(logger->time);
    logger->time = malloc(sizeof(struct tm));
    if (!logger->time) {
        perror("Allocation of logger time failed");
        free(msg);
        free(stdout_msg);
        free(meta);
        return false;
    }
    *logger->time = *time;

    if (get_name(sign, logger).print_out) printf("%s\n", stdout_msg);

    if (!logger->file) {
        free(msg);
        free(stdout_msg);
        free(meta);
        return sign != error;
    }

    char* final_msg = malloc(
        strlen(msg) + strlen(logger->name) +
        strlen(get_name(sign, logger).name) + 33
    );
    sprintf(
        final_msg, "(%s)  %s  [\n%s]\n",
        meta, get_name(sign, logger).name, msg
    );
    fwrite(
        final_msg, sizeof(char),
        strlen(final_msg), logger->file
    );

    free(meta);
    free(msg);
    free(stdout_msg);
    free(final_msg);
    return true;
}

void logger_clean_logs(
    const char* log_dir_path, const int max_log_files
) {
    char** files = NULL;
    const int file_count = list_files(
        log_dir_path, &files
    );
    if (!files) {
        if (file_count == 0) return;
        perror("Error while reading files of log directory");
        return;
    }

    if (max_log_files >= file_count) {
        for (int i = 0; i < file_count; i++) free(files[i]);
        free(files);
        return;
    }

    struct log_s {
        unsigned long long time_stamp;
        char* name;
        bool deletable;
    }* logs = malloc(file_count * sizeof(struct log_s));

    if (!logs) {
        perror("Error while allocation of logs list");
        return;
    }

    for (int i = 0; i < file_count; i++) {
        logs[i].deletable = false;
        logs[i].name = malloc(sizeof(char) * (
            strlen(files[i]) + strlen(log_dir_path) + 2
        ));

        if (!logs[i].name) {
            perror("Error while allocation of log name");
            free(logs);
            return;
        }
        sprintf(logs[i].name, "%s/%s", log_dir_path, files[i]);

        compute_time_stamp(files[i], &logs[i].time_stamp);
        if (files[i]) free(files[i]);

        if (i != 0 && i < file_count - i) {
            const size_t prev = i - 1;
            if (logs[prev].time_stamp < logs[i].time_stamp) {
                logs[prev].deletable = true;
            }
        }
    }

    for (int i = 0; i < file_count; i++) {
        if (!logs[i].deletable) free(logs[i].name);
        else {
            remove(logs[i].name);
            free(logs[i].name);
        }
    }
    free(files);
}



void logger_del(logger_t* logger) {
    if (!logger) return;
    if (!logger->time) free(logger->time);
    logger->log(logger, info, "Disposal of logger %s.", logger->name);
    if (logger->file && logger->own_file) fclose(logger->file);
    logger = NULL;
}
