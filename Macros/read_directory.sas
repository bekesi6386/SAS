/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Read the directory path recursively and write the following informations to the output data set table.
           path / file_name / extension / moddate / creation_date / file_size 
    Parameter: path: Full path name to the directory. If you want more dir, make a macro for that.
               logfile: NOT optional - The logfile full path and filename.
               outset_name: The output data set name with or without library reference.
               file_extensions: File extensions to looking for.
                                (SAS SAS7BCAT SAS7BDAT SAS7BNDX SAS7BITM SAS7BUTL EGP LCK SAS UTL CFG CMD SH BAT DOC DOCX XLS XLSX XLSM XLSB BAK HTML XHTML CSV SQL $$1)
               first: Parameter to the recursive call. Do not modify!
               debug: Debug parameter. If the value is YES, more information will be written to the log file.
    Created at: 2021.05.20.
    Modified at: 2021.09.20. 
                 2022.01.25. - delete the MPRINT from debug line
                 2022.05.05. - clear the macro vars. at the begin of the loops

    Use cases:
        options mprint mlogic;

        1:  %read_directory(\\sas02\DFF_DATA
                            , \\srv2\MNB_IDM\Piac_adat_onal_oszt\Rendszeres_Riportok\Egyéb\tarhely_hasznalat\LOG\read_directory.log
                            , dir_file_list_dff_data
                            , file_extensions= SAS7BDAT 
                            )
**/

