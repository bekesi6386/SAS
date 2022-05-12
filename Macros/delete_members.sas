/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Delete the parameter members.
    Parameter: member_names: Tables or views separated by ' '.
               type: Must be in the list: DATA, VIEW
    Inner macro call: %put_params_to_log
                      %parameter_check

    Created at: 2022.01.17.
    Modified at: 

    Use cases:
        options mprint mlogic;

        1: data x y z;
               set sashelp.class;
           run;

           libname temp '\\srv3\users$\bekesid\proba_dir';

           data temp.x2;
               set work.x;
           run;

           %delete_members(work.x y work.z temp.x2 temp.x3)

           data temp.x3;
               set work.x;
           run;

           %delete_members(temp.x3, type= VIEW)

           %delete_members(temp.x3, type= DATAA)

           %delete_members(temp.x3, type= DATA)

           libname temp clear;

           data work.x / view= work.x;
               set sashelp.class;
           run;

           %delete_members(work.x, type= VIEW)
**/

%macro delete_members(member_names, type= DATA) / minoperator     
                                                  mindelimiter= ' ';
    /* print params and values to log */
    %put_params_to_log(delete_members)

    %local param_err i member_full_name dir_name member_name dir_list;

    /* member_names check */
    %parameter_check(member_names, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_params_err;
    %end;

    /* type check */
    %let type = %upcase(&type.);

    %if NOT (%bquote(&type.) IN (DATA VIEW)) %then %do;
        %put The type parameter must be in the list: DATA, VIEW! (&=type)!;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_params_err;
    %end;

    %do i=1 %to %sysfunc(countw(&member_names., %str( )));
        %let member_full_name = %scan(&member_names., &i., %str( ));

        /* exist? */
        %if NOT (%sysfunc(exist(&member_full_name., &type.))) %then %do;
            %put;
            %put The &=member_full_name (&=type) does not exist!;
            %put;
            %goto next_i;
        %end;

        %if (%sysfunc(index(&member_full_name., %str(.))) gt 0) %then %do;
            %let dir_name    = %scan(&member_full_name., -2, %str(.));
            %let member_name = %scan(&member_full_name., -1, %str(.));
        %end;
        %else %do;
            %let dir_name    = WORK;
            %let member_name = &member_full_name.;
        %end;

        /* new dir? */
        %if (%sysfunc(findw(&dir_list., &dir_name., %str(~ ), I)) eq 0) %then %do;
            %let dir_list = &dir_list. &dir_name.;
        %end;

        %local dir_&dir_name.;

        %let dir_&dir_name. = &&dir_&dir_name.. &member_name.;

        %next_i:
    %end;

    %do i=1 %to %sysfunc(countw(&dir_list., %str( )));
        %let dir_name = %scan(&dir_list., &i., %str( ));

        proc datasets lib= &dir_name. 
                      mtype= &type. 
                      nolist;
            delete &&dir_&dir_name..;
            run;
        quit;
    %end;

    %eom_params_err:

%mend delete_members;
