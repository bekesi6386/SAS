/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Compare two tables by same columns with proc compare.
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

            %compare_tables_with_proc(sashelp.class work.class, name age, work.compared_classes)
**/

%macro compare_tables_with_proc(table_names, by_values, compared_table_name) / minoperator mindelimiter= ' ';
    %put_params_to_log(compare_tables_with_proc)

    %local param_err i base_table_full_name compare_table_full_name base_dir_name base_table_name compare_dir_name compare_table_name
           compared_table_dir_name compared_table_table_name base_varnames compare_varnames by_value union_varnames except_base_varnames 
           except_compare_varnames base_table_name_sort compare_table_name_sort last_by_value
    ;

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
    %put &=compare_dir_name;
    %put &=compare_table_name;
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

    /* last by value */
    %let last_by_value = %scan(&by_values., -1, %str( ));

    /* varname lists */
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
    %put &=except_base_varnames;
    %put &=except_compare_varnames;
    %put &=union_varnames;
    %put *******************************;
    %put;
    
    /* sort the tables first */
    proc sort data= &base_dir_name..&base_table_name.
              out= work.&base_table_name_sort._bsr;
        by &by_values.;
    run;

    proc sort data= &compare_dir_name..&compare_table_name.
              out= work.&compare_table_name_sort._csr;
        by &by_values.;
    run;

    /* more than one row for id-s (suppress the proc compare WARNING) */
    data work.&base_table_name_sort._sbv / view= work.&base_table_name_sort._sbv;
        set work.&base_table_name_sort._bsr;
        by &by_values.;

        if first.&last_by_value. then do;
            seqno = 1;
        end;
        else do;
            seqno+1;
        end;
    run;

    data work.&compare_table_name_sort._scv / view= work.&compare_table_name_sort._scv;
        set work.&compare_table_name_sort._csr;
        by &by_values.;

        if first.&last_by_value. then do;
            seqno = 1;
        end;
        else do;
            seqno+1;
        end;
    run;

    /* compare */
    proc compare base= work.&base_table_name_sort._sbv
                 comp= work.&compare_table_name_sort._scv
                 out= work.tmp_inner_comp
                 noprint
                 outcomp
                 outbase
                 outdif
                 outnoequal
                 note
                 ;
        id &by_values. seqno;
        var &union_varnames.;
    run;

    /* define the DELETED or NEW observations */
    data &compared_table_dir_name..&compared_table_table_name.;
        length _type_ $11;

        merge work.tmp_inner_comp
              work.tmp_inner_comp (firstobs= 2
                                   keep= &by_values. seqno _type_
                                   rename= (%pattern(&by_values. seqno _type_, %bquote(# = lead1_#), %str( ))))
              work.tmp_inner_comp (firstobs= 3
                                   keep= &by_values. seqno _type_
                                   rename= (%pattern(&by_values. seqno _type_, %bquote(# = lead2_#), %str( ))))
        ;

        if %pattern(&by_values. seqno, %bquote((# ne lead1_#)), %str(or)) then do;
            lead1__type_ = '';
        end;

        if %pattern(&by_values. seqno, %bquote((# ne lead2_#)), %str(or)) then do;
            lead2__type_ = '';
        end;

        if (_type_ in ('BASE' 'COMPARE') and (missing(lead1__type_) and missing(lead2__type_))) then do;

            select(_type_);
                when('BASE')    _type_ = 'DELETED ROW';
                when('COMPARE') _type_ = 'NEW ROW';
                otherwise;
            end;

        end;

        drop lead: seqno;
    run;

    proc datasets lib= WORK nolist nodetails;
        delete &base_table_name_sort._bsr &compare_table_name_sort._csr tmp_inner_comp / MEMTYPE= DATA;
        run;
        delete &base_table_name_sort._sbv &compare_table_name_sort._scv / MEMTYPE= VIEW;
        run;
    quit;

    %table_err:
    %param_err:

%mend compare_tables_with_proc;
