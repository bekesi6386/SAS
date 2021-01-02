%macro log_session_test;
    proc printto log= 'C:\Users\user\log_session_test.log';
    run;

    %local i;

    data _null_;
        set sashelp.vmember (keep= libname memname memtype where= (upcase(memtype) eq 'DATA' 
                                                                   and upcase(libname) not in ('SASHELP' 'WORK' 'MAPS' 'MAPSGFK' 'MAPSSAS' 'SASUSER')))
                            end= done
        ;

        call symputx(catt('table_full_name', _N_), catx('.', libname, memname), 'L');
        if done then call symputx('counts', _N_, 'L');
    run;

    %put &=counts;

    %do i=1 %to 100;
        data _null_;
            if 0 then set &&table_full_name&i.. nobs= obs;
            call symputx('nobs', obs, 'L');
            stop;
        run;
            
        %if &nobs. gt 0 %then %do;
            %put &&table_full_name&i..;

            dm "vt &&table_full_name&i..";
            dm 'next viewtable:&&table_full_name&i..; end;';
        %end;
    %end;

    proc printto log= log;
    run;
%mend log_session_test;

%log_session_test
