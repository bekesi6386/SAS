%macro log_error_check(dirpath= , env=, rundate=, ext= log) /des= 'If the LOG contains az ERROR send an email to the Administrator(s).';
    %* Author: BD; 
    %* Owner:  BD; 
    %* Created at: 2020.12.11.; 
    %* Version: 1.0; 

    %if %sysevalf(%superq(dirpath)=, boolean) %then %do;
        %put The dirpath parameter is missing!;
        %put The %upcase(&=sysmacroname) is exiting!;
        %goto exit;
    %end;
    %if %sysevalf(%superq(env)=, boolean) %then %do;
        %put The environment parameter is missing!;
        %put The %upcase(&=sysmacroname) is exiting!;
        %goto exit;
    %end;
    %if %sysevalf(%superq(rundate)=, boolean) %then %do;
        %put The rundate parameter is missing so it will be date()!;
        %let rundate = %sysfunc(date());
    %end;
    %if %sysevalf(%superq(ext)=, boolean) %then %do;
        %put The ext parameter must be in LOG type extension!;
        %put The %upcase(&=sysmacroname) is exiting!;
        %goto exit;
    %end;

    %put The %upcase(&sysmacroname.) process has started.;

    options nomprint nomlogic nosymbolgen;

    %let new_rundate = %sysfunc(putn(%bquote(&rundate.), yymmddn8.));

    /* PARAMETERS TO LOG */
    %put;
    %put &=new_rundate;
    %put &=dirpath;
    %put &=ext;

    /* We does not know the exact name for this LOG file */
    %macro get_filenames(location);
        filename _dir_ "%bquote(&location.)";

        data work.tmp_filenames (keep= memname);
            handle = dopen( '_dir_' );

            if handle gt 0 then do;
                counts = dnum(handle);

                do i= 1 to counts;
                  memname = dread(handle, i);

                  output;
                end;
            end;

            rc = dclose(handle);
        run;
        filename _dir_ clear;
    %mend get_filenames;

    %get_filenames(&dirpath.)

    data _null_;
        set work.tmp_filenames;
        if (index(memname, "sas_&env._ArchiveData_&new_rundate.") gt 0);
        call symputx('logfilename', memname, 'L');
    run;

    %put &=logfilename;

    data _null_;
        infile "&dirpath.\&logfilename." length= reclen end= done;
        input line $varying1024. reclen;

        if (index(line, 'ERROR') gt 0) then do;
            call symputx('error_line', line, 'L');
        end;
        else do;
            call symputx('error_line', 'NO_ERROR', 'L');
        end;
    run;

    %if %bquote(&error_line.) ne NO_ERROR %then %do;
        %sending_email_logcheck(%bquote(&error_line.))
    %end;

    proc datasets lib= WORK nolist nodetails;
        delete tmp_:;
        run;
    quit;

    %exit:
%mend log_error_check;

/*
%log_error_check(dirpath= C:\munka\Porsche\Archive_log_check, env= TEST, rundate= %sysfunc(date()), ext= LOG)
%log_error_check(dirpath= e:\SAS_Logs\, env= TEST, rundate=, ext= LOG)
%log_error_check(dirpath= e:\SAS_Logs\, env= TEST, rundate=%sysfunc(mdy(10,20,2020)), ext= LOG)
*/
