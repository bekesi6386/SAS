%macro nobs(dsn, result);
    %local dsid rc;

    %if %bquote(&dsn.) eq or not (%sysfunc(exist(&dsn., DATA)) or %sysfunc(exist(&dsn., VIEW))) %then %do;
        %put %sysfunc(sysrc()) - %sysfunc(sysmsg());
        %goto exit;
    %end;

    %let dsid = %sysfunc(open(&dsn.));
    %if (&dsid. le 0) %then %do;
        %put %sysfunc(sysrc()) - %sysfunc(sysmsg());
        %goto exit;
    %end;

    %let nobs = %sysfunc(attrn(&dsid., NLOBS));
    %let rc   = %sysfunc(close(&dsid.));

    %if %bquote(&result.) eq %then %do;
        &nobs.
    %end;
    %else %let result = &nobs.;

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
    set a;

    nobs = %nobs(a);
run;
*/
