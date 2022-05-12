%macro close_all_viewtables / des= 'Close all the viewtables';
    %local i;

    %do i=1 %to 30;
        dm 'next viewtable:;end;';
    %end;
%mend close_all_viewtables;

%close_all_viewtables