%macro read_directory(path
                      , logfile
                      , outset_name
                      , file_extensions=
                      , first=Y
                      , debug= NO) /des='Read the directory path recursively.' 
                                    minoperator 
                                    mindelimiter=' '
    ;

    /* MACRO OPTIONS */
    %local symbolgen_opt mlogic_opt;

    %let symbolgen_opt = %sysfunc(getoption(SYMBOLGEN));
    %let mlogic_opt    = %sysfunc(getoption(MLOGIC));

    %if (&debug. ne NO) %then %let debug=;
    options &debug.symbolgen &debug.mlogic;

    /* PARAMETERS */
    %if (%sysevalf(%superq(path)=, boolean)) %then %do;
        %put The path parameter is missing!;
        %put The &sysmacroname. is exiting.;
        %goto eom;
    %end;

    %if (%sysevalf(%superq(file_extensions)=, boolean)) %then %do;
        %put The file_extensions parameter is missing!;
        %put The &sysmacroname. is exiting.;
        %goto eom;
    %end;

    %if (%sysevalf(%superq(outset_name)=, boolean)) %then %do;
        %let outset_name = dir_file_list;
    %end;

    %local /* SYSTEM */ external_log operationalsystem 
           /* DIR */    indir rc did i 
           /* FILE */   flref nobs fullname ref fid file_name moddate filesize_bytes creation_date 
    ;

    /* LOGFILE */
    %let external_log = 0;

    %if (%sysevalf(%superq(logfile)=, boolean) eq 0) %then %do;
        proc printto log= "&logfile." new;
        run;

        %if %sysfunc(fileexist(&logfile.)) %then %do;
            %put The LOG FILE WAS CREATED!;

            %let external_log = 1;
        %end;
        %else %do;
            %put There was a problem with the LOG FILE creation!;

            proc printto log= log;
            run;
        %end;
    %end;

    /* OPERATIONAL SYSTEM */
    %if (&sysscp. eq WIN) %then %do;
        %let operationalsystem = &sysscp.;
    %end;
    %else %if (&sysscp. eq LINUX) or (%index(&sysscp., SUN)) %then %do;
        %let operationalsystem = UNIX;
    %end;

    /* DIRECTORY OPEN */
    %let rc  = %sysfunc(filename(indir, %bquote(&path.)));
    %let did = %sysfunc(dopen(&indir.));

    %if (&did. eq 0) %then %do;
        %put The directory can not be opened!;
        %put The directory: &path.; 
        %put The &sysmacroname. is exiting.;
        %goto eom;
    %end;

    /* META TABLE */
    %if NOT (%sysfunc(exist(&outset_name.))) %then %do;
        data &outset_name.;
            length path           $30000
                   fullname       $256
                   file_name      $100
                   extension      $50
                   moddate        $30
                   filesize_bytes $1000
                   creation_date  $30
            ;
            call missing(of _all_);
            stop;
        run;

        %if (&syserr. IN (0 4)) %then %do;
            %put The %upcase(&outset_name.) meta table has created!;
        %end;

        %else %do;
            %put There was a problem with the %upcase(&outset_name.) meta table creation!;
            %put The &sysmacroname. is exiting.;
            %goto eom;
        %end;
    %end;

    /* RERUN STATUS CHECK */
    %if (&first. eq Y) %then %do;
        data _null_;
            if 0 then set &outset_name. nobs= nobs;
            call symputx('nobs', nobs);
            stop;
        run;

        %if (&nobs. gt 0) %then %do;
            data &outset_name.;
                set &outset_name. (obs= 0);
            run;

            %put The %upcase(&outset_name.) meta table was cleared!;
        %end;
    %end;

    /* DIR ITERATIVE */
    %do i= 1 %to %sysfunc(dnum(&did.));
        %let fullname       = ;
        %let ref            = ;
        %let file_name      = ;
        %let moddate        = ;
        %let filesize_bytes = ;
        %let creation_date  = ;

        %let fullname  = %upcase(%qsysfunc(dread(&did., &i.)));
        %let ref       = %upcase(%qscan(&fullname., -1, %str(.)));

        /* FILE META INFOS */
        %let rc  = %qsysfunc(filename(flref, %bquote(&path.\&fullname.)));
        %let fid = %sysfunc(fopen(&flref.));
        
        %if (&fid. gt 0) %then %do;
            %if %bquote(&ref.) ne %bquote(&fullname.) %then %do;
                %let file_name = %upcase(%qsubstr(&fullname., 1, %qsysfunc(length(&fullname.)) - %sysfunc(length(&ref.)) - 1));
            %end;

            %let moddate        = %qsysfunc(finfo(&fid., Last Modified));
            %let filesize_bytes = %qsysfunc(finfo(&fid., File Size (bytes)));

            %if (&operationalsystem. eq WIN) %then %do;
                %let creation_date = %qsysfunc(finfo(&fid.,  Create Time));
            %end;
            %else %do;
                %let creation_date =;
            %end;

            %let rc = %sysfunc(fclose(&fid.));
        %end;
        %else %do;
            %put %sysfunc(sysmsg());
        %end;

        %let rc = %sysfunc(filename(flref));
        %let rc = %sysfunc(filename(indir));


        /* FILL THE META TABLE */
        /* if there is a duplicate name, we do not know its content */
        %if (%qupcase(&ref.) # %bquote(&file_extensions.)) %then %do;
            proc sql;
                insert into &outset_name.
                set   path           = "&path."
                    , fullname       = "&fullname."
                    , file_name      = "&file_name."
                    , extension      = "&ref."
                    , moddate        = "&moddate."
                    , filesize_bytes = "&filesize_bytes."
                    , creation_date  = "&creation_date."
                ;
            quit;
        %end;
        /* RECURSIVE CALL */
        %else %if (%qscan(&fullname., 2, .) eq) %then %do;
            %if (&operationalsystem.) eq WIN %then %do;
                %read_directory(&path.\&fullname., , &outset_name., file_extensions= &file_extensions., first=N)
            %end;
            %else %do;
                %read_directory(&path./&fullname., , &outset_name., file_extensions= &file_extensions., first=N)
            %end;
        %end;
    %end;

    /* CLEAR */
    %let rc = %sysfunc(dclose(&did.));
    %let rc = %sysfunc(filename(flref));
    %let rc = %sysfunc(filename(indir));

    %if (&external_log.) %then %do;
        proc printto log= log;
        run;
    %end;

    %eom:
        options &symbolgen_opt. &mlogic_opt.;

%mend read_directory;
