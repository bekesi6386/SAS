%macro odSet(dsname);
    %global dsid;
    %local rc;
    %let dsid = %sysfunc(open(&dsname.));
    %if &dsid. le 0 %then %do; 
        %put ERROR: %sysfunc(SysRc()) -- %sysfunc(SysMsg());
        %let rc = %sysfunc(close(&dsid.));
    %end;
    %else %do;
        %let dsname = %sysfunc(Dsname(&dsid.));
        %put The data set opened was &dsname. || odSet(DSID): &dsid.;
        %put NOTE: "Don't forget to CLOSE!";
    %end;
%mend odSet;

/*
%odSet(sashelp.cars)
*/
