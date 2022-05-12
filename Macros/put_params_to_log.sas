/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Write the macro parameter names and values to the LOG in that form: name=value.
           IMPORTANT: Use this macro in the first line of the macro!
    Parameter: macro_name: The name of the macro.
    Created at: 2021.11.16.
    Modified at: 2021.11.18. - nobs check 
                 2022.01.18. - vmacro cut the macro values to 200 bytes - handling this
                             - %put details text around

    Use cases:
        options mprint mlogic;

        1:  %macro abc(param1, param2, param3);
                %put_params_to_log(abc)
            %mend abc;

            %abc(\\abc\def\ghi
                 , '30jun2021'd
                 , 3456)
**/

%macro put_params_to_log(macro_name);
    %local i param_err nobs;

    %parameter_check(macro_name, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_no_input;
    %end;

    %let macro_name = %upcase(&macro_name.);

    proc sql noprint;
        select count(*)
        into :nobs trimmed
        from sashelp.vmacro
        where scope eq "&macro_name."
        ;
    quit;

    %if (&nobs. lt 1) %then %do;
        %put There is no parameter for this macro (&macro_name.)!;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_no_param;
    %end;

    /* the vmacro is cutting the macro values to 200 bytes */
    data _null_;
        set sashelp.vmacro (keep= scope name value
                            where= (scope eq "&macro_name."))
                            end= done
        ;
        by scope name notsorted;

        length value_ret $32767
               macro_num 8
        ;

        retain value_ret;

        if (first.name) then do;
            value_ret = '';
            macro_num+1;
        end;

        value_ret = catx(' ', value_ret, compbl(value));

        if (last.name) then do;
            call symputx(cats('macro_local_var_', macro_num), cats(name, '=', value_ret), 'L');
        end;

        if (done) then do;
            call symputx('counts', macro_num, 'L');
        end;
    run;

    %put ********************************;
    %put The &macro_name. macro parameters are:;

    %do i= 1 %to &counts.;
        %put %bquote(&&macro_local_var_&i..);
    %end;

    %put ********************************;

    %eom_no_input:
    %eom_no_param:
%mend put_params_to_log;
