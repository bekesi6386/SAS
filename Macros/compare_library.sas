%macro compare_library(lib= work) /minoperator;
    %local counts i memname_length new_name;

    data _null_;
        set sashelp.vmember (keep= libname memname memtype where= (libname = upcase("&lib.") and memtype = 'DATA')) end= done;
        call symputx(catt('memname',_N_), memname, 'L');
        if (done) then call symputx('counts', _N_, 'L');
    run;

    %if &counts. eq %then %do;
        %put The query did not select rows. Maybe the library is empty.;
        %goto exit;
    %end;
    
    proc datasets nolist nodetails lib= &lib.;
        %do i=1 %to &counts.;
            %let memname_length = %length(&&memname&i..);

            %if &memname_length. ge 32 %then %let new_name = %substr(&&memname&i.., 1, 31)_;
                                       %else %let new_name = &&memname&i.._;

            %if not %sysfunc(exist(&new_name., DATA)) %then %do;
                change &&memname&i.. = &new_name.;
            %end;
            %else %put The new table name is already exist.;
        %end;
    run;
    quit;

    %exit:
%mend compare_library;

/*
options mprint mlogic;
%compare_library(lib= work)
*/
