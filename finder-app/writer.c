#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>

int main(int argc, char *argv[]) {
    // Check if correct number of arguments are provided
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <string> <file>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    // Open file for writing
    FILE *file = fopen(argv[2], "w");
    if (file == NULL) {
        syslog(LOG_ERR, "Failed to open file %s for writing", argv[2]);
        perror("Error");
        exit(EXIT_FAILURE);
    }

    // Write string to file
    if (fprintf(file, "%s\n", argv[1]) < 0) {
        syslog(LOG_ERR, "Failed to write string to file %s", argv[2]);
        perror("Error");
        exit(EXIT_FAILURE);
    }

    // Close file
    fclose(file);

    // Log the action using syslog
    openlog("writer", LOG_PID | LOG_CONS, LOG_USER);
    syslog(LOG_DEBUG, "Writing %s to %s", argv[1], argv[2]);
    closelog();

    return EXIT_SUCCESS;
}
