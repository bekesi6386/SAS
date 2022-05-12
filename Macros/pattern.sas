/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Return the string based on the specified pattern.
    Parameter: what: the string or list of strings
               how: the returned style
                    # is the element 
               delimiter: how to delimit the strings 
                          default: %str( )
    Inner macro call: %parameter_check
    Created at: 2019.02.20.
    Modified at: 2022.01.14. - Header fix
                             - %parameter_check use
                 2022.03.29. - %parameter_check delete: in dosubl() it shown error

    Use cases:
        options mprint mlogic;
        1:  data work.tmp_samle;
                %pattern(a b c, %bquote(length # 8;))
            run;

        2: data work.tmp_samle_2;
               set sashelp.class (where= (name in (%pattern(John Carol Henry, '#', %str(,)))));
           run;
**/

%macro pattern(what, how, delimiter);
    %local i element param_err;

    /* what check */
    %if (%bquote(&what.) eq) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto exit;
    %end;

    /* how check */
    %if (%bquote(&how.) eq) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto exit;
    %end;

    %if (%bquote(&delimiter.) eq) %then %let delimiter = %quote( );
    %else                               %let delimiter = %quote(&delimiter.);

    %let what = %quote(%sysfunc(compbl(&what.)));
    %let how  = %quote(%sysfunc(compbl(&how.))); 

    %do i=1 %to %sysfunc(countw(&what., %str( )));
        %let element = %qscan(&what., &i., %str( ));
        
        %if (&i. gt 1) %then %do;
            %quote(&delimiter.)
        %end;

        %sysfunc(tranwrd(%nrquote(&how.), %quote(#), %quote(&element.)))
    %end;

    %exit:
%mend pattern;
