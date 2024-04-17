# Default target builds the writer application
all: writer

# Compiler settings
CC := gcc
CFLAGS := -Wall -Wextra
LDFLAGS :=

# Cross-compiler settings
ifeq ($(filter-out aarch64-none-linux-gnu-,$(CROSS_COMPILE)),)
CC := $(CROSS_COMPILE)$(CC)
endif

# Source and object files
SRC := writer.c
OBJ := $(SRC:.c=.o)

# Default target for building the writer application
writer: $(OBJ)
	$(CC) $(LDFLAGS) -o $@ $^

# Rule to compile C source files
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

# Clean target to remove application and object files
clean:
	rm -f writer $(OBJ)
