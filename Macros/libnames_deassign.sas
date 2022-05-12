/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Deassign the library references.
    Parameter: librefs: Required.
    Inner macro call: %put_params_to_log
                      %parameter_check
                      %pattern

    Created at: 2022.01.21.
    Modified at: 2022.01.27 - dictionary input instead of sashelp view

    Use cases:
        options mprint mlogic;

        1: libname x '\\srv2\MNB_IDM';
           libname y '\\srv2\MNB_IDM';
           libname z '\\srv2\MNB_IDM';

           %libnames_deassign(x y z)

        2: libname x '\\srv3\srv3';
           libname y '\\srv3\MNB_IDM';

           %libnames_deassign(x y)

        3: %libnames_deassign(a b c)
**/

%macro libnames_deassign(librefs) / minoperator
                                    mindelimiter= ',';

    /* print params and values to log */
    %put_params_to_log(libnames_deassign)

    %local param_err libnames i libname;

    /* librefs check */
    %parameter_check(librefs, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* exist check 
       distinct list */
    proc sql noprint;
        select distinct libname
        into :libnames separated by ' '
        from dictionary.libnames
        where libname IN (%pattern(%upcase(&librefs., %bquote('#'), %str( ))))
        ;
    quit;

    %if (%bquote(&libnames.) eq) %then %do;
        %put The value of the librefs macro parameter is not in the vslib view! (&=librefs);
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    %do i=1 %to %sysfunc(countw(&libnames., %str( )));
        %let libname = %scan(&libnames., &i., %str( ));

        libname &libname. clear;
    %end;

    %eom_param_err:

%mend libnames_deassign;
