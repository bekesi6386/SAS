%macro split_ds_vertical(dsn, rootname= dummy, splitcnt= 2); %macro dummy; %mend dummy;
    %if %bquote(&dsn.) eq or not (%sysfunc(exist(&dsn., DATA)) or %sysfunc(exist(&dsn., VIEW))) %then %do;
        %put The &=dsn is not exist or the value is NULL - %sysfunc(sysmsg());
        %put The &sysmacroname. is exiting...;
        %goto exit;
    %end;

    %local dsid i j k varcounts rc;

    %if &rootname. eq %then %put The output names will start with the dummy word;
    %if %length(%bquote(&rootname.)) ge 32 %then %let rootname = %substr(&rootname., 1, %eval(%length(&rootname.)-%length(&splitcnt.)));

    %let dsid = %sysfunc(open(&dsn.));
    %if not &dsid.%then %do;
        %put The data set can not be opened!;
        %put The &=sysmacroname is exiting;
        %goto exit;
    %end;

    %let varcounts = %sysfunc(attrn(&dsid., nvar));
    %if &varcounts. eq %then %do;
        %put There is no variable in the data set!;
        %put The &=sysmacroname is exiting;
        %goto exit;
    %end;
    %else %do;
        %do i = 1 %to &varcounts.;
            %local vars&i.;

            %let vars&i. = %sysfunc(varname(&dsid., &i.));
            %put &&vars&i..;
        %end;
    %end;
    %let rc = %sysfunc(close(&dsid.));

    %let cnteach = %sysevalf(&varcounts./&splitcnt., ceil);

    data 
        %do j = 1 %to &splitcnt.;
            %put &rootname&j.;
            &rootname&j. (keep= 
                %do k = %eval((&j.-1) * &cnteach. + 1) %to %sysfunc(min(&varcounts., %eval(&j. * &cnteach.)));
                    &&vars&k..
                %end; 
                        )
        %end;
        ;
        set &dsn.;
    run;

    %exit:
%mend split_ds_vertical;

/*
%split_ds_vertical(sashelp.cars, rootname= abc, splitcnt= 6)
*/
