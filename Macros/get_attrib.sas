%macro get_attrib(fieldnames, attrib_types, table) /minoperator;
    options mprint mlogic;
    %if (%sysevalf(%superq(fieldnames)=, boolean) eq)
         or
        (%sysevalf(%superq(attrib_types)=, boolean) eq)
    %then %do;
        %put The FIELDNAMES and ATTRIB_TYPES parameters are strict!;
        %goto exit;
    %end;

    /* ATTRIB_TYPES TEST */
    %let attrib_types = %upcase(&attrib_types.);

    %if (%eval(  %sysfunc(indexw(&attrib_types, LENGTH))
               + %sysfunc(indexw(&attrib_types, LABEL))
               + %sysfunc(indexw(&attrib_types, FORMAT))
               + %sysfunc(indexw(&attrib_types, INFORMAT))
              ) eq 0) 
        %then %do;
        %put The ATTRIB_TYPES rules are strict!;
        %put The choices are: LENGTH/LABEL/FORMAT/INFORMAT;
        %goto exit; 
    %end;
    %else %do;
        %local i attrib_param clean_attrib_types;
        %do i= 1 %to %sysfunc(countw(&attrib_types., %str( )));
            %let attrib_param = %scan(&attrib_types., &i., %str( ));
            %if (&attrib_param. IN (LENGTH LABEL FORMAT INFORMAT)) %then %do;
                %let clean_attrib_types = &clean_attrib_types. &attrib_param.;  
            %end;
        %end;
    %end;

    %local quote_fieldnames metatable dsid rc j nvars field_name field_type field_length 
           field_label field_format field_informat missing_fieldnames k l already_done
    ;

    /* FIELDNAME TEST */
    %let quote_fieldnames = "%sysfunc(tranwrd(&fieldnames., %str( ), " "))";

    /* TABLE TEST */
    %if (%bquote(&table.) eq) %then %do;
        %let dsid = %sysfunc(open(sashelp.vcolumn (keep= libname memname memtype name type &clean_attrib_types. 
                                                   where= (memtype= 'DATA' and name in (&quote_fieldnames.)))));
    %end;
    %else %do;
        %local libname membername;
        %if (%sysfunc(countw(&table., %str(.))) eq 2) %then %do;
            %let libname    = %scan(&table., 1, %str(.));
            %let membername = %scan(&table., 2, %str(.));
        %end;
        %else %if (%sysfunc(countw(&table.)) eq 1) %then %do;
            %let libname    = WORK;
            %let membername = &table.;
        %end;
        %let dsid = %sysfunc(open(sashelp.vcolumn (keep= libname memname memtype name type &clean_attrib_types. 
                                                   where= (libname eq "&libname." and memname eq "&membername." and memtype= 'DATA' and name in (&quote_fieldnames.)))));
    %end;

    %if (&dsid. le 0) %then %do;
        %put The data set can not be opened!;
        %goto exit;
    %end; 

    %let nvars = %sysfunc(attrn(&dsid., NVARS));
    %if (%bquote(&nvars.) eq) %then %do;
        %put The data set has no variables!;
        %goto exit;
    %end;

    %let missing_fieldnames =;
    %let full_declare       =;
    %let k                  = 1;

    %do %while(%sysfunc(fetch(&dsid.)) eq 0);
        %let field_name = %sysfunc(getvarc(&dsid., %sysfunc(varnum(&dsid., name))));

        %if (&field_name. IN (&fieldnames.)) %then %do; 
            %if %sysfunc(indexw(&attrib_types, LENGTH)) %then %do;
                %if (%sysfunc(getvarc(&dsid., %sysfunc(varnum(&dsid., type)))) eq char)      %then %let field_type = $;
                %else %if (%sysfunc(getvarc(&dsid., %sysfunc(varnum(&dsid., type)))) eq num) %then %let field_type =;
                
                %let field_length = %sysfunc(getvarn(&dsid., %sysfunc(varnum(&dsid., length))));

                %if %bquote(&field_length.) ne %then %do;
                    %let full_declare&k. = length%str( )&field_name.%str( )&field_type.&field_length.;
                %end;
            %end;
            %if %sysfunc(indexw(&attrib_types, LABEL)) %then %do;
                %let field_label = %sysfunc(getvarc(&dsid., %sysfunc(varnum(&dsid., label))));

                %if %bquote(&field_label.) ne %then %do;
                    %let full_declare&k. = &full_declare.%str( )label%str( )"&field_label.";
                %end;
            %end;
            %if %sysfunc(indexw(&attrib_types, FORMAT)) %then %do;
                %let field_format = %sysfunc(getvarc(&dsid., %sysfunc(varnum(&dsid., format))));

                %if %bquote(&field_format.) ne %then %do;
                    %let full_declare&k. = &full_declare.%str( )format%str( )&field_format.;
                %end;
            %end;
            %if %sysfunc(indexw(&attrib_types, INFORMAT)) %then %do;
                %let field_informat = %sysfunc(getvarc(&dsid., %sysfunc(varnum(&dsid., informat))));

                %if %bquote(&field_informat.) ne %then %do;
                    %let full_declare&k. = &full_declare.%str( )informat%str( )&field_informat.;
                %end;
            %end;

            %let k = %eval(&k. + 1);
        %end;
        %else %let missing_fieldnames = &missing_fieldnames.%str( )&field_name.;
    %end;

    %put &=k;

    %let rc = %sysfunc(close(&dsid.));

    %if (%bquote(&missing_fieldnames.) ne) %then %do;
        %put &=missing_fieldnames;
    %end;

    %do l= 1 %to &k.;
        length &&full_declare&l..;
    %end;

    %symdel quote_fieldnames metatable dsid rc j nvars field_name field_type field_length field_label field_format field_informat missing_fieldnames 
            libname membername i attrib_param clean_attrib_types k l already_done
            /NOWARN
    ;

    %exit:
        %put The %upcase(&sysmacroname.) is exiting!;
%mend get_attrib;

/*
%get_attrib
*/
