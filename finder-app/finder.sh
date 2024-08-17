#!/bin/sh

# This is a simple shell script

# Check if two argument are provided
if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <filesdir> <searchstr>"
	exit 1
fi

# Assign the first argument to the variable filesdir
filesdir="$1"

# Assign the second argument to the variable searchstr
searchstr="$2"

# check if filesdir represent a directory on the filesystem
if [ ! -d "$filesdir" ]; then
	echo "Error: '$filesdir' is not a directory."
	exit 1
fi

# Count the number of files in filesdir and its subdirectories
num_files=$(find "$filesdir" -type f | wc -l)

# Count the number of lines containing searchstr in filesdir and its subdirectories
num_lines=$(grep -r "$searchstr" "$filesdir" | wc -l)

# Display the assigned directories, the search string, and the number of matching lines
echo "Files Directory: $filesdir"
echo "Search String: $searchstr"
echo "Number of files: $num_files"
echo "Number of Lines: $num_lines"
echo "The number of files are $num_files and the number of matching lines are $num_lines"
