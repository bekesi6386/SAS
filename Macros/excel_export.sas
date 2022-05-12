/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Export the dataset to an excel (sheet).
    Parameter: inset: The data set name.
               outfile: The full path and excel filename.
               sheetname: optional - The excel sheet name. 
                          If the parameter is null, the NEWFILE= YES; option is added!
               dbms: Database Management Systems
                     default: xlsx
    Inner macro call: %put_params_to_log
                      %parameter_check
                      %delete_file
    Created at: 2021.07.14.
    Modified at: 2021.09.20. - Default DBMS parameter.
                 2021.10.27. - If the .bak file exist, delete at the end.
                             - %parameter_check() macro call at the beginning.
                 2022.01.12. - Header fix
                             - %put_params_to_log use

    Use cases:
        options mprint mlogic;

        1:  %excel_export(sashelp.class
                          , \\srv3\users$\bekesid\proba.xlsx
                          , CLASS
                          , dbms= excel)
        2:  %excel_export(sashelp.class
                          , \\srv3\users$\bekesid\proba.xlsx
                          , CLASS)
        3:  %excel_export(sashelp.class
                          , \\srv3\users$\bekesid\proba.xlsx)
**/

%macro excel_export(inset, outfile, sheetname, dbms= xlsx) / minoperator     
                                                             mindelimiter= ' ';

    /* print params and values to log */
    %put_params_to_log(excel_export)

    %local param_err;

    %parameter_check(inset, TABLE_EXIST, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto param_err;
    %end;

    %parameter_check(outfile, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto param_err;
    %end;

    proc export outfile= "&outfile."
                data= &inset.
                dbms= &dbms.
                replace
                ;
                %if (%bquote(&sheetname.) ne) %then %do;
                    sheet= "&sheetname.";
                %end;
                %else %do;
                    newfile= yes;
                %end;
    run;

    %if (&syserr. IN (0 4)) %then %do;
        %put;
        %put The excel file (&=outfile) successfully created!;
        %put;
    %end;
    %else %do;
        %put;
        %put There was a problem while creating the excel file (&=outfile)!;
        %put;
    %end;

    %if (%sysfunc(fileexist(&outfile..bak))) %then %do;
        %delete_file(&outfile..bak)
    %end;

    %param_err:

%mend excel_export;
