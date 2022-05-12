/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Create a work/holiday calendar for the parameter year.
    Parameter: year: Calendar year.
               holidays: Holiday, Numeric SAS date list.
               holiday_exceptions: Working holiday, Numeric SAS date list.
               debug: default: NO
    Inner macro call: %put_params_to_log
                      %parameter_check
                      %libname_assign
                      %libnames_deassign
    Created at: 2022.04.04.
    Modified at: 

    Use cases:
        options mprint mlogic;

        1:  %make_calendar(2022
                           , '01jan2022'd    '15mar2022'd    '15apr2022'd    '17apr2022'd   '18apr2022'd    
                             '01may2022'd    '06jun2022'd    '20aug2022'd    '23oct2022'd   '01nov2022'd    
                             '25dec2022'd    '26dec2022'd

                           , '14mar2022'd    '26mar2022'd    '15oct2022'd    '31oct2022'd
                           , debug= YES)
**/

%macro make_calendar(year, holidays, holiday_exceptions, debug=NO) / minoperator     
                                                                     mindelimiter= ' ';
    /* print params and values to log */
    %put_params_to_log(make_calendar)

    %local start_time end_time mprint_option msglevel_option param_err libname_err i holiday holiday_exception
           holidays_cnt holiday_exceptions_cnt
    ;

    %let start_time      = %sysfunc(datetime()); 
    %let mprint_option   = %sysfunc(getoption(MPRINT));
    %let msglevel_option = %sysfunc(getoption(MSGLEVEL));

    options mprint msglevel=I;

    /* year check */
    %parameter_check(year, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    %if (%length(&year.) ne 4) %then %do;
        %put There is something wrong with the year parameter! (&=year);
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* holidays check */
    %parameter_check(holidays, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    %let holidays_cnt = %sysfunc(countw(&holidays., %str( )));

    %do i=1 %to &holidays_cnt.;
        %let holiday = %scan(&holidays., &i., %str( ));

        %parameter_check(holiday, DATE_NUM, param_err)
        %if (&param_err.) %then %do;
            %put The %upcase(&sysmacroname.) is exiting...;
            %put;
            %goto eom_param_err;
        %end;
    %end;

    /* holiday_exceptions check */
    %parameter_check(holiday_exceptions, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    %let holiday_exceptions_cnt = %sysfunc(countw(&holiday_exceptions., %str( )));

    %do i=1 %to &holiday_exceptions_cnt.;
        %let holiday_exception = %scan(&holiday_exceptions., &i., %str( ));

        %parameter_check(holiday_exception, DATE_NUM, param_err)
        %if (&param_err.) %then %do;
            %put The %upcase(&sysmacroname.) is exiting...;
            %put;
            %goto eom_param_err;
        %end;
    %end;

    /* DEBUG check */
    %let debug = %upcase(&debug.);

    %if NOT (%bquote(&debug.) IN (NO YES)) %then %do;
        %put The debug must be in the list: (YES, NO)! (&=debug);
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* libname conn. */
    %libname_assign(adatelem, , libname_err, sqlsvr, KIRDBS03, ADATELEMZES, dbo)
    %if (&libname_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_lib_con_err;
    %end;

    %if (&debug. eq NO) %then %do;
        %if %sysfunc(exist(adatelem.CALENDAR_&year.)) %then %do;
            proc sql;
                drop table adatelem.CALENDAR_&year.;
            quit;
        %end;
    %end;

    /* type: W: workday H: holiday */
    data %if (&debug. eq NO) %then adatelem; %else work; .CALENDAR_&year. (keep= date weekday type);
        attrib i       length= 8
               date    length= 8  format= datetime21.
               weekday length= $1
               type    length= $1 
        ;

        array holidays           (&holidays_cnt.)           _temporary_ (&holidays.);
        array holiday_exceptions (&holiday_exceptions_cnt.) _temporary_ (&holiday_exceptions.);

        do i= "01jan&year."d to "31dec&year."d;
            type = '';

            weekday = put(sum(weekday(i), -1), 1.);

            if (weekday eq '0') then do;
                weekday = '7';
            end;

            if (i in holidays or weekday in ('6' '7')) then do;
                type = 'H';
            end;

            if (missing(type) or i in holiday_exceptions) then do; 
                type = 'W';
            end;

            date = dhms(i, 0, 0, 0);

            output;
        end;

        stop;
    run;

    %if (&debug. eq NO) %then %do;
        proc sql;
            connect to sqlsvr (noprompt="server=KIRDBS03;DRIVER=SQL Server;Trusted Connection=yes;");

            execute(CREATE INDEX hitreg_azonosito ON adatelemzes.dbo.CALENDAR_&year. (date)) by sqlsvr;

            disconnect from sqlsvr;
        quit;
    %end;

    %libnames_deassign(adatelem)

    %let end_time = %sysfunc(datetime());
    %put ************;
    %put RUN TIME: %sysfunc(putn(%sysevalf(&end_time. - &start_time.), time11.2));
    %put ************;

    %eom_lib_con_err:
    %eom_param_err:
        options &mprint_option. msglevel=&msglevel_option.;

%mend make_calendar;
