/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Get the data table (and view) names from the given library. 
    Parameter: libname: Library name.
               result: optional - macro variable result
               view: optional - Default: NO
    Created at: 2022.05.11.
    Modified at:  

    Use cases:
        options mlogic;

        1:  data work.tmp_samle;
                abc = "%get_tablenames(work)";
                put abc=;
            run;

        2:  %macro test;
                %local abc;

                %get_tablenames(work, abc)

                %put &=abc;
            %mend test;
            %test

        3: %put %get_tablenames(work);
**/

%macro get_tablenames(libname, result, VIEW= NO) / minoperator
                                                   mindelimiter= ' '; 
    %if (%bquote(&libname.) eq ) %then %do;
        %put The &=libname value is NULL!;
        %put The &sysmacroname. is exiting...;
        %put;
        %goto exit;
    %end;

    %if (%length(&libname.) gt 8) %then %do;
        %put The &=libname length is more than 8 char! (LENGTH=%length(&libname.));
        %put The &sysmacroname. is exiting...;
        %put;
        %goto exit;
    %end;

    %let view = %upcase(&view.);

    %if NOT (%bquote(&view.) IN (YES NO)) %then %do;
        %put The VIEW parameter value must be in the list (YES | NO)! (&=view);
        %put The &sysmacroname. is exiting...;
        %put;
        %goto exit;
    %end;

    %local temp_memnames rc;

    %let libname = %upcase(&libname.);

    %if (&view. eq NO) %then %do;
        %let rc = %sysfunc(dosubl(%str(proc sql noprint;
                                       select distinct memname
                                       into :temp_memnames separated by ' '
                                       from dictionary.tables
                                       where libname eq "&libname."
                                               and memtype eq 'DATA'
                                       ;
                                   quit;
                                   )));
    %end;
    %else %do;
        %let rc = %sysfunc(dosubl(%str(proc sql noprint;
                                       select distinct memname
                                       into :temp_memnames separated by ' '
                                       from dictionary.tables
                                       where libname eq "&libname."
                                       ;
                                   quit;
                                   )));
    %end;

    %if (%bquote(&result.) ne) %then %let &result. = &temp_memnames.;
    %else %do;
        &temp_memnames.
    %end;

    %exit:
%mend get_tablenames;
