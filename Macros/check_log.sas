/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Check a parameter log file for the given keyword(s).
    Parameter: log_full_path: The full path and log filename.
               output_table_name: The SAS output data set name. 
                                  Maximum library name length: 8 characters
                                  Maximum data set name length: 32 characters
               keywords: separated by ' ' and maximum length by keywords: 512 characters 
    Inner macro call: %put_params_to_log
                      %parameter_check
                      %nobs 
    Created at: 2022.01.05.
    Modified at: 2022.01.12. - Header fix

    Use cases:
        options mprint mlogic;

        1:  %check_log(\\srv2\MNB_IDM\Piac_adat_onal_oszt\Rendszeres_Riportok\Egyéb\tarhely_hasznalat\LOG\space_usage_report.sas.log
                       , work.checklog_table
                       , ERROR ERROR: WARNING WARNING:)

            %check_log(\\srv2\MNB_IDM\Piac_adat_onal_oszt\Rendszeres_Riportok\Egyéb\tarhely_hasznalat\LOG\space_usage_report.sas.log
                       , work.checklog_table
                       , XX)
**/

%macro check_log(log_full_path
                 , output_table_name
                 , keywords) / minoperator
                               mindelimiter= ' ';

    /* print params and values to log */
    %put_params_to_log(check_log)

    %local param_err i keyword output_dir_name output_table_name;

    /* log_full_path check */
    %parameter_check(log_full_path, FILE_EXIST, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* output_table_name check */
    %parameter_check(output_table_name, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    %if (%sysfunc(index(&output_table_name., %str(.))) gt 0) %then %do;
        %let output_dir_name   = %scan(&output_table_name., -2, %str(.));
        %let output_table_name = %scan(&output_table_name., -1, %str(.));
    %end;
    %else %do;
        %let output_dir_name   = work;
        %let output_table_name = &output_table_name.;
    %end;

    %if (%length(&output_dir_name.) gt 8) %then %do;
        %put;
        %put There output directory name (&=output_dir_name) is too long (%length(&output_dir_name.))!;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    %if (%length(&output_table_name.) gt 32) %then %do;
        %put;
        %put There output table name (&=output_table_name) is too long (%length(&output_table_name.))!;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* keywords check */
    %parameter_check(keywords, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    %let keywords = %upcase(&keywords.);

    filename logf "&log_full_path.";

    data &output_dir_name..&output_table_name. (keep= logline keyword logtext);
        infile logf end= done
                    lrecl= 32767
                    length= linelength
        ;

        length logline
               found   8
               keyword $512
        ;

        informat logtext $3000.;

        input logtext $varying3000. linelength;

        logline = _N_;
        logtext = upcase(compbl(strip(logtext)));
        found   = 0;

        %do i=1 %to %sysfunc(countw(&keywords., %str( )));
            %let keyword = %scan(&keywords., &i., %str( ));

            if findw(logtext, "&keyword") gt 0 then do;
                keyword  = "&keyword.";
                found    = 1;
            end;
        %end;

        if found;
    run;

    %if (%nobs(&output_dir_name..&output_table_name.) lt 1) %then %do;

        %if (%sysfunc(exist(&output_dir_name..&output_table_name.))) %then %do;
            proc datasets lib= &output_dir_name. nolist nodetails;
                delete &output_table_name.;
                run;
            quit;
        %end;

        %put;
        %put There were no found for these keywords: &keywords.;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
    %end;

    filename logf clear;

    %eom_param_err:

%mend check_log;
