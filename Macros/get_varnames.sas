%macro get_varnames(dsn, result); %macro dummy; %mend dummy;
    %if %bquote(&dsn.) eq or not (%sysfunc(exist(&dsn., DATA)) or %sysfunc(exist(&dsn., VIEW))) %then %do;
        %put The &=dsn is not exist or the value is NULL - %sysfunc(sysmsg());
        %put The &sysmacroname. is exiting...;
        %goto exit;
    %end;

    %local dsid i varcounts varnames rc;

    %let dsid = %sysfunc(open(&dsn.));
    %if not &dsid. %then %do;
        %put The data set can not be opened!;
        %put The &=sysmacroname is exiting;
        %goto exit;
    %end;

    %let varcounts = %sysfunc(attrn(&dsid., NVARS));
    %if &varcounts. eq %then %do;
        %put There is no variable in the data set!;
        %put The &=sysmacroname is exiting;
        %goto exit;
    %end;
    %else %do;
        %do i = 1 %to &varcounts.;
            %let varnames = &varnames. %sysfunc(varname(&dsid., &i.));
        %end;
        %let varnames = &varnames.;
    %end;
    %let rc = %sysfunc(close(&dsid.));

    %if %bquote(&result.) ne %then %let &result. = &varnames.;
    %else %do;
        &varnames.
    %end;

    %exit:
%mend get_varnames;

/*
data a;
    abc = "%get_varnames(sashelp.cars)";
    put abc=;
run;

%macro a;
    %local abc;

    %get_varnames(sashelp.cars, abc)

    %put &=abc;
%mend a;
%a
*/
