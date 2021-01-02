%macro subset_percent_point(dsn, key, percent) /des= 'Subset the percent observations from the data set by key.';
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

    proc sort data= &dsn.;
        by descending &key.;
    run;

    %put The &dsn. table is sorted by the &key. var!;

    data &dsn.;
        id_percent = ceil(nobs * &percent.);

        do point= 1 to id_percent;
            set &dsn. point= point nobs= nobs;
            output &dsn.;
        end;
        stop;
    run;

    %exit:
%mend subset_percent_point;

/*
%subset_percent_point(work.class, name, .25)
*/
