%macro dstomacrvar(dsn); %macro dummy; %mend dummy;
    %if %bquote(&dsn.) eq or not (%sysfunc(exist(&dsn., DATA)) or %sysfunc(exist(&dsn., VIEW))) %then %do;
        %put There is NO DSN parameter!;
        %goto exit;
    %end;

    %local nobs dsid i rc;
    
    %let nobs = %nobs(&dsn.);
    %let dsid = %sysfunc(open(&dsn.));

    %if (&dsid. eq 0) %then %do;
        %put The table can not be opened!;
        %goto exit;
    %end; 

    %syscall set(dsid);

    %do i=1 %to &nobs.;
        %let rc = %sysfunc(fetchobs(&dsid., &i.));
        %put _local_;
    %end;

    %let dsid = %sysfunc(close(&dsid.));

    %exit:
%mend dstomacrvar;

/*
%dstomacrvar(sashelp.class)
*/

