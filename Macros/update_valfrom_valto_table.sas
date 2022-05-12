/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Update base history table with another table by key(s) to a given date.
    Parameter: base_table: The base history table with valfrom valto columns.
               update_table: The update table with keys. OLD/NEW/SAME key records.
               keys: One or more key column names.
               date: Update date.
               update_old_records: Default: YES
    Inner macro call: %put_params_to_log
                      %parameter_check
                      %get_varnames
                      %list_operator
                      %pattern
                      %nobs
                      %delete_members
    Created at: 2022.03.02.
    Modified at: 2022.03.09. - datepart(valfrom) in RDBMS mode
                 2022.03.10. - compare the intersect columns values
                 2022.03.16. - %local i macro variable
                 2022.03.21. - BASE table <= &date. -> < &date.
                 2022.03.23. - valto_sas ne '31dec9000'd
                 2022.03.24. - SQLSVR usage

    Use cases:
        options mprint mlogic;

        base table:

        data work.base;
            set sashelp.class;

            attrib valfrom length= 8 format= yymmddp10.
                   valto   length= 8 format= yymmddp10.
            ;

            valfrom = sum('01jan2022'd, _N_);
            valto   = '31dec9000'd;
        run;

        update table:

        data work.update;
            set sashelp.class;

            if (mod(_N_, 2) eq 0) then do;
                delete;
            end;

            if (mod(_N_, 3) eq 0) then do;
                age = sum(age, _N_);
            end;
        run;

        1: every record with same key is a new record:

           %update_valfrom_valto_table(work.base
                                       , work.update
                                       , name 
                                       , '02mar2022'd)

        2: same name list: nothing happens

           %update_valfrom_valto_table(work.base
                                       , work.update
                                       , name 
                                       , '02mar2022'd
                                       , update_old_records= NO)

        3: new records

           data work.update;
                set sashelp.class;

                if (mod(_N_, 2) eq 0) then do;
                    delete;
                end;

                if (mod(_N_, 3) eq 0) then do;
                    name = cats(name, age);
                end;
           run;

           %update_valfrom_valto_table(work.base
                                        , work.update
                                        , name 
                                        , '02mar2022'd
                                        , update_old_records= NO)

        4: rerun the previous macro call: no event
        
           %update_valfrom_valto_table(work.base
                                        , work.update
                                        , name 
                                        , '02mar2022'd
                                        , update_old_records= NO)
                
**/

