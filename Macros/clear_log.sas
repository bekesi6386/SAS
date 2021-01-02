%macro clear_log(dirpath= , dayskeep= 180, ext= log);
    %if (%bquote(&dirpath.) eq) %then %do;
        %put The dirpath parameter is missing!;
        %put The %upcase(&=sysmacroname) is exiting!;
        %goto exit;
    %end;
    %if (%bquote(&dayskeep.) lt 0) %then %do;
        %put The dayskeep parameter must be positive!;
        %put The %upcase(&=sysmacroname) is exiting!;
        %goto exit;
    %end;
    %if (%upcase(%bquote(&ext.)) ne LOG) %then %do;
        %put The ext parameter must be in LOG type extension!;
        %put The %upcase(&=sysmacroname) is exiting!;
        %goto exit;
    %end;

    %put The %upcase(&sysmacroname.) process has started.;

    options nomprint nomlogic nosymbolgen;

    %local deldate rc did i memname moddate indir inmem;

    %let deldate = %eval(%sysfunc(today()) - &dayskeep.);
    %let rc      = %sysfunc(filename(indir, %bquote(&dirpath.)));
    %let did     = %sysfunc(dopen(&indir.));

    %put DELDATE = %sysfunc(putn(&deldate., yymmddn8.));

    %if (&did.) %then %do i= 1 %to %sysfunc(dnum(&did.));

        %let memname = %sysfunc(dread(&did., &i.));

        %if %scan(&memname., 2, %str(.)) eq &ext. %then %do;
            %let rc  = %sysfunc(filename(inmem, %bquote(&dirpath.)\&memname.));
            %let fid = %sysfunc(fopen(&inmem.));

            %if (&fid.) %then %do;
                %let moddate = %sysfunc(inputn(%sysfunc(finfo(&fid., Last Modified)), date9.));
                %let rc      = %sysfunc(fclose(&fid.));

                %if (%bquote(&moddate.) ne) and (%bquote(&moddate.) ne .) %then %do;
                    %if %eval(&moddate. < &deldate.) %then %do;
                        %put &=memname;
                        %put MODDATE: %sysfunc(putn(&moddate., yymmddn8.));
                        %let rc = %sysfunc(fdelete(&inmem.));
                    %end;
                %end;
            %end;
        %end;
    %end;

    %let rc = %sysfunc(dclose(&did.));
    %let rc = %sysfunc(filename(&inmem.));
    %let rc = %sysfunc(filename(&indir.));

    %exit:
%mend clear_log;

/*
%clear_log(dirpath=e:\SAS_RELEASE\TST\2020-02-19\Logs)
%clear_log(dirpath=e:\SAS_Logs\)
*/

