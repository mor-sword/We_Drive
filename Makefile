# We_Drive — build on Windows with raylib.
PROJECT_NAME ?= wedrive
OBJS        ?= main.c
RAYLIB_PATH ?= C:/raylib/raylib
BUILD_MODE  ?= RELEASE
CC           = gcc
CFLAGS       = -Wall -std=c99 -I$(RAYLIB_PATH)/src
LDFLAGS      = -L$(RAYLIB_PATH)/src -lraylib -lopengl32 -lgdi32 -lwinmm -mwindows

ifeq ($(BUILD_MODE),DEBUG)
    CFLAGS += -g -O0
else
    CFLAGS += -s -O2
endif

$(PROJECT_NAME): $(OBJS)
	$(CC) -o $@ $< $(CFLAGS) $(LDFLAGS)

clean:
	del /q *.exe 2>NUL || rm -f *.exe
	@echo Cleaning done