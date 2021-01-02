%macro distinctlist(list, result);
    %if %sysevalf(%superq(list)=, boolean) %then %do;
        %put;
        %put The LIST parameter is missing!;
        %put The &=sysmacroname is exiting.;
        %goto exit;
    %end;

    %local distinct_list i;

    %let distinct_list = %scan(&list., 1, %str( ));

    %let i = 2;

    %do %while(%scan(&list., &i., %str( )) ne %str());
        %if %sysfunc(indexw(&distinct_list., %scan(&list., &i., %str( )))) eq 0 %then %do;
            %let distinct_list = &distinct_list. %scan(&list., &i., %str( ));
        %end;

        %let i = %eval(&i.+1);
    %end;

    %if %bquote(&result.) ne %then %let &result. = &distinct_list.;
    %else %do;
        &distinct_list.
    %end;

    %exit:
%mend distinctlist;

/*
%macro test;
    %local test;

    %distinctlist();
    
    %distinctlist(a b c d a b, test);

    %put &=test;

    %put %distinctlist(a b c d a b);
%mend test;
%test

*/
