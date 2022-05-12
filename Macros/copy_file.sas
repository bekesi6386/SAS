/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Copy a file from source to destination.
    Parameter: src: The full path and file name from the source.
               result: The full path and file name to the destination.
    Inner macro call:
    Created at: 2021.05.12.
    Modified at: 2022.01.12. - Header fix
                             - %parameter_check use
                             - %put_params_to_log use

    Use cases:
        options mprint mlogic;

        1:  %copy_file(\\srv3\users$\bekesid\projects\50C_50W\riport\50C_50W.xlsx
                       , \\srv3\users$\bekesid\projects\50C_50W\riport\50C_50W_proba_copy.xlsx)
**/

%macro copy_file(src, dest) / des= 'Copy macro';
    /* print params and values to log */
    %put_params_to_log(copy_file)

    %local copy_rc param_err;

    /* src check */
    %parameter_check(src, FILE_EXIST, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_no_src;
    %end;

    filename src  "&src."  recfm=N;
    filename dest "&dest." recfm=N;

    data _null_;
        rc = fcopy('src', 'dest');
        call symputx('copy_rc', rc, 'L');
    run;

    %if (%bquote(&copy_rc.) ne 0) %then %do;
        %put;
        %put The copy did not work!;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom; 
    %end;
    %else %do;
        %put;
        %put The file was copied successfully!;
        %put SOURCE: &src.;
        %put DESTINATION: &dest.;
        %put;
    %end;

    %eom:
        filename src  clear;
        filename dest clear;
    %eom_no_src:
%mend copy_file;
