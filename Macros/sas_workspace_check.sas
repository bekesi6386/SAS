%macro sas_workspace_check(drive) /des= 'If the space is less than 10 GB than send a WARNING to the Administrators.'; %macro dummy; %mend dummy;
    %* Author: BD; 
    %* Owner:  BD; 
    %* Created at: 2020.01.20.; 
    %* Version: 0.5; 

    %if %sysevalf(%superq(drive)=, boolean) eq %then %goto exit;

    %global email_sent;

    %if %bquote(&email_sent.) eq 1 %then %goto exit;

    %* automatically close the cmd windows;
    options noxwait xmin;

    /*keep just the alphabet*/
    %let drive = %upcase(%sysfunc(compress(&drive., , AK)));

    filename check pipe "wmic logicaldisk get size,freespace,caption";

    data _null_;
        infile check length= reclen;
        input line $varying1024. reclen;
        length empty_size full_size 8;

        /* subset the drive */
        if line =: "&drive.:";

        line = compress(line, '', 'DK');
        
        /* subset the digits */
        if not missing(line);

        empty_size = scan(line, 1, ' ');
        full_size  = scan(line, 2, ' ');

        if (divide(empty_size, full_size) lt 0.1) then do;
            call symputx('send_mail', '1', 'L');
        end;
        else do;
            call symputx('send_mail', '1', 'L');
        end;
    run;

    %if %bquote(&send_mail.) eq 1 %then %do;
        options emailhost=
         (
           'smtp.gmail.com' 
           /* alternate: port=487 SSL */
           port= 587 STARTTLS 
           auth= plain 
           /* your Gmail address */
           id= 'bekesi.david.90@gmail.com'
           /* optional: encode PW with PROC PWENCODE */
           pw= 'xunk lwxb bvnb tdqv'
         )
        ;

        filename my_msg email sender='bekesi.david.90@gmail.com'
                              to='bekesi.david.90@gmail.com'
                              subject='A szabad tárhely 10% alá csökkent!'
                              importance='high'
        ;
        data _null_;
            file my_msg;
        run;

        %if &syserr. eq 0 or &syserr. eq 4 %then %do;
            %let email_sent = 1;
        %end;

        filename my_msg clear;
    %end;

    filename check clear;

    %symdel send_mail /NOWARN;

    %exit:
%mend sas_workspace_check;

%sas_workspace_check(C)
