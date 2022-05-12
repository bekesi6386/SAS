/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Compare two tables by same columns.
    Parameter: table_names: exactly two table names with or without library
               by_values: minimum one variable name
               compared_table_name: exactly one table name with or without library
    Inner macro call: %put_params_to_log
                      %parameter_check
                      %get_varnames
                      %list_operator
                      %pattern
    Created at: 2021.12.22.
    Modified at: 2022.01.12. - Header fix
                 2022.01.25. - %pattern() macro usage in the alter table step
                 2022.05.10. - union_varnames length attribs before merge: compare column can be longer than the base column

    Use cases:
        options mprint mlogic;

        1:  data work.class;
                length sex $10;
                set sashelp.class;

                if (mod(_N_, 4) eq 0) then do;
                    delete;
                end;

                if (mod(_N_, 5) eq 0) then do;
                    output;
                end;

                if (mod(_N_, 3) eq 0) then do;
                    height = height + 5;
                    weight = weight + 1;
                    sex = 'XXXXX';
                end;

                i = _N_; 
                
                output;
            run;

            %compare_tables(sashelp.class work.class, name age, work.compared_classes)
**/

%macro compare_tables(table_names, by_values, compared_table_name) / minoperator mindelimiter= ' ';
    %put_params_to_log(compare_tables)

    %local param_err i base_table_full_name compare_table_full_name base_dir_name base_table_name compare_dir_name compare_table_name
           compared_table_dir_name compared_table_table_name base_varnames compare_varnames base_varname compare_varname by_value 
           to_rename_base_varnames from_rename_base_varname to_rename_compare_varnames from_rename_compare_varname union_varnames 
           except_base_varnames except_compare_varnames base_table_name_sort compare_table_name_sort columns_to_drop varname_length_counts
    ;

    /* proc sql into miatt */
    %do i=1 %to 200;
        %local union_varname_name_&i. union_varname_type_&i. union_varname_length_&i.;
    %end;

    %parameter_check(table_names, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto param_err;
    %end;

    %parameter_check(by_values, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto param_err;
    %end;

    %parameter_check(compared_table_name, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto param_err;
    %end;

    /* table_names countw */
    %if (%sysfunc(countw(&table_names., %str( ))) ne 2) %then %do;
        %put;
        %put There has to be two tables to compare! (&=table_names);
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto param_err;
    %end;

    %let base_table_full_name    = %scan(&table_names., 1, %str( ));
    %let compare_table_full_name = %scan(&table_names., 2, %str( ));

    /* directory and table name */
    %if (%sysfunc(index(&base_table_full_name., %str(.))) gt 0) %then %do;
        %let base_dir_name   = %scan(&base_table_full_name., -2, %str(.));
        %let base_table_name = %scan(&base_table_full_name., -1, %str(.));
    %end;
    %else %do;
        %let base_dir_name   = work;
        %let base_table_name = &base_table_full_name.;
    %end;

    %if (%sysfunc(index(&compare_table_full_name., %str(.))) gt 0) %then %do;
        %let compare_dir_name   = %scan(&compare_table_full_name., -2, %str(.));
        %let compare_table_name = %scan(&compare_table_full_name., -1, %str(.));
    %end;
    %else %do;
        %let compare_dir_name   = work;
        %let compare_table_name = &compare_table_full_name.;
    %end;

    /* table_names lengths */
    %if (%length(&base_table_name.) gt 17) %then %do;
        %let base_table_name_sort = %sysfunc(substrn(&base_table_name., 1, 17));
    %end;
    %else %do;
        %let base_table_name_sort = &base_table_name.;
    %end;

    %if (%length(&compare_table_name.) gt 17) %then %do;
        %let compare_table_name_sort = %sysfunc(substrn(&compare_table_name., 1, 17));
    %end;
    %else %do;
        %let compare_table_name_sort = &compare_table_name.;
    %end;

    /* compared_table_name */
    %if (%sysfunc(countw(&compared_table_name., %str( ))) gt 1) %then %do;
        %put;
        %put There has to be one outset table name! (&=compared_table_name);
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto param_err;
    %end;

    %if (%sysfunc(index(&compared_table_name., %str(.))) gt 0) %then %do;
        %let compared_table_dir_name   = %scan(&compared_table_name., -2, %str(.));
        %let compared_table_table_name = %scan(&compared_table_name., -1, %str(.));
    %end;
    %else %do;
        %let compared_table_dir_name   = work;
        %let compared_table_table_name = &compared_table_name.;
    %end;

    %if (%length(&compared_table_table_name.) gt 32) %then %do;
        %put;
        %put There compared table name (&=compared_table_name) is too long (%length(&compared_table_table_name.))!;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto param_err;
    %end;

    %put;
    %put ******** TABLES INFO ********;
    %put &=base_dir_name;
    %put &=base_table_name;
    %put &=base_table_name_sort;
    %put &=compare_dir_name;
    %put &=compare_table_name;
    %put &=compare_table_name_sort;
    %put &=compared_table_dir_name;
    %put &=compared_table_table_name;
    %put *****************************;
    %put;

    /* varnames */
    %get_varnames(&base_dir_name..&base_table_name., base_varnames)

    %if (%bquote(&base_varnames.) eq) %then %do;
        %put;
        %put The base table is empty! (&=base_varnames);
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto table_err;
    %end;

    %get_varnames(&compare_dir_name..&compare_table_name., compare_varnames)

    %if (%bquote(&compare_varnames.) eq) %then %do;
        %put;
        %put The compare table is empty! (&=compare_varnames);
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto table_err;
    %end;

    /* varnames length */
    %do i=1 %to %sysfunc(countw(&base_varnames., %str( )));
        %let base_varname = %scan(&base_varnames., &i., %str( ));

        %if (%length(&base_varname.) gt 30) %then %do;
            %put;
            %put The &=base_varname is too long to rename in the base table (&base_dir_name..&base_table_name.)!;
            %put The %upcase(&sysmacroname.) is exiting...;
            %put;
            %goto table_err;
        %end;
    %end;

    %do i=1 %to %sysfunc(countw(&compare_varnames., %str( )));
        %let compare_varname = %scan(&compare_varnames., &i., %str( ));

        %if (%length(&compare_varname.) gt 30) %then %do;
            %put;
            %put The &=compare_varname is too long to rename in the compare table (&compare_dir_name..&compare_table_name.)!;
            %put The %upcase(&sysmacroname.) is exiting...;
            %put;
            %goto table_err;
        %end;
    %end;

    /* by values */
    %do i=1 %to %sysfunc(countw(&by_values., %str( )));
        %let by_value = %scan(&by_values., &i., %str( ));

        %if (%sysfunc(findw(&base_varnames., &by_value., %str(~ ), I)) eq 0) %then %do;
            %put;
            %put The &=by_value is not in the base table (&base_dir_name..&base_table_name. | &=base_varnames)!;
            %put The %upcase(&sysmacroname.) is exiting...;
            %put;
            %goto table_err;
        %end;

        %if (%sysfunc(findw(&compare_varnames., &by_value., %str(~ ), I)) eq 0) %then %do;
            %put;
            %put The &=by_value is not in the compare table (&compare_dir_name..&compare_table_name. | &=compare_varnames)!;
            %put The %upcase(&sysmacroname.) is exiting...;
            %put;
            %goto table_err;
        %end;
    %end;

    /* compare varnames minus by_values */
    %let to_rename_base_varnames = %list_operator(EXCEPT, &base_varnames., &by_values.);

    %if (%bquote(&to_rename_base_varnames.) eq) %then %do;
        %put;
        %put No varnames to compare! (&=base_varnames | &=by_values);
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto table_err;
    %end;

    %let to_rename_compare_varnames = %list_operator(EXCEPT, &compare_varnames., &by_values.);

    %if (%bquote(&to_rename_compare_varnames.) eq) %then %do;
        %put;
        %put No varnames to compare! (&=compare_varnames | &=by_values);
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto table_err;
    %end;

    %let except_base_varnames    = %list_operator(EXCEPT, &base_varnames., &compare_varnames.);
    %let except_compare_varnames = %list_operator(EXCEPT, &compare_varnames., &base_varnames.);
    %let union_varnames          = %list_operator(EXCEPT
                                                  , %list_operator(UNION
                                                                   , &base_varnames.
                                                                   , &compare_varnames.)
                                                  , &by_values. &except_base_varnames. &except_compare_varnames.);

    %if (%bquote(&union_varnames.) eq ) %then %do;
        %put;
        %put No same varnames to compare! (&=to_rename_base_varnames | &=to_rename_compare_varnames);
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto table_err;
    %end;

    %put;
    %put ******** VARNAMES INFO ********;
    %put &=base_varnames;
    %put &=compare_varnames;
    %put &=by_values;
    %put &=to_rename_base_varnames;
    %put &=to_rename_compare_varnames;
    %put &=except_base_varnames;
    %put &=except_compare_varnames;
    %put &=union_varnames;
    %put *******************************;
    %put;

    /* get name, type, length attribs */
    proc sql noprint;
        select    coalesce(base.name, compared.name) as name
                , coalesce(base.type, compared.type) as type
                , max(base.length, compared.length)  as max_length
        into   :union_varname_name_1-       
             , :union_varname_type_1-       
             , :union_varname_length_1-     
        from dictionary.columns       as base
        inner join dictionary.columns as compared
        on upcase(base.name) = upcase(compared.name)
        where (upcase(base.name) in (%pattern(%upcase(&union_varnames.), %bquote('#'), %str(,)))
               and base.libname eq "%upcase(&base_dir_name.)"
               and base.memname eq "%upcase(&base_table_name.)")
              and 
              (upcase(compared.name) in (%pattern(%upcase(&union_varnames.), %bquote('#'), %str(,)))
               and compared.libname eq "%upcase(&compare_dir_name.)"
               and compared.memname eq "%upcase(&base_table_name.)")
        ;

        %let varname_length_counts = &sqlobs.;
    quit;
    
    /* sort the tables before merge */
    /* rename the variables */
    proc sort data= &base_dir_name..&base_table_name.
              out= work.&base_table_name_sort._bsr
                   (rename= (%do i=1 %to %sysfunc(countw(&to_rename_base_varnames., %str( )));
                                 %let from_rename_base_varname = %scan(&to_rename_base_varnames., &i., %str( ));

                                 &from_rename_base_varname. = &from_rename_base_varname._o
                             %end;
                   ))
              ;
        by &by_values.;
    run;

    proc sort data= &compare_dir_name..&compare_table_name.
              out= work.&compare_table_name_sort._csr
                   (rename= (%do i=1 %to %sysfunc(countw(&to_rename_compare_varnames., %str( )));
                                 %let from_rename_compare_varname = %scan(&to_rename_compare_varnames., &i., %str( ));

                                 &from_rename_compare_varname. = &from_rename_compare_varname._n
                             %end;
                   ))
              ;
        by &by_values.;
    run;

    /* compare */
    data &compared_table_dir_name..&compared_table_table_name. (where= ((row_type in ('DELETED' 'NEW'))
                                                                         or
                                                                        (%pattern(&union_varnames., %bquote((D_# eq 1)), %str(or)))));
        length table_from 
               row_type                $7
               var_is_diff      
               union_varnames_d_prefix $32000
        ;

        retain &by_values.
               %pattern(&union_varnames.,          %bquote(D_#), %str( ))
               %pattern(&union_varnames.,          %bquote(#_o #_n), %str( ))
               %pattern(&except_base_varnames.,    %bquote(#_o), %str( ))
               %pattern(&except_compare_varnames., %bquote(#_n), %str( ))
               var_is_diff
        ;

        /* compare column can be longer than the base column */
        %do i=1 %to &varname_length_counts.;
            length &&&union_varname_name_&i 
                   %if (&&&union_varname_type_&i eq char) %then %do;
                       $
                   %end;
                   &&&union_varname_length_&i
            ;
        %end;

        merge work.&base_table_name_sort._bsr     (IN= base)
              work.&compare_table_name_sort._csr  (IN= compare)
                                                  end= done
        ;
        by &by_values.;

        keep table_from row_type &by_values. D_: &union_varnames. &except_base_varnames. &except_compare_varnames.;

        call missing(%pattern(&union_varnames., %bquote(D_#), %str(,)));

        if (base) and NOT (compare) then do;
            table_from = 'BASE';
            row_type   = 'DELETED';

            %if (%bquote(&except_compare_varnames.) ne) %then %do;
                call missing(%pattern(&except_compare_varnames., %bquote(#_n), %str(,)));
            %end;

            %pattern(&union_varnames., %bquote(# = #_o), %str(;)) /* after last element: */ ;

            output;
        end;

        if (compare) and NOT (base) then do;
            table_from = 'COMPARE';
            row_type   = 'NEW';

            %if (%bquote(&except_base_varnames.) ne) %then %do;
                call missing(%pattern(&except_base_varnames., %bquote(#_o), %str(,)));
            %end;

            %pattern(&union_varnames., %bquote(# = #_n), %str(;)) /* after last element: */ ;

            output;
        end;

        if (base) and (compare) then do;
            is_diff = 0;

            %do i=1 %to %sysfunc(countw(&union_varnames., %str( )));
                if (%scan(&union_varnames., &i., %str( ))_o ne %scan(&union_varnames., &i., %str( ))_n) then do;
                    D_%scan(&union_varnames., &i., %str( )) = 1;

                    is_diff = 1;

                    if (D_%scan(&union_varnames., &i., %str( )) eq 1) then do;
                        if (findw(var_is_diff, "D_%scan(&union_varnames., &i., %str( ))", ' ', 'I') eq 0) then do;
                            var_is_diff = catx(' ', var_is_diff, "D_%scan(&union_varnames., &i., %str( ))");
                        end;
                    end;
                end;
            %end;

            if (is_diff) then do;
                table_from = 'BASE';
                row_type   = 'DIFF';

                %pattern(&union_varnames. &except_base_varnames., %bquote(# = #_o), %str(;)) /* after last element: */ ;

                output;

                table_from = 'COMPARE';
                row_type   = 'DIFF';

                %if (%bquote(&except_base_varnames.) ne) %then %do;
                    call missing(%pattern(&except_base_varnames., %bquote(#_o), %str(,)));
                %end;

                %pattern(&union_varnames. &except_compare_varnames., %bquote(# = #_n), %str(;)) /* after last element: */ ;

                output;
            end;
        end;

        if (done) then do;
            union_varnames_d_prefix = "%pattern(&union_varnames., %bquote(D_#), %str( ))";

            do i=1 to countw(var_is_diff, ' ');
                if (findw(union_varnames_d_prefix, scan(var_is_diff, i, ' '), ' ', 'I')) then do;
                    union_varnames_d_prefix = transtrn(union_varnames_d_prefix, scan(var_is_diff, i, ' '), trimn(' '));
                end;
            end;

            call symputx('columns_to_drop', union_varnames_d_prefix, 'L');
        end;

        call missing(base, compare);
    run;

    %if (&columns_to_drop. ne) %then %do;
        proc sql;
            alter table &compared_table_dir_name..&compared_table_table_name.
                drop %pattern(&columns_to_drop., %bquote(#), %str(,))
            ;
        quit;
    %end;

    proc datasets lib= WORK nolist nodetails;
        delete &base_table_name_sort._bsr &compare_table_name_sort._csr;
        run;
    quit;

    %exit:
    %table_err:
    %param_err:

%mend compare_tables;
