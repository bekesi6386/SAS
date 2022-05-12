%macro lock(table, timeout= 3600);
    %if %sysevalf(%superq(table)=, boolean) eq %then %do;
        %put The TABLE parameter is strict!;
        %goto exit;
    %end;

    %local start dsid rc;

    %let start = %sysfunc(datetime());

    %do %until(&syslckrc. <= 0 or %sysevalf(%sysfunc(datetime()) > (&start. + &timeout.)));
        %let dsid = %sysfunc(open(&table.));
        %if &dsid. lt 0 %then %do;
            %put Could not open the table!; 
            %goto exit;
        %end; 

        %let rc = %sysfunc(close(&dsid.));

        lock &table. NOMSG; *supress the ERROR, just NOTES;
    %end;

    %exit:
        %put The &sysmacroname. is exiting.;
%mend lock;
/*
%lock(S_IFRS.M_JUT_AMORT_CF_IFRS)
%lock(SASHELP.CLASS)
*/
