#!/usr/bin/env python
'''
Extract unique Python exceptions from a log/text file.

Usage: filter_exceptions.py -f FILE [-e EXCEPTION_LIST]

-h --help           show help
-f FILE             file containing exceptions
-e EXCEPTION_LIST   comma delimited list of exceptions to filter
'''
import argparse

def read_exceptions(exception_file):
    '''
    Read the exceptions from a file

    Parameters
    ----------
    exception_file : str
        The OS path to the file containing exceptions

    Returns
    -------
    out : list[str]
        The list of strings containing the exceptions

    Raises
    ------
    IOError
        if the exception_file cannot be opened for reading
    '''
    processing_exception = False
    exception_buffer = ''
    error_list = []

    with open(exception_file, 'r') as f:
        for line in f:
            if 'Traceback' in line:
                processing_exception = True
            if processing_exception:
                exception_buffer += line
            if 'Error:' in line:
                processing_exception = False
                error_list.append(exception_buffer)
                exception_buffer = ''

    return error_list

def print_filtered_errors(error_list, exclude_list):
    '''
    Prints the filtered error list to std out

    Parameters
    ----------
    error_list : list[str]
        The list of tracebacks to be filtered
    exclude_list : str
        A comma delimited list of exceptions to exclude
    '''
    unique_errs = set(error_list)
    excludes = []
    if exclude_list:
        excludes = exclude_list.split(',')

    for err in unique_errs:
        if any([excl in err for excl in excludes]):
            continue
        print(err)

def main(exception_file, exclude_list):
    '''
    Simple main program to process and filter exception files

    Parameters
    ----------
    exception_file : str
        The OS path to the file containing exceptions
    exclude_list : str
        A comma delimited list of exceptions to exclude
    '''
    try:
        # Grab all the exception tracebacks from the file
        error_list = read_exceptions(exception_file)

        # Filter the tracebacks and dump them to stdout
        print_filtered_errors(error_list, exclude_list)

    except IOError as error:
        print('OS error: {0}'.format(error))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('-f', '--file', type=str, required=True, \
                        help='The file to extract exceptions from')

    parser.add_argument('-e', '--exclude', type=str, default='', \
                        help='Exclude certain exceptions from output.')

    args = parser.parse_args()

    main(args.file, args.exclude)
