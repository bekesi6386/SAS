%macro sas_workspace_check /des= 'If the space is less than 10 percent than send an EMAIL to the Administrator(s).'; 
    proc printto log= "E:\SAS_Logs\sas_PROD_workspace_check_%left(%sysfunc(putn(%sysfunc(datetime()), b8601dt.))).log";
    run;

    %* Author: BD; 
    %* Owner:  BD; 
    %* Created at: 2020.01.20.; 
    %* Version: 1.0; 

    %put The %upcase(&sysmacroname.) process has started.;

    options nomprint nomlogic nosymbolgen;

    %local datetime i;

    %let datetime = %sysfunc(datetime());

    %macro sending_email(drive);
        %if %sysevalf(%superq(drive)=, boolean) eq %then %do;
            %put The drive parameter is missing!;
            %goto exit;
        %end;

        options emailhost= ('smtp.in.porsche.hu' id= 'extern.d.bekesi@porschebank.hu' pw= 'Spartan2020');

        %let drive = %upcase(%sysfunc(compress(&drive., , AK)));

        %put Sending the Email to the Administrator.;

        filename my_msg email sender='extern.d.bekesi@porschebank.hu'
                              to='bekesi.david@bsce.hu'
                              subject="A szabad tárhely 10% alá csökkent a(z) &drive.:\ meghajtón!"
                              importance='high'
        ;
        data _null_;
            file my_msg;
            put 'Tisztelt Adminisztrátor!';
            put;
            put "A(z) &drive.:\ tárhely felülvizsgálatára van szükség!";
            put;
            put 'Üdvözlettel,';
            put 'Porsche Finance Group Hungary';
            put 'Member of Porsche Bank Group';
            put '1139 Budapest, Fáy u. 27.';
            put '-----------------------------------------';
        run;

        %if &syserr. eq 0 or &syserr. eq 4 %then %do;
            %put The Email was succesfully sent to the Administrator.;
            %let email_sent_&&drive&i.. = 1;
        %end;

        filename my_msg clear;

        %exit:
    %mend sending_email;

    %* automatically close the cmd windows;
    options noxwait xmin;

    filename check pipe 'wmic logicaldisk get size,freespace,caption';

    data _null_;
        infile check firstobs= 2 length= reclen;
        input line $varying1024. reclen;
        length empty_size full_size counts 8 all_drive $20;
        retain counts 0 all_drive '';

        drive = compress(line, '', 'AK');
        line  = compress(line, '', 'DK');

        if not missing(line) and not missing(drive);

        all_drive  = catx(' ', all_drive, drive);
        empty_size = scan(line, 1, ' ');
        full_size  = scan(line, 2, ' ');

        if (divide(empty_size, full_size) lt 0.1) then do;
            put (drive empty_size full_size) (=/);
            put /;
            counts+1;
            call symputx(catt('drive',counts), drive, 'L');
        end;

        /* The end= is not working. */
        call symputx('counts',    counts,    'L');
        call symputx('all_drive', all_drive, 'L');
    run;

    %if (%bquote(&counts.) gt 0) %then %do;
        %put &=counts;

        %do i= 1 %to &counts.;
            %put &=i;

            %global email_sent_&&drive&i..;

            %put;
            %put &&&&email_sent_&&drive&i...;
            %put;

            %if not (&&&&email_sent_&&drive&i... eq 1) %then %do;
                %put email_sent_&&drive&i..=;

                %sending_email(&&drive&i..)
            %end;
            %else %do;
                %put The message was already sent!;
                %goto exit;
            %end;
        %end; 
    %end;
    %else %if (%bquote(&counts.) eq 0) %then %do;
        %do i= 1 %to %sysfunc(countw(&all_drive.));
            %if %symexist(email_sent_&&drive&i..) %then %do;
                %put These drive will be change to 0: &&&&email_sent_&&drive&i...;
                %let email_sent_&&drive&i.. = 0;
            %end;
        %end;
    %end;

    filename check clear;

    %symdel counts i /NOWARN;

    %exit:
        %put;
        %put The %upcase(&sysmacroname.) is exiting.;

        proc printto log=log;
        run;
%mend sas_workspace_check;

%sas_workspace_check

/*
To set 0 for the drives:
%let EMAIL_SENT_E = .;
%let EMAIL_SENT_E = .;
%let EMAIL_SENT_E = .;
%let EMAIL_SENT_E = .;
*/
