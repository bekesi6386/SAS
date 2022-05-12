/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Create a directory.
    Parameter: directory_name: The full path with the new directory name.
                               Important: The parent directory must be exist!
    Inner macro call: %put_params_to_log
                      %parameter_check
    Created at: 2021.10.20.
    Modified at: 2022.01.12. - Header fix
                             - %put_params_to_log use
                 2022.01.24. - %bquote() usage in every "directory_name" macro variable 

    Use cases:
        options mprint mlogic;

        1:  %create_directory(\\srv3\users$\bekesid\proba_dir)
**/

%macro create_directory(directory_name);
    /* print params and values to log */
    %put_params_to_log(create_directory)

    %local param_err parent_directory new_directory_name;

    /* directory_name check */
    %parameter_check(directory_name, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_no_input;
    %end;

    /* C:\ */
    %if (%sysfunc(countw(%bquote(&directory_name.), %str(\))) eq 1) %then %do;
        %put Root directory name is INVALID!;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_no_input;
    %end;

    %let new_directory_name = %scan(%bquote(&directory_name.), -1, %str(\));

    /* C:\\ */
    %if (%bquote(&new_directory_name.) eq) %then %do;
        %put Directory name is a strict value!;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_no_input;
    %end;

    /* Extract new_directory_name from directory_name.  */
    %put &=directory_name;
    %put &=new_directory_name;
    %let parent_directory = %sysfunc(transtrn(%bquote(&directory_name.), %bquote(&new_directory_name.), %sysfunc(trimn(%str()))));

    /* OK: new dir path string 
       ERROR: empty string */
    %let rc = %sysfunc(dcreate(%bquote(&new_directory_name.), %bquote(&parent_directory.)));

    %if (%bquote(&rc.) eq) %then %do;
        %put The directory can not be created!;
        %put;
    %end;
    %else %do;
        %put The directory (&directory_name.) successfully created!;
        %put;
    %end;

    %eom_no_input:

%mend create_directory;
