/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Create a distinct list from a list.
    Parameter: list: The list we want to make unique.
               result: optional - The unique list macro variable.
               delimiter: The NOT unique list delimiter.
    Inner macro call: %parameter_check
    Created at: 2021.04.21.
    Modified at: 2021.09.20. - Some information print.
                 2022.01.12. - Header fix
                             - %parameter_check use

    Use cases:
        options mprint mlogic;

        1:  %macro test;
                %local test;

                %distinctlist()
                
                %distinctlist(a b c d a b, test)

                %put &=test;

                %put %distinctlist(a b c d a b);

                %put %distinctlist(a#b#c#a#e#f#c, , #);
            %mend test;

            %test
**/

%macro distinctlist(list, result, delimiter) / des= 'Create a distinct list from a list';
    %local i list_item distinct_list param_err;

    /* output_table_name check */
    %parameter_check(list, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom;
    %end;

    %if (%bquote(&delimiter.) eq) %then %do;
        %let delimiter = %nrstr( );
    %end;

    %local i list_item distinct_list;

    %let distinct_list = %scan(&list., 1, %str(&delimiter.));

    %do i=2 %to %sysfunc(countw(&list., %str(&delimiter.)));
        %let list_item = %scan(&list., &i., %str(&delimiter.));

        %if (%sysfunc(indexw(&distinct_list., &list_item., %str(&delimiter.))) eq 0) %then %do;
            %let distinct_list = &distinct_list.%str(&delimiter.)&list_item.;
        %end;
    %end;

    %if %bquote(&result.) ne %then %do;
        %let &result. = &distinct_list.;
    %end;
    %else %do;
        &distinct_list.
    %end;

    %eom:
%mend distinctlist;
