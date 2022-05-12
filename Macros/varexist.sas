%macro varexist(dsn, varlist);
    %if %bquote(&dsn.) eq or not (%sysfunc(exist(&dsn., DATA)) or %sysfunc(exist(&dsn., VIEW))) %then %do;
        %put The &=dsn is not exist or the value is NULL - %sysfunc(sysmsg());
        %put The &sysmacroname. is exiting...;
        %goto exit;
    %end;

    %local dsid varcnts i missing_varnames rc ok;

    %let dsid = %sysfunc(open(&dsn., i));
    %if not &dsid. %then %do;
        %put The &dsn. can not be opened - %sysfunc(sysmsg());
        %put The &sysmacroname. is exiting...;
        %goto exit;
    %end;

    %let i = 1;

    %do %while(%scan(&varlist., &i.) ne %str());
        %if %sysfunc(varnum(&dsid., %scan(&varlist., &i.))) = 0 %then %do;
            %let missing_varnames = &missing_varnames. %scan(&varlist., &i.);
        %end;

        %let i = %eval(&i. + 1);
    %end;

    %if &missing_varnames. eq %then %let ok = 1;
    %else %do;
        %let ok = 0;
        %put These are the variables that are not in the data set: &missing_varnames. ;
    %end;

    &ok.

    %let rc = %sysfunc(close(&dsid.));

    %exit:
%mend varexist;

/*
%macro a;
    %local abc;
    %let abc = %varexist(sashelp.cars, typee);
    %put &=abc;
%mend a;
%a

%macro b;
    %local abc;
    %let abc = %varexist(sashelp.cars, type);
    %put &=abc;
%mend b;
%b
*/
