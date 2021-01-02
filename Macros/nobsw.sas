%macro nobsw(dsn);
    %if %bquote(&dsn.) eq or not (%sysfunc(exist(&dsn., DATA)) or %sysfunc(exist(&dsn., VIEW))) %then %do;
        %put %sysfunc(sysrc()) - %sysfunc(sysmsg());
        %goto exit;
    %end;

    %local dsid rc;

    %let dsid = %sysfunc(open(&dsn.));

    %if not &dsid. %then %do;
        %put %sysfunc(sysrc()) - %sysfunc(sysmsg());
        %goto exit;
    %end;

    %let nobs = %sysfunc(attrn(&dsid., NLOBS));
    %let rc   = %sysfunc(close(&dsid.));

    /* for pop up menu (right click on table) */
    %window obswnd color= white 
    #2 @5 "The data set observations number is: &nobs.";  
    %display obswnd;

    %exit:
%mend nobsw;

/*
options mprint mlogic;

*/
