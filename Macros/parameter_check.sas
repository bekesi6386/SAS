/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Checks the given parameter name against the specified check type.
    Parameter: parameter_name: the parameter name to check
               parameter_type: how to check the parameter name
               parameter_rc: return value to the outer macro or global session
                             IMPORTANT: If you use this macro inside a macro, 
                                        you have to create this parameter_rc macro variable
                                        into the outer macro local macro variable scope!
    Created at: 2021.09.30.
    Modified at: 2022.01.21 - Modify parameter_name and parameter_type macro variables check.

    Use cases:
        options mprint mlogic;

        1:  %macro test(name, age, table, file, char, num, date, date2);
                %local param_err;

                %parameter_check(name, PARAM_NULL, param_err)

                %put &=param_err.;

                %if &param_err. %then %do;
                    %put Konec!;
                    %goto eom;
                %end;

                %parameter_check(table, TABLE_EXIST, param_err)

                %put &=param_err.;

                %if &param_err. %then %do;
                    %put Konec!;
                    %goto eom;
                %end;

                %parameter_check(file, FILE_EXIST, param_err)

                %put &=param_err.;

                %if &param_err. %then %do;
                    %put Konec!;
                    %goto eom;
                %end;

                %parameter_check(char, CHARACTER, param_err)

                %put &=param_err.;

                %if &param_err. %then %do;
                    %put Konec!;
                    %goto eom;
                %end;

                %parameter_check(num, NUMERIC, param_err)

                %put &=param_err.;

                %if &param_err. %then %do;
                    %put Konec!;
                    %goto eom;
                %end;

                %parameter_check(date, DATE_CHAR, param_err)

                %put &=param_err.;

                %if &param_err. %then %do;
                    %put Konec!;
                    %goto eom;
                %end;

                %parameter_check(date2, DATE_NUM, param_err)

                %put &=param_err.;

                %if &param_err. %then %do;
                    %put Konec!;
                    %goto eom;
                %end;

                %eom:
            %mend test;

            %test(John, 17, sashelp.class, \\sas02\MACRO\nobs.sas, abc, 123, 20210110, '01jan2000'd)
**/

%macro parameter_check(parameter_name, parameter_type, parameter_rc) / minoperator mindelimiter= ' ';
    /*
    %let &&parameter_rc = 1;
    && -> &: a parameter nevenek ertekul adja 
    
    %bquote(&&&parameter_name)
    &&& 
    -> &&+& -> a parameter neve 
    -> && -> & -> a parameter nevet is kiertekeli
    */

    /* parameter_rc check */
    %if (%bquote(&parameter_rc.) eq) %then %do;
        %let parameter_rc = param_err;
    %end;

    /* always start with this */
    %let &&parameter_rc = 0;

    /* parameter_name check */
    %if (%bquote(&parameter_name.) eq) %then %do;
        %put;
        %put The parameter_name macro parameter is missing!;
        %let &&parameter_rc = 1;
        %put;
        %goto parameter_error;
    %end;

    /* parameter_type check */
    %if (%bquote(&parameter_type.) eq) %then %do;
        %put;
        %put The parameter_type macro parameter is missing!;
        %let &&parameter_rc = 1;
        %put;
        %goto parameter_error;
    %end;

    %local types did rc;

    %let types = PARAM_NULL TABLE_EXIST FILE_EXIST CHARACTER NUMERIC DATE_NUM DATE_CHAR LIBNAME_EXIST;

    %let parameter_type = %upcase(&parameter_type.);

    %if NOT (%bquote(&parameter_type.) IN (&types.)) %then %do;
        %put;
        %put The param type list does not contain the &=parameter_type value!;
        %let &&parameter_rc = 1;
        %put;
        %goto parameter_error;
    %end;

    /* values check */
    %if (%bquote(&parameter_type.) eq PARAM_NULL) %then %do;
        %if (%bquote(&&&parameter_name) eq) %then %do;
            %put;
            %put The &&parameter_name parameter is missing!;
            %let &&parameter_rc = 1;
            %put;
        %end;
    %end;
    %else %if (%bquote(&parameter_type.) eq TABLE_EXIST) %then %do;
        %if (NOT (%sysfunc(exist(&&&parameter_name, DATA)) 
                  or 
                  %sysfunc(exist(&&&parameter_name, VIEW)))) %then %do;
            %put;
            %put The &&parameter_name does not exist!;
            %let &&parameter_rc = 1;
            %put;
        %end;
    %end;
    %else %if (%bquote(&parameter_type.) eq FILE_EXIST) %then %do;
        %if NOT (%sysfunc(fileexist(&&&parameter_name))) %then %do;
            %put;
            %put The file does not exist!;
            %let &&parameter_rc = 1;
            %put;
        %end;
    %end;
    %else %if (%bquote(&parameter_type.) eq CHARACTER) %then %do;
        %if (%sysfunc(anydigit(%bquote(&&&parameter_name))) ne 0) %then %do;
            %put;
            %put The parameter must be character!;
            %let &&parameter_rc = 1;
            %put;
        %end;
    %end;
    %else %if (%bquote(&parameter_type.) eq NUMERIC) %then %do;
        %if (%sysfunc(anyalpha(%bquote(&&&parameter_name))) ne 0) %then %do;
            %put;
            %put The parameter must be number!;
            %let &&parameter_rc = 1;
            %put;
        %end;
    %end;
    %else %if (%bquote(&parameter_type.) eq DATE_CHAR) %then %do;
        %if ((%sysfunc(inputn(&&&parameter_name, anydtdte21.)) eq) 
             or 
             (%sysfunc(inputn(&&&parameter_name, anydtdte21.)) lt 0)
             or
             (%datatyp(%sysfunc(inputn(&&&parameter_name, anydtdte21.))) ne NUMERIC))
        %then %do;
            %put;
            %put The parameter must be date char!;
            %let &&parameter_rc = 1;
            %put;
        %end;
    %end;
    %else %if (%bquote(&parameter_type.) eq DATE_NUM) %then %do;
        %if ((%sysfunc(putn(&&&parameter_name, anydtdte21.)) eq) 
             or 
             (%sysfunc(putn(&&&parameter_name, anydtdte21.)) lt 0)
             or
             (%datatyp(%sysfunc(putn(&&&parameter_name, anydtdte21.))) ne NUMERIC))
        %then %do;
            %put;
            %put %sysfunc(putn(&&&parameter_name, anydtdte21.));
            %put The parameter must be date char!;
            %let &&parameter_rc = 1;
            %put;
        %end;
    %end;

    %parameter_error:

%mend parameter_check;
