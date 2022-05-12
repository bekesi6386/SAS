/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Get the current ISIN list and save to a SAS data table.
    Parameter: filename: The filename with the full path to save the isin_list file.
               outfile_name: The SAS proc import outset data set name.
               debug: default value: NO
                      If yes, it will print everything to the LOG about the http process 
                      and not delete the downloaded file.
    Inner macro call: %put_params_to_log
                      %parameter_check
                      %delete_file
    Created at: 2021.10.06.
    Modified at: 2022.01.12. - Header fix
                             - %put_params_to_log use
                 2022.03.10. - if debug= YES, then NOT %delete_file()
                             - debug must be YES or NO

    Use cases:
        options mprint mlogic;

        1:  %get_current_isin_list(\\srv3\users$\bekesid\isin_list.csv
                                   , work.tmp_isin_list)

        2:  %get_current_isin_list(\\srv3\users$\bekesid\isin_list.csv
                                   , work.tmp_isin_list (keep= 'ISIN kód'n deviza 'Névérték'n))

        3:  %get_current_isin_list(\\srv3\users$\bekesid\isin_list.csv
                                   , work.tmp_isin_list
                                   , debug= YES)

        4:  %get_current_isin_list(\\srv3\users$\bekesid\isin_list.csv
                                   , work.tmp_isin_list
                                   , debug= yes)
**/

%macro get_current_isin_list(filename, outfile_name, debug= NO) / minoperator 
                                                                  mindelimiter= ' ';
    /* print params and values to log */
    %put_params_to_log(get_current_isin_list)

    %local param_err rc filrf;

    %parameter_check(filename, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto param_err;
    %end;

    %parameter_check(outfile_name, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto param_err;
    %end;

    %let debug = %upcase(&debug.);

    %if NOT (%bquote(&debug.) IN (NO YES)) %then %do;
        %put The debug must be in the list: (YES, NO)! (&=debug);
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto param_err;
    %end;

    %let filrf = myfile;
    %let rc = %sysfunc(filename(filrf, &filename.));

    %if (&rc.) %then %do;
        %put;
        %put There was a problem with the filename command!;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto filename_err;
    %end;

    proc http url='https://www.keler.hu/isin.mvc/GetItemsCSV?filterItems='
              method='get' 
              out=&filrf.
              proxyhost='http://proxy2.mnb.hu'
              proxyport=8080;

              %if (%bquote(&debug.) eq YES) %then %do;
                  debug level=2;
              %end;
    run;

    %if NOT (&syserr. IN (0 4)) %then %do;
        %put;
        %put There was a problem while downloading the ISIN list!;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto isin_download_err;
    %end;

    proc import datafile= &filrf.
                out= &outfile_name.
                dbms= csv
                replace
                ;
                delimiter= ';';
                guessingrows= 40000;
    run;

    %if NOT (&syserr. IN (0 4)) %then %do;
        %put;
        %put There was a problem while importing the ISIN list!;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto isin_import_err;
    %end;
    %else %do;
        %put;
        %put The output table (&outfile_name.) successfully created!;
        %put;
    %end;

    %if (&debug. eq NO) %then %do;
        %delete_file(&filename.)
    %end;

    %isin_import_err:
    %isin_download_err:
        %let rc = %sysfunc(filename(filrf));

    %filename_err:
    %param_err:

%mend get_current_isin_list;
