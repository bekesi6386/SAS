%macro rename_lib_members_pipe(lib= work, test= no) /des= 'Rename all membernames inside a called library using filename pipe.'; %macro dummy; %mend dummy;
    %*You can not call the macro inside a data or proc step!;

    options &test.mprint &test.mlogic &test.symbolgen;

    %local libpath counts i memname_length new_name;

    %* automatically close the cmd windows;
    options noxwait xmin;

    %let libpath = %sysfunc(pathname(&lib.));

    %* /o:n =  sort the list files by name (alphabetic);
    %* /b = uses bare format (no heading information or summary, only the information itself);

    filename list pipe %tslit(dir "&libpath\*.sas7bdat" /o:n /b );

    data _null_;
        infile list truncover end= done;
        input fullname $41.;
        name = scan(fullname, 1, '.');
        call symputx(catt('dsn',_N_), name, 'L');
        if (done) then call symputx('counts', _N_, 'L');
    run;

    %if &counts. eq %then %do;
        %put The query did not select rows. Maybe the library is empty.;
        %put The &=sysmacroname. is exiting;
        %goto exit;
    %end;
    
    proc datasets nolist nodetails lib= &lib.;
        %do i=1 %to &counts.;
            %let memname_length = %length(&&dsn&i..);

            %if &memname_length. ge 32 %then %let new_name = %substr(&&dsn&i.., 1, 31)_;
                                       %else %let new_name = &&dsn&i.._;

            %if not %sysfunc(exist(&new_name., DATA)) %then %do;
                change &&dsn&i.. = &new_name.;
            %end;
            %else %put The new table &new_name. is already exist.;
        %end;
    run;
    quit;

    %exit:
%mend rename_lib_members_pipe;

/*
%rename_lib_members_pipe(lib= work)
*/
