%macro rename_lib_members_dread(lib= work, test= no) /des= 'Rename all membernames inside a called library using filename pipe.'; %macro dummy; %mend dummy;
    %*You can not call the macro inside a data or proc step!;

    options &test.mprint &test.mlogic &test.symbolgen;

    %local filrf rc dsid counts dsn new_name name;

    %let filrf = mydata;
    %let rc    = %sysfunc(filename(filrf, %sysfunc(pathname(&lib.))));
    %let dsid  = %sysfunc(dopen(&filrf.));

    %let counts = %sysfunc(dnum(&dsid.));

    %if &counts. eq %then %do;
        %put The query did not select rows. Maybe the library is empty.;
        %put The &=sysmacroname. is exiting;
        %goto exit;
    %end;
    
    proc datasets nolist nodetails lib= &lib.;
        %do i=1 %to &counts.;
            %let dsn = %sysfunc(dread(&dsid., &i.));

            %if %scan(&dsn., 2, %str(.)) eq sas7bdat %then %do;
                %let name = %scan(&dsn., 1, %str(.));

                %if %length(&name.) ge 32 %then %let new_name = %substr(&name., 1, 31)_;
                                          %else %let new_name = &name._;

                %if not %sysfunc(exist(&new_name., DATA)) %then %do;
                    change &name. = &new_name.;
                %end;
                %else %put The new table &new_name. is already exist.;
            %end;
        %end;
    run;
    quit;

    %exit:
%mend rename_lib_members_dread;

/*
%rename_lib_members_dread(lib= work)
*/
