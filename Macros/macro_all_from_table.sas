%macro macro_all_from_table(dsn);
    %if (%bquote(&dsn.) eq ) %then %do;
        %put;
        %put There is no data set name parameter!;
        %put The &=sysmacroname is exiting.;
        %goto exit;
    %end;

    data _null_;
        set &dsn.;

        array char_array {*} $ _character_;
        array num_array {*} _numeric_;

        do i=1 to dim(char_array);
            call symputx(catt(vname(num_array[i]), _N_),  num_array[i], 'L');
        end;

        do j=1 to dim(num_array);
            call symputx(catt(vname(num_array[j]), _N_),  num_array[j], 'L');
        end;
    run;

    %put _local_;

    %exit:

%mend macro_all_from_table;

/*
%macro_all_from_table()
%macro_all_from_table(sashelp.class)
*/
