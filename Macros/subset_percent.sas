%macro subset_percent(dsn, key, percent) /des= 'Subset the percent observations from the data set by key.'; 
    %if %bquote(&dsn.) eq or not (%sysfunc(exist(&dsn., DATA)) or %sysfunc(exist(&dsn., VIEW))) %then %do;
        %put The &=dsn is not exist or the value is NULL - %sysfunc(sysmsg());
        %put The &sysmacroname. is exiting...;
        %goto exit;
    %end;
    %if %bquote(&key.) eq %then %do;
        %put There is no key parameter!;
        %put The &sysmacroname. is exiting...;
        %goto exit;
    %end;

    %if %bquote(&percent.) eq %then %let percent = 1;

    %local subset_obs;

    proc sql noprint;
        select count(distinct &key.) * &percent. into :subset_obs from &dsn.;
    quit;

    proc sort data= &dsn.;
        by descending &key.;
    run;

    %put The &dsn. table is sorted by the &key. var!;

    data &dsn.;
        set &dsn. (obs= %sysevalf(&subset_obs., ceil));
    run;

    %exit:
%mend subset_percent;

/*
%subset_percent(work.class, name, .25)
*/
