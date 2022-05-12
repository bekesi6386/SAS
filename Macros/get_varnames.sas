/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Get the data set variable names. 
    Parameter: dsn: Data Set name with or without library reference.
               result: optional - macro variable result
    Created at: 2021.06.25.
    Modified at: 2021.09.20. 

    Use cases:
        options mprint mlogic;

        1:  data work.tmp_samle;
                abc = "%get_varnames(sashelp.cars)";
                put abc=;
            run;

        2:  %macro test;
                %local abc;

                %get_varnames(sashelp.cars, abc)

                %put &=abc;
            %mend test;
            %test
**/

%macro get_varnames(dsn, result); 
    %if %bquote(&dsn.) eq or not (%sysfunc(exist(&dsn., DATA)) or %sysfunc(exist(&dsn., VIEW))) %then %do;
        %put The &=dsn is not exist or the value is NULL - %sysfunc(sysmsg());
        %put The &sysmacroname. is exiting...;
        %put;
        %goto exit;
    %end;

    %local dsid i varcounts varnames rc;

    %let dsid = %sysfunc(open(&dsn.));
    %if not &dsid. %then %do;
        %put The data set can not be opened!;
        %put The &=sysmacroname is exiting;
        %put;
        %goto exit;
    %end;

    %let varcounts = %sysfunc(attrn(&dsid., NVARS));
    %if (&varcounts. eq) %then %do;
        %put There is no variable in the data set!;
        %put The &=sysmacroname is exiting;
        %put;
        %goto exit;
    %end;
    %else %do;
        %do i = 1 %to &varcounts.;
            %let varnames = &varnames. %sysfunc(varname(&dsid., &i.));
        %end;
        %let varnames = &varnames.;
    %end;
    %let rc = %sysfunc(close(&dsid.));

    %if (%bquote(&result.) ne) %then %let &result. = &varnames.;
    %else %do;
        &varnames.
    %end;

    %exit:
%mend get_varnames;