%macro update_valfrom_valto_table(base_table
                                  , update_table
                                  , keys
                                  , date
                                  , update_old_records= YES) / minoperator 
                                                               mindelimiter= ' ';

    /* print params and values to log */
    %put_params_to_log(update_valfrom_valto_table)

    %local param_err base_table_libname base_table_name base_table_libname_engine base_table_engine base_varnames 
           comp_varnames nobs dsid rc base_sortedby base_sortlvl union_varnames i
    ;

    /* base_table check */
    %parameter_check(base_table, TABLE_EXIST, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    %let base_table = %upcase(&base_table.);

    %if (%index(%bquote(&base_table.), %str(.)) gt 0) %then %do;
        %let base_table_libname = %qscan(&base_table., -2, %str(.));
        %let base_table_name    = %qscan(&base_table., -1, %str(.));
    %end;
    %else %do;
        %let base_table_libname = WORK;
        %let base_table_name    = &base_table.;
    %end;

    %put *********************;
    %put &=base_table_libname;
    %put &=base_table_name;
    %put *********************;

    proc sql noprint;
        select distinct engine
        into :base_table_libname_engine trimmed
        from dictionary.libnames
        where libname eq "&base_table_libname."
        ;
    quit;

    %put *********************;
    %put &=base_table_libname_engine;
    %put *********************;

    %if (&base_table_libname_engine. ne) and (&base_table_libname_engine. ne V9) %then %do;
        %let base_table_engine = RDBMS;
    %end;

    %put *********************;
    %put &=base_table_engine;
    %put *********************;

    /* update_table check */
    %parameter_check(update_table, TABLE_EXIST, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* keys check */
    %parameter_check(keys, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* make distinct list */
    %let keys = %cmpres(%upcase(%distinctlist(%bquote(&keys.))));

    /* date check */
    %parameter_check(date, DATE_NUM, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* update_old_records check */
    %let update_old_records = %upcase(%bquote(&update_old_records.));

    %if NOT (%bquote(&update_old_records.) IN (YES NO)) %then %do;
        %put The &=update_old_records parameter is not in the list (YES NO)!;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* get column lists */
    %let base_varnames      = %list_operator(EXCEPT, %get_varnames(%bquote(&base_table.)),   %bquote(&keys.));
    %let comp_varnames      = %list_operator(EXCEPT, %get_varnames(%bquote(&update_table.)), %bquote(&keys.));
    /* no key columns in the INTERSECT */
    %let intersect_varnames = %list_operator(INTERSECT, %bquote(&base_varnames.), %bquote(&comp_varnames.));

    %put *********************;
    %put &=base_varnames;
    %put &=comp_varnames;
    %put &=intersect_varnames;
    %put *********************;

    /* valfrom valto column exist in the base table? --> is it really a history table? */
    %if NOT (VALFROM IN (%bquote(&base_varnames.))) 
        or
        NOT (VALTO IN (%bquote(&base_varnames.))) %then %do;

        %put The VALFROM or VALTO columns are not in the BASE table (&=base_table)!;
        %put &=base_varnames;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* update_table has rows? 
       why not %nobs() macro? --> view input
    */
    proc sql noprint;
        select count(*)
        into :nobs trimmed
        from %bquote(&update_table.)
        ;
    quit;

    %if (&nobs. lt 1) %then %do;
        %put The update table has not rows! (&=update_table);
        %put &=nobs;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* get sortedby and sortlvl meta infos from base table
       sorlvl: WEAK:   sort order of the data was established by the user
               STRONG: sort order of the data was established by the software
    */
    %let dsid = %sysfunc(open(%bquote(&base_table.)));
    %if not (&dsid.) %then %do;
        %put The &=base_table can not be opened!;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    %let base_sortedby = %cmpres(%upcase(%sysfunc(attrc(&dsid., SORTEDBY))));
    %let base_sortlvl  = %sysfunc(attrc(&dsid., SORTLVL));

    /* close the table */
    %let rc = %sysfunc(close(&dsid.));

    %put *********************;
    %put &=base_sortedby;
    %put &=base_sortlvl;
    %put KEYS=&keys. VALFROM;
    %put *********************;

    %if (%bquote(&base_sortedby.) eq)
         or
        (%bquote(&base_sortedby.) ne %bquote(&keys.) VALFROM)
         or
        (%bquote(&base_sortlvl.) eq WEAK) %then %do;

        %put The base table (&base_table.) has no sort info or the sortlevel info is WEAK so proc sort will be happen!;
        %put;

        proc sort data= %bquote(&base_table.) 
                  %if (&base_table_engine. eq RDBMS) %then %do;
                      out= work.tmp_base_table_srt

                      %let base_table = work.tmp_base_table_srt;
                  %end;
                  force;
            by %bquote(&keys.) valfrom;
        run;
    %end;
    %else %do;
        %put The base table (&base_table.) already sorted with STRONG sortlevel!;
        %put;
    %end;

    /* must be sort first!
           - duplicate rows!
    */
    proc sort data= %bquote(&update_table.) 
              out= work.tmp_new_srt_update_tbl 
              dupout= work.tmp_duplicate_rows
              nodupkey
              force;
        by %bquote(&keys.);
    run;

    %if (%nobs(work.tmp_duplicate_rows) gt 0) %then %do;

        %put;
        %put ******************************************;
        %put These rows were duplicate records!;
            data _null_;
                set work.tmp_duplicate_rows;
                put _all_;
            run;
        %put ******************************************;
        %put;
    %end;
    %else %do;
        %put;
        %put *******************************;
        %put 0 duplicate records was found!;
        %put *******************************;
        %put;
    %end;
    
    /* compare the tables */
    data %bquote(&base_table.)  (keep= %bquote(&base_varnames.) %bquote(&keys.))
         work.event_table       (keep= %bquote(&base_varnames.) %bquote(&keys.) event_type)
        ;
        merge %bquote(&base_table.)         (IN= base
                                             where= (%if (&base_table_engine. eq RDBMS) %then %do;
                                                         datepart(valfrom) < &date. 
                                                     %end;
                                                     %else %do; 
                                                         valfrom < &date. 
                                                     %end;
                                            ))
              work.tmp_new_srt_update_tbl   (IN= new
                                             rename= (%pattern(%bquote(&intersect_varnames.), %bquote(# = N_#), %str( ))
                                                      )
                                             )
        ;
        by %bquote(&keys.);

        length event_type $3
               diff       8
               valto_sas  8
        ;

        diff = 0;

        %if (&base_table_engine. eq RDBMS) %then %do; 
            valto_sas = datepart(valto);
        %end;
        %else %do;
            valto_sas = valto;
        %end;
        
        if (base and not new) then do;

            output %bquote(&base_table.);
        end;
        else if (not base and new) then do;

            %pattern(%bquote(&intersect_varnames.), %bquote(# = N_#), %str(;));

            %if (&base_table_engine. eq RDBMS) %then %do;
                valfrom = dhms(&date.,       0, 0, 0);
                valto   = dhms('31dec9000'd, 0, 0, 0);
            %end;
            %else %do;
                valfrom = &date.;
                valto   = '31dec9000'd;
            %end;

            event_type = 'NEW';

            output work.event_table
                   %bquote(&base_table.)
            ;
        end;
        else if (base and new and valto_sas ne '31dec9000'd) then do;
            output %bquote(&base_table.);
        end;
        else if (base and new and valto_sas eq '31dec9000'd) then do;

            %if (&update_old_records. eq YES) %then %do;

                %if (&base_table_engine. eq RDBMS) %then %do;
                    valto = dhms(intnx('DAY', &date., -1, 'S'), 0, 0, 0);
                %end;
                %else %do;
                    valto = intnx('DAY', &date., -1, 'S');
                %end;

                event_type = 'OLD';

                output work.event_table
                       %bquote(&base_table.)
                ;

                %pattern(%bquote(&intersect_varnames.), %bquote(# = N_#), %str(;));

                %if (&base_table_engine. eq RDBMS) %then %do;
                    valfrom = dhms(&date.,       0, 0, 0);
                    valto   = dhms('31dec9000'd, 0, 0, 0);
                %end;
                %else %do;
                    valfrom = &date.;
                    valto   = '31dec9000'd;
                %end;

                event_type = 'NEW'; 

                output work.event_table
                       %bquote(&base_table.)
                ;
            %end;
            %else %do;
                /* intersect_varnames difference check */
                %do i=1 %to %sysfunc(countw(&intersect_varnames., %str( )));
                    if (%scan(&intersect_varnames., &i., %str( )) ne N_%scan(&intersect_varnames., &i., %str( ))) then do;
                        diff = 1;
                    end;
                %end;

                if (diff) then do;
                    %if (&base_table_engine. eq RDBMS) %then %do;
                        valto = dhms(intnx('DAY', &date., -1, 'S'), 0, 0, 0);
                    %end;
                    %else %do;
                        valto = intnx('DAY', &date., -1, 'S');
                    %end;

                    event_type = 'OLD';

                    output work.event_table
                           %bquote(&base_table.)
                    ;

                    %pattern(%bquote(&intersect_varnames.), %bquote(# = N_#), %str(;));

                    %if (&base_table_engine. eq RDBMS) %then %do;
                        valfrom = dhms(&date.,       0, 0, 0);
                        valto   = dhms('31dec9000'd, 0, 0, 0);
                    %end;
                    %else %do;
                        valfrom = &date.;
                        valto   = '31dec9000'd;
                    %end;

                    event_type = 'NEW'; 

                    output work.event_table
                           %bquote(&base_table.)
                    ;
                end;
                else do;
                    output %bquote(&base_table.);
                end;
            %end;

        end;
    run;

    /*
      NOTE: SAS variable labels, formats, and lengths are not written to DBMS tables.
      WARNING: Engine SQLSVR does not support index create operations.
    */

    %if (&base_table_engine. eq RDBMS) %then %do;

        %delete_members(&base_table_libname..&base_table_name.)

        proc datasets lib= WORK nolist nodetails;
            change tmp_base_table_srt = &base_table_name.;
            run;
            copy out= &base_table_libname.;
                select &base_table_name.;
            run;
            delete &base_table_name.;
            run;
        quit;
    %end;
    %else %do;
        proc sql;
            %do i=1 %to %sysfunc(countw(&keys., %str( )));
                create index %scan(&keys., &i., %str( )) on &base_table_libname..&base_table_name.;
            %end; 

            create index pk on &base_table_libname..&base_table_name. (valfrom, valto);
        quit;
    %end;

    %delete_members(work.tmp_duplicate_rows work.tmp_new_srt_update_tbl)

    %eom_param_err:

%mend update_valfrom_valto_table;
