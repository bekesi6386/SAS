%macro nobs(dsn, result);
    %if %bquote(&dsn.) eq or not (%sysfunc(exist(&dsn., DATA)) or %sysfunc(exist(&dsn., VIEW))) %then %do;
        %put The &=dsn is not exist or the value is NULL - %sysfunc(sysmsg());
        %put The &sysmacroname. is exiting...;
        %goto exit;
    %end;

    %local dsid rc;

    %let dsid = %sysfunc(open(&dsn.));
    %if not &dsid. %then %do;
        %put The &dsn. can not be opened - %sysfunc(sysmsg());
        %put The &sysmacroname. is exiting...;
        %goto exit;
    %end;

    %let nobs = %sysfunc(attrn(&dsid., NLOBS));
    %let rc   = %sysfunc(close(&dsid.));
    
    %if %bquote(&result.) ne %then %let &result. = &nobs.;
    %else %do;
        &nobs.
    %end;

    %exit:
%mend nobs;

/*
options mprint mlogic;

data a;
    do i= 1 to 100;
        output;
    end;
run;

data c;
    nobs = %nobs(a);
run;

%macro a;
%local abc;
%nobs(a, abc)

%put &=abc;
%mend a;

%a
*/
