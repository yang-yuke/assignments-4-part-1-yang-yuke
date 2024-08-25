#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{

    // TODO: wait, obtain mutex, wait, release mutex as described by thread_data structure
    // hint: use a cast like the one below to obtain thread arguments from your parameter
    //struct thread_data* thread_func_args = (struct thread_data *) thread_param;

    // Cast thread_param to thread_data pointer
    struct thread_data* thread_func_args = (struct thread_data*) thread_param;

    // Pre-wait before obtaining the mutex
    usleep(thread_func_args->wait_to_obtain_ms*1000);

    // Obtain the mutex
    pthread_mutex_lock(thread_func_args->mutex);

    // Post-wait while holding the mutex
    usleep(thread_func_args->wait_to_obtain_ms*1000);

    // Release the mutex
    pthread_mutex_unlock(thread_func_args->mutex);

    thread_func_args->thread_complete_success = true;
    
    return thread_param;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
    /**
     * TODO: allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
     * using threadfunc() as entry point.
     *
     * return true if successful.
     *
     * See implementation details in threading.h file comment block
     */
    struct thread_data* data = malloc(sizeof(struct thread_data));

    if(data == NULL)
    {
        return false; // Memory allocation failed
    }

    // Set up mutex and wait arguments
    data->mutex = mutex;
    data->thread_complete_success = false;
    data->wait_to_obtain_ms = wait_to_obtain_ms;
    data->wait_to_release_ms = wait_to_release_ms;

    int result = pthread_create(thread, NULL, threadfunc, data);
    if (result != 0)
    {
        free(data);
        return false;
    }

    return true;
}

