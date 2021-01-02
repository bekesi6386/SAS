%macro modify_stmt(dsn_1, dsn_2, by);
    %if %bquote(&dsn_1.) eq 
        or not (%sysfunc(exist(&dsn_1., DATA)) or %sysfunc(exist(&dsn_1., VIEW))) 
        or %bquote(&dsn_2.) eq 
        or not (%sysfunc(exist(&dsn_2., DATA)) or %sysfunc(exist(&dsn_2., VIEW))) 
        or %bquote(&by.) eq %then %do;
        %put %sysfunc(sysrc()) - %sysfunc(sysmsg());
        %goto exit;
    %end;

    /* If it is sorted, you must validate also. */
    proc sort data= &dsn_1. (index= (&by.)) force; by &by.; run;
    proc sort data= &dsn_2.; by &by.; run;

    data &dsn_1.;
        modify &dsn_1. &dsn_2.;
        by &by.;
        
        select(_iorc_);
            when(%sysrc(_sok)) do;
                replace;
            end;
            when(%sysrc(_dsenmr)) do;
                output;
                _error_ = 0;
            end;
            otherwise do;
                put 'An unexpected I/O error has occured.';
                _error_ = 0;
                stop;
            end;
        end;
    run;

    %exit:
%mend modify_stmt;

/*
data elso;
    do i=1 to 1E6;
        b = sum(i, 5);
        output;
    end;
run;
data masodik;
    do i=1 to 1E3;
        b = sum(i,3);
        output;
    end;
run;

%modify_stmt(elso, masodik, i)
*/
