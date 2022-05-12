%macro dsvarlist(dsn); %macro dummy; %mend dummy;
    %local dsid rc nvars i varlist;

    %if %bquote(&dsn.) eq or not (%sysfunc(exist(&dsn., DATA)) or %sysfunc(exist(&dsn., VIEW))) %then %do;
        %put %sysfunc(sysrc()) - %sysfunc(sysmsg());
        %goto exit;
    %end;

    %let dsid = %sysfunc(open(&dsn.));
    %if (&dsid. le 0) %then %do;
        %put %sysfunc(sysrc()) - %sysfunc(sysmsg());
        %goto exit;    
    %end;
    %else %do;
        %do i=1 %to %sysfunc(attrn(&dsid., nvars));
            %let varlist = &varlist. %sysfunc(varname(&dsid., &i.));
        %end;

        %do;
            %sysfunc(compbl(%bquote(&varlist.)))
        %end;
    %end;

    %let rc = %sysfunc(close(&dsid.));

    %exit:
%mend dsvarlist;

/*
examples:

data _null_;
    varlist = "%dsvarlist(sashelp.cars)";
    put varlist=;
run;
*/
