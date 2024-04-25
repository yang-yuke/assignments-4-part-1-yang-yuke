#include "systemcalls.h"
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <errno.h>

/**
 * @param cmd the command to execute with system()
 * @return true if the command in @param cmd was executed
 *   successfully using the system() call, false if an error occurred,
 *   either in invocation of the system() call, or if a non-zero return
 *   value was returned by the command issued in @param cmd.
*/
bool do_system(const char *cmd)
{

/*
 * TODO  add your code here
 *  Call the system() function with the command set in the cmd
 *   and return a boolean true if the system() call completed with success
 *   or false() if it returned a failure
*/
    int status = system(cmd);
    if(status == -1){
        //execution failure
        perror("system");
        return EXIT_FAILURE;
    }
    printf("command %s exited with status %d\n", cmd, status);
    return true;
}

/**
* @param count -The numbers of variables passed to the function. The variables are command to execute.
*   followed by arguments to pass to the command
*   Since exec() does not perform path expansion, the command to execute needs
*   to be an absolute path.
* @param ... - A list of 1 or more arguments after the @param count argument.
*   The first is always the full path to the command to execute with execv()
*   The remaining arguments are a list of arguments to pass to the command in execv()
* @return true if the command @param ... with arguments @param arguments were executed successfully
*   using the execv() call, false if an error occurred, either in invocation of the
*   fork, waitpid, or execv() command, or if a non-zero return value was returned
*   by the command issued in @param arguments with the specified arguments.
*/

bool do_exec(int count, ...)
{
    va_list args;
    va_start(args, count);
    char * command[count+1];
    int i;
    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
        printf("%s ",command[i]);
    }
    printf("\ncurrently in parent process %d , line %d\n", getpid(), __LINE__);
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    command[count] = command[count];

/*
 * TODO:
 *   Execute a system command by calling fork, execv(),
 *   and wait instead of system (see LSP page 161).
 *   Use the command[0] as the full path to the command to execute
 *   (first argument to execv), and use the remaining arguments
 *   as second argument to the execv() command.
 *
*/  
    if(count < 1){
        fprintf(stderr, "Usage: %s command [args...]\n", command[0]);
        return false;
    }

    fflush(stdout);

    // Fork a child process
    pid_t pid = fork();
    if(pid == -1){
        perror("fork");
        return false;
    }
    else if(pid == 0){//Child process
        //Execute the command in the child process
        if(execv(command[0], command) == -1){
            printf("do_exec, in child process %d, execv %s fail, will return errno %d to the parent process\n", getpid(), command[0], errno);
            printf("current in child process %d, line %d\n", getpid(), __LINE__);
            perror("do_exec, execv");
            exit (EXIT_FAILURE);
        }
    }
    else {//Parent process
        //Wait for the child process to terminate
        int status;
        if(waitpid(pid, &status, 0) == -1){
            printf("do_exec, in child process %d return with error\n", pid);
            printf("currently in parent process %d, child process is %d, line %d\n", getpid(), pid, __LINE__);
            perror("waitpid");
            return false;
        }

        printf("do_exec, currently in parent process %d, before checking child process %d exited %d, exit status %d, errno %d, status %d, line %d\n", getpid(), pid, WIFEXITED(status), (WEXITSTATUS(status) == 0), errno, status, __LINE__);

        return WIFEXITED(status) && (WEXITSTATUS(status) == 0);
    }
    va_end(args);

    return false;
}

/**
* @param outputfile - The full path to the file to write with command output.
*   This file will be closed at completion of the function call.
* All other parameters, see do_exec above
*/
bool do_exec_redirect(const char *outputfile, int count, ...)
{
    va_list args;
    va_start(args, count);
    char * command[count+1];
    int i;
    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    command[count] = command[count];


/*
 * TODO
 *   Call execv, but first using https://stackoverflow.com/a/13784315/1446624 as a refernce,
 *   redirect standard out to a file specified by outputfile.
 *   The rest of the behaviour is same as do_exec()
 *
*/
    if(count < 1){
        fprintf(stderr, "Usage: %s command [args...]\n", command[0]);
        return false;
    }

    // Fork a new process
    pid_t pid = fork();
    if(pid == -1){
        perror("fork");
        return false;
    }
    else if(pid == 0){//Child process
        int fd = open(outputfile, O_WRONLY|O_TRUNC|O_CREAT, 0666);
        if (fd == -1) {
            perror("open");
            return false;
        }

        // duplicate the standard output to the file specified by fd
        if (dup2(fd, STDOUT_FILENO) < 0) { 
            perror("dup2"); abort(); 
        }

        // Close the original file descriptor
        close(fd);

        //Execute the command in the child process
        if(execv(command[0], command) == -1){
            perror("do_exec_redirect, execv");
            return false;
        }
    }
    else {//Parent process
        
        //Wait for the child process to terminate
        int status;
        if(waitpid(pid, &status, 0) == -1){
            perror("waitpid");
            return false;
        }

        //Check if the child process terminated normally
        if(WIFEXITED(status)){
            printf("do_exec_redirect, Child process terminated with exit status: %d\n", WEXITSTATUS(status));
            return WEXITSTATUS(status) == 0;
        }
        else {
            printf("do_exec_redirect, Child process terminated abnormally\n");
            return false;
        }
    }

    va_end(args);

    return true;
}
