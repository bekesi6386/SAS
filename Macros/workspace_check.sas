%macro workspace_check /des= 'If the space is less than 10 percent than send an EMAIL to the Administrator(s).'; 
    %* Author: BD; 
    %* Owner:  BD; 
    %* Created at: 2020.01.20.; 
    %* Version: 1.0; 

    %put The %upcase(&sysmacroname.) process has started.;

    options nomprint nomlogic nosymbolgen;
    %* automatically close the cmd windows;
    options noxwait xmin;

    %local datetime 
           i 
           counts 
           drives 
           drive_status
    ;

    %let datetime     = %left(%sysfunc(putn(%sysfunc(datetime()), b8601dt.)));
    %let logcheck_tbl = log.SAS_Workspace_Check;
    %let username     = BEKESID;

    %if not (%sysfunc(exist(&logcheck_tbl.))) %then %do;
        %put The log.SAS_Workspace_Check table does not exist.;
        %goto exit;
    %end;

    filename check pipe 'wmic logicaldisk get size,freespace,caption';

    data _null_;
        infile check firstobs= 2 length= reclen end= done;
        input line $varying1024. reclen;
        length empty_size full_size counts 8;
        retain counts 0;

        drive = compress(line, '', 'AK');
        line  = compress(line, '', 'DK');

        if not missing(line) and not missing(drive) and (drive in ('C' 'D' 'E' 'S')) then do;
            empty_size = scan(line, 1, ' ');
            full_size  = scan(line, 2, ' ');

            if (divide(empty_size, full_size) lt 0.1) then do;
                put (drive empty_size full_size) (=/);
                put /;
                counts+1;
                call symputx(catt('drive', counts), drive, 'L');
            end;
        end;
        else if (done) then do;
            call symputx('counts', counts);
        end;
    run;

    %if (%bquote(&counts.) eq 0) %then %do;
        proc sql noprint;
            select quote(drive) into :drives separated by ' ' from &logcheck_tbl.
            where drive_status eq '1' and modificationclosed eq 'Y'
            ;
        quit;

	%put These drive(s) will be set to 0: &drives.;

        %if %bquote(&drives.) ne %then %do;
            proc sql;
                update &logcheck_tbl.
                set   drive_status     = '0'
                    , modifiedby       = "&username."
                    , modificationdate = "&datetime."
                where drive in (&drives.) and modificationclosed eq 'Y'
                ; 
            quit;
        %end;
    %end;
    %else %if (%bquote(&counts.) gt 0) %then %do;
        %put The number of the drive(s) will be checked: &counts.;

        %do i= 1 %to &counts.;
            %put Lap: &i.;

            proc sql noprint;
                select drive_status into :drive_status trimmed from &logcheck_tbl.
                where drive eq "&&drive&i.." and modificationclosed eq 'Y';

                %put The drive name is: &&drive&i..:\;
            quit;

            %if &drive_status. eq 1 %then %do;
                %put The message was already sent about the &&drive&i..:\ drive!;
                %goto exit;
            %end;
            %else %do;
                %sending_email(&&drive&i..)
            %end;
        %end; 
    %end;

    %*Destruct and etc...;
    filename check clear;
    %symdel datetime i counts drives drive_status /NOWARN;

    %exit:
        %put;
        %put The %upcase(&sysmacroname.) is exiting.;

%mend workspace_check;