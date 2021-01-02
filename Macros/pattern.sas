%macro pattern(what, how, delimiter);
    %if %bquote(&what.) eq or %bquote(&how.) eq %then %do;
        %put %sysfunc(sysrc()) - %sysfunc(sysmsg());
        %goto exit;
    %end;

    %local i element;

    %if %bquote(&delimiter.) eq %then %let delimiter = %quote( );
    %else                             %let delimiter = %quote(&delimiter.);

    %let what = %quote(%sysfunc(compbl(&what.)));
    %let how  = %quote(%sysfunc(compbl(&how.)));

    %do i=1 %to %sysfunc(countw(&what.));
        %let element = %qscan(&what., &i., %str( ));

        %sysfunc(tranwrd(%nrquote(&how.), %quote(#), %quote(&element.)))
    %end;

    %exit:
%mend pattern;

/*
options mprint;

data _null_;
    %pattern(a b c, %bquote(length # 8;))
run;
*/
