/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Delete a file.
    Parameter: filename: The full path and file name.
    Inner macro call: %put_params_to_log
                      %parameter_check
    Created at: 2021.09.90.
    Modified at: 2022.01.12. - Header fix
                             - %parameter_check use

    Use cases:
        options mprint mlogic;

        1:  %delete_file(\\srv3\users$\bekesid\isin_list.csv)
**/

%macro delete_file(filename);
    /* print params and values to log */
    %put_params_to_log(delete_file)

    %local param_err;

    /* filename check */
    %parameter_check(filename, FILE_EXIST, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_no_file_to_delete;
    %end;

    data _null_;
        fname = 'delete';
        rc = filename(fname, "&filename.");
        rc = fdelete(fname);
        if (rc ne 0) then do;
            put / 'There was a problem while deleting the file!' /;
        end;
        rc = filename(fname);
    run;

    %eom_no_file_to_delete:
%mend delete_file;