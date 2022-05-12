%macro distinctlist(list, result, delimiter) / des= 'Create a distinct list from a list';
    %if (%sysevalf(%superq(list)=, boolean)) %then %do;
        %goto eom;
    %end;

    %if (%bquote(&delimiter.) eq) %then %do;
        %let delimiter = %nrstr( );
    %end;

    %local i list_item distinct_list;

    %let distinct_list = %scan(&list., 1, %str(&delimiter.));

    %do i=2 %to %sysfunc(countw(&list., %str(&delimiter.)));
        %let list_item = %scan(&list., &i., %str(&delimiter.));

        %if (%sysfunc(indexw(&distinct_list., &list_item., %str(&delimiter.))) eq 0) %then %do;
            %let distinct_list = &distinct_list.%str(&delimiter.)&list_item.;
        %end;
    %end;

    %if %bquote(&result.) ne %then %do;
        %let &result. = &distinct_list.;
    %end;
    %else %do;
        &distinct_list.
    %end;

    %eom:
%mend distinctlist;

/*
%macro test;
    %local test;

    %distinctlist()
    
    %distinctlist(a b c d a b, test);

    %put &=test;

    %put %distinctlist(a b c d a b);

    %put %distinctlist(a#b#c#a#e#f#c, , #);
%mend test;
%test
*/
