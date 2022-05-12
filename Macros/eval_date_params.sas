/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Evaluate the macro date ('ddmmmyyyy'd or 22461) parameter to get just numeric (22461) date value.
           Why? : In batch mode run, the Compiler sees the date literals like characters and does not evaluate it.
    Parameter: date_params: date parameters delimited with commas.
    Inner macro call: %put_params_to_log
                      %parameter_check
    Created at: 2021.11.16.
    Modified at: 2022.01.12. - Header fix
                             - %put_params_to_log use

    Use cases:
        options mprint mlogic;

        1:  %macro abc(date1, date2);
                %eval_date_params(date1 date2)

                %put &=date1;
                %put &=date2;
            %mend abc;

            %abc('30jun2021'd, 22431)
**/

%macro eval_date_params(date_params);
    /* print params and values to log */
    %put_params_to_log(eval_date_params)

    %local i param_err;

    %parameter_check(date_params, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_no_input;
    %end;

    /* minimum one date parameter */
    %do i=1 %to %sysfunc(countw(&date_params., %str( )));
        %let date_param = %scan(&date_params., &i., %str( ));

        %if (%bquote(&date_param.) ne) %then %do;
            %let &date_param. = %sysevalf(&&&date_param);
        %end;

        %next_i:
    %end;

    %eom_no_input:
%mend eval_date_params;
