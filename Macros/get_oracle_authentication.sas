/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Get the oracle SHA256 encrypted password from user windows library 
           and username from _METAUSER global macro variable. (Autocall macro)
    Parameter: 
    Inner macro call: %parameter_check
    Created at: 2021.10.07.
    Modified at: 2022.01.12. - Header fix

    Use cases:
        options mprint mlogic;

        1:  %get_oracle_authentication
**/

%macro get_oracle_authentication;
    %local username orac_auth_file param_err;
    
    %let username       = %sysfunc(transtrn(&_metauser., %str(@MNB), %sysfunc(trimn(%str()))));
    %let orac_auth_file = \\srv3\users$\&username.\orac_auth.txt;

    %parameter_check(orac_auth_file, FILE_EXIST, param_err)

    %if (&param_err.) %then %do;
        %goto eom;
    %end;

    data _null_;
        infile "&orac_auth_file." obs=1 length= len;
    
        input oracle_password $varying1024. len;

        call symputx('oracle_password', oracle_password, 'G');
        call symputx('oracle_username', "&username.",    'G');
        stop;
    run;

    %eom:
%mend get_oracle_authentication;
