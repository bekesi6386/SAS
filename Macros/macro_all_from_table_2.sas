%macro macro_all_from_table_2(dsn) /minoperator;
    %if (%bquote(&dsn.) eq ) %then %do;
        %put;
        %put There is no data set name parameter!;
        %put The &=sysmacroname is exiting.;
        %goto exit;
    %end;

    %local dsid nobs i iterate rc;

    %let dsid = %sysfunc(open(&dsn., i));
    %if (&dsid. eq 0) %then %do;
        %put;
        %put The table could not be opened!;
        %put The &=sysmacroname is exiting.;
        %goto exit;
    %end;

    %let nobs = %sysfunc(attrn(&dsid., NLOBS));
    %if (&nobs. IN (0 .)) %then %do;
        %put;
        %put The table has no observation!;
        %put The &=sysmacroname is exiting.;
        %goto exit;
    %end;

    %syscall set(dsid);

    %do i=1 %to &nobs.;
        %let iterate = %sysfunc(fetchobs(&dsid., &i.));

        %put &=i.;

        %put _local_;
    %end;

    %let rc = %sysfunc(close(&dsid.));

    %exit:

%mend macro_all_from_table_2;

/*
%macro_all_from_table_2()
%macro_all_from_table_2(sashelp.class)
*/
