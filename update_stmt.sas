%macro update_stmt(dsn1, dsn2, by, missingcheck); %macro dummy; %mend dummy;
    %local dsn1_group dsn2_group by_group dsn1_obs dsn2_obs mode;    

    %if %bquote(&dsn1.) eq or %bquote(&dsn2.) eq or %bquote(&by.) eq 
        or not (%sysfunc(exist(&dsn1., DATA)) or %sysfunc(exist(&dsn1., VIEW)))
        or not (%sysfunc(exist(&dsn2., DATA)) or %sysfunc(exist(&dsn2., VIEW))) %then %do;

        %put %sysfunc(sysrc()) - %sysfunc(sysmsg());
        %goto exit;
    %end; 

    %if %sysfunc(countw(&by.)) gt 1 %then %let by_group = %sysfunc(tranwrd(&by., %str( ), %str(,)));
    %else                                 %let by_group = &by.;

    proc sql noprint;
        select count(*) into :dsn1_group trimmed from &dsn1. group by &by_group.;
        select count(*) into :dsn2_group trimmed from &dsn2. group by &by_group.;

        select count(*) into :dsn1_obs trimmed from &dsn1.;
        select count(*) into :dsn2_obs trimmed from &dsn2.;
    quit;

    %if %bquote(&dsn1_group.) gt 1 or %bquote(&dsn2_group.) gt 1 %then %do;
        %put The MASTER data set contains more than one observation for a BY group. The data sets must be unique for the BY value(s).; 
        %put &by. : &=dsn1_group &=dsn2_group;
        %put %sysfunc(sysrc()) - %sysfunc(sysmsg());
        %put The macro exiting because of errors.;
        %goto exit;
    %end;

    %if &dsn2_obs. gt &dsn1_obs. %then %put The second data set has more observations. Plus records will be added.;

    proc sort data= &dsn1.; by &by.; run;

    proc sort data= &dsn2.; by &by.; run;
    
    %if %upcase(%bquote(&missingcheck.)) eq NO %then %let mode = NOMISSINGCHECK;
    %else                                            %let mode = MISSINGCHECK;

    data &dsn1.;
        update &dsn1. &dsn2. updatemode= &mode.;
        by &by.;
    run;

    %exit:
%mend update_stmt;

/*
data elso;
    do i= 1 to 10;
        b = .;
        output;
    end;
run;

data masodik;
    do i= 5 to 10;
        b = i;
        output;
    end;
run;

%update_stmt(elso, masodik, i);
%update_stmt(elso, masodik, i, no);
*/
