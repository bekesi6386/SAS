/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Connect to the library with libname statement. 
    Parameter: libref: Required
                       Libname library reference. 
                       Maximum 8 chracter with valid first char.
               path: Optional
                     Lirary full path.
               libref_err: Optional
                           The parameter of the return code.
               engine: Optional
                       Libname engine. (NULL, SQLSVR, ORACLE)
                       Must be valid engine.
               server: Optional
                       Database server name.
                       Must be valid server name.
               database: Optional
                         Database name. 
                         Must be valid database.
               schema: Optional
                       Schema name.
                       Must be valid schema.
               libname_options: Optional
                                Libname option(s).
                                Must be valid option and value. 
                                The program does not check the options validity!
                                Use with %str() function.
                                For example: readbuff, insertbuff, compress... etc
    Inner macro call: %put_params_to_log
                      %parameter_check

    Created at: 2022.01.21.
    Modified at: 2022.03.09. - libref already assing check
                 2022.03.24. - SQLSVR engine usage

    Use cases:
        options mprint mlogic;

        options NODLCREATEDIR;

        1:  %macro test;
                %local libname_err;

                %libname_assign(xx, "\\srv2\MNB_IDM\", libname_err)
                %put &=libname_err;

                %libname_assign(xx, '\\srv2\MNB_IDM\', libname_err)
                %put &=libname_err;

                %libname_assign(xx, \\srv2\MNB_IDM\, libname_err)
                %put &=libname_err;

                %libname_assign(_1234567, '\\srv2\MNB_IDM\', libname_err)
                %put &=libname_err;

                %libname_assign(kariter, , libname_err, sqlsvr, kirdbs03, kariter_live, dbo)
                %put &=libname_err;

                %libname_assign(kariter, , libname_err,  sqlsvrr, kirdbs03, kariter_live, dbo)
                %put &=libname_err;

                %libname_assign(orac, , libname_err,  oracle)
                %put &=libname_err;

                %libname_assign(orac, , libname_err, oracle, , , %str(readbuff= 50000 insertbuff= 32000))
                %put &=libname_err;

                %libname_assign(orac, , libname_err, oraclee, , , %str(readbuff= 50000 insertbuff= 32000))
                %put &=libname_err;

            %mend test;

            %test
**/

%macro libname_assign(libref, path, libname_rc, engine, server, database, schema, libname_options) / minoperator
                                                                                                     mindelimiter= ',';
    /* print params and values to log */
    %put_params_to_log(libname_assign)

    %local param_err libref_length libref_first_char libname_statement;

    /* libname_rc check */
    %if (%bquote(&libname_rc.) eq) %then %do;
        %let libname_rc = libname_err;
    %end;

    /* always start with this */
    %let &&libname_rc = 0;

    /* libref check */
    %parameter_check(libref, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %let &&libname_rc = 1;
        %put;
        %goto eom_param_err;
    %end;

    /* libref length */
    %let libref_length = %length(%bquote(&libref.));

    %if (&libref_length. gt 8) %then %do;
        %put The maximum length of the library reference is 8! (&=libref_length);
        %put The %upcase(&sysmacroname.) is exiting...;
        %let &&libname_rc = 1;
        %put;
        %goto eom_param_err;
    %end;

    /* libref characteristics check */

    /* first char check */
    %let libref_first_char = %substr(%bquote(&libref.), 1, 1);

    %if (%sysfunc(notfirst(%bquote(&libref_first_char.))) gt 0) %then %do;
        %put The libref first character is not valid in SAS! (&=libref_first_char);
        %put The %upcase(&sysmacroname.) is exiting...;
        %let &&libname_rc = 1;
        %put;
        %goto eom_param_err;
    %end;

    /* already assign? */
    %if (%sysfunc(libref(&libref.)) eq 0) %then %do;
        %put The &=libref already assigned!;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* path check */
    %if (%bquote(&path.) ne) %then %do;
        %let path = %sysfunc(dequote(%bquote(&path.)));

        /* normal libname statement */
        %let libname_statement = &libref. "&path." &libname_options.;

        %goto libname_statement;
    %end;

    /* engine check */
    %if (%bquote(&engine.) ne) %then %do;
        %let engine = %upcase(&engine.);

        /* if SQLSVR, then SERVER | DATABASE | SCHEMA check */
        %if (%bquote(&engine.) eq SQLSVR) %then %do;
            %parameter_check(server, PARAM_NULL, param_err)
            %if (&param_err.) %then %do;
                %put The %upcase(&sysmacroname.) is exiting...;
                %let &&libname_rc = 1;
                %put;
                %goto eom_param_err;
            %end;

            %let server = %upcase(&server.);

            %parameter_check(database, PARAM_NULL, param_err)
            %if (&param_err.) %then %do;
                %put The %upcase(&sysmacroname.) is exiting...;
                %let &&libname_rc = 1;
                %put;
                %goto eom_param_err;
            %end;

            %let database = %upcase(&database.);

            %parameter_check(schema, PARAM_NULL, param_err)
            %if (&param_err.) %then %do;
                %put The %upcase(&sysmacroname.) is exiting...;
                %let &&libname_rc = 1;
                %put;
                %goto eom_param_err;
            %end;

            %let libname_statement = &libref. &engine. noprompt="driver=SQL Server;server=&server.;database=&database.;Trusted_Connection=yes" 
                                     schema= &schema. &libname_options.;

            %goto libname_statement;
        %end;

        %else %if (%bquote(&engine.) eq ORACLE) %then %do;
            
            %let libname_statement = &libref. &engine. user= "&oracle_username." password= "&oracle_password." 
                                     path= "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=oradw)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=dw)))"
                                     &libname_options.;

            %goto libname_statement;
        %end;

        %else %do;
            %put The engine is not supported in this macro! (&=engine);
            %put The %upcase(&sysmacroname.) is exiting...;
            %let &&libname_rc = 1;
            %put;
            %goto eom_param_err;
        %end;
    %end;

    %libname_statement:
        libname &libname_statement.;

        %if (%sysfunc(libref(&libref.)) ne 0) %then %do;
            %put;
            %put There was a problem with the &libref. library reference!;
            %put The %upcase(&sysmacroname.) is exiting...;
            %let &&libname_rc = 1; 
            %put;
        %end;

    %eom_param_err:

%mend libname_assign;
