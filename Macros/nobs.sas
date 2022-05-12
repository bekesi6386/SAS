/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Return the number of logical (undeleted) observations.
    Parameter: dsn: Data Set name with or without library reference.
               result: optional - macro variable result
    Created at: 2019.02.20.
    Modified at: 2021.09.20. - get the obs count from a RDBMS table too (%sysfunc(dosubl))
                 2022.03.24. - SQLSVR usage

    Use cases:
        options mprint mlogic;

        1:  data work.a;
                do i= 1 to 100;
                    output;
                end;
                stop;
            run;

            data work.b;
                nobs = %nobs(work.a);
            run;
        2:  %macro obs_count;
                %local obs_count;

                %nobs(a, obs_count)

                %put &=obs_count;
            %mend obs_count;

            %obs_count
        3:  libname adatelem SQLSVR noprompt="driver=SQL Server;server=KIRDBS03;database=ADATELEMZES;Trusted_Connection=yes" schema=dbo;
            %put OBS COUNT: %nobs(adatelem.intezmeny_kat);
**/

%macro nobs(dsn, result);
    %if %bquote(&dsn.) eq or not (%sysfunc(exist(&dsn., DATA)) or %sysfunc(exist(&dsn., VIEW))) %then %do;
        %put The &=dsn is not exist or the value is NULL - %sysfunc(sysmsg());
        %put The &sysmacroname. is exiting...;
        %put;
        %goto exit;
    %end;

    %local dsid rc;

    %let dsid = %sysfunc(open(&dsn.));
    %if not &dsid. %then %do;
        %put The &dsn. can not be opened - %sysfunc(sysmsg());
        %put The &sysmacroname. is exiting...;
        %put;
        %goto exit;
    %end;

    %let nobs = %sysfunc(attrn(&dsid., NLOBS));
    %let rc   = %sysfunc(close(&dsid.));

    %if (%bquote(&nobs.) eq -1) %then %do;
        %let rc = %sysfunc(dosubl(%str(proc sql noprint;
                                           select count(*)
                                           into :nobs   TRIMMED
                                           from &dsn.
                                           ;
                                       quit;
                                      )));
    %end;
    
    %if (%bquote(&result.) ne) %then %do;
        %let &result. = &nobs.;
    %end;
    %else %do;
        &nobs.
    %end;

    %exit:
%mend nobs;
