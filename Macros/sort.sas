%macro sort(dsn, by, out, dupout, uniqueout, nodupkey, force); %macro dummy; %mend dummy;
    %if %bquote(&dsn.) eq or %bquote(&by.) eq %then %do;
        %put No DSN or BY value!;
        %goto exit;
    %end;
    %if %sysfunc(countw(&dsn., %str(.))) eq 2 and %upcase(%scan(&dsn., 1, %str(.))) eq SASHELP and %bquote(&out.) eq %then %do;
        %put The user has no authorization to SASHELP!;
        %goto exit;
    %end;
    %if %sysfunc(exist(&dsn., VIEW)) %then %do;
        %put VIEW cannot be sorted!;
        %goto exit;
    %end;
    %if not %sysfunc(exist(&dsn., DATA)) %then %do;
        %put DATA is not exist!;
        %goto exit;
    %end;
    
    %local tagsort libname memname;

    /* OUT test */
    %if %bquote(&out.) ne %then %do;
        %if %sysfunc(countw(&out., %str(.))) eq 2 %then %do;
            %if %length(%scan(&out., 1, %str(.))) gt 8 %then %do;
                %put Output LIBRARY name is too long! It must be less equal 8.;
                %goto exit;
            %end; 
            %if %length(%sysfunc(trim(%scan(&out., 2, %str(.))))) gt 32 %then %do;
                %put Output DATA name is too long! It must be less equal 32.;
                %goto exit;
            %end;

            %let libname = %scan(&out., 1, %str(.));
            %let memname = %scan(&out., 2, %str(.));
        %end;
        %else %do;
            %let libname = WORK;

            %if %length(%sysfunc(trim(&out.))) gt 32 %then %do;
                %put Output DATA name is too long! It must be less equal 32.;
                %goto exit;
            %end;

            %let memname = &out.;
        %end;
    %end;

    /* DUPOUT test */
    %if %bquote(&dupout.) ne %then %do;
        %if %sysfunc(countw(&dupout., %str(.))) eq 2 %then %do;
            %if %length(%scan(&dupout., 1, %str(.))) gt 8 %then %do;
                %put Dupout LIBRARY name is too long! It must be less equal 8.;
                %goto exit;
            %end; 
            %if %length(%sysfunc(trim(%scan(&dupout., 2, %str(.))))) gt 32 %then %do;
                %put Dupout DATA name is too long! It must be less equal 32.;
                %goto exit;
            %end;

            %let libname = %scan(&dupout., 1, %str(.));
            %let memname = %scan(&dupout., 2, %str(.));
        %end;
        %else %do;
            %let libname = WORK;

            %if %length(%sysfunc(trim(&dupout.))) gt 32 %then %do;
                %put Dupout DATA name is too long! It must be less equal 32.;
                %goto exit;
            %end;

            %let memname = &dupout.;
        %end;
    %end;

    /* UNIQUEOUT test */
    %if %bquote(&uniqueout.) ne %then %do;
        %if %sysfunc(countw(&uniqueout., %str(.))) eq 2 %then %do;
            %if %length(%scan(&uniqueout., 1, %str(.))) gt 8 %then %do;
                %put Uniqueout LIBRARY name is too long! It must be less equal 8.;
                %goto exit;
            %end; 
            %if %length(%sysfunc(trim(%scan(&uniqueout., 2, %str(.))))) gt 32 %then %do;
                %put Uniqueout DATA name is too long! It must be less equal 32.;
                %goto exit;
            %end;

            %let libname = %scan(&uniqueout., 1, %str(.));
            %let memname = %scan(&uniqueout., 2, %str(.));
        %end;
        %else %do;
            %let libname = WORK;

            %if %length(%sysfunc(trim(&uniqueout.))) gt 32 %then %do;
                %put Uniqueout DATA name is too long! It must be less equal 32.;
                %goto exit;
            %end;

            %let memname = &uniqueout.;
        %end;
    %end;

    %let by = %quote(%sysfunc(compbl(&by.)));
    %if %sysfunc(countw(&by.)) gt 10 %then %let tagsort = 1;

    proc sort data= &dsn. 
        %if %bquote(&out.)       ne   %then out=       &libname..&memname.;
        %if %bquote(&dupout.)    ne   %then dupout=    &dupout.;
        %if %bquote(&uniqueout.) ne   %then uniqueout= &uniqueout.;
        %if &tagsort.            eq 1 %then tagsort;
        %if %bquote(&force.)     ne   %then force;
        %if %bquote(&nodupkey.)  ne   %then nodupkey;
        ;
        by &by.;
    run;

    %exit:
%mend sort;

/*
*options mprint mlogic symbolgen;
*options nomprint nomlogic nosymbolgen;
%sort(sashelp.class, age, work.yas, , , , force)
*/
