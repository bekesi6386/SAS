%macro sending_email(drive);
    %if %sysevalf(%superq(drive)=, boolean) eq %then %do;
        %put The drive parameter is missing!;
        %goto exit;
    %end;

    options emailhost= ('smtp.in.porsche.hu' id= 'extern.d.bekesi@porschebank.hu' pw= 'Spartan2020');

    %let drive = %upcase(%sysfunc(compress(&drive., , AK)));

    %put Sending the Email to the Administrator.;

    filename my_msg email sender='extern.d.bekesi@porschebank.hu'
                          subject="A szabad tárhely 10% alá csökkent a (&sysparm.) &drive.:\ meghajtón!"
                          importance='high'
    ;
    data _null_;
        file my_msg to=('bekesi.david@bsce.hu' 'g.szalai@porschebank.hu' 'v.lipecz@porschebank.hu');
        put 'Tisztelt Adminisztrátor!';
        put;
        put "A (&sysparm.) &drive.:\ tárhely felülvizsgálatára van szükség!";
        put;
        put 'Üdvözlettel,';
        put 'Porsche Finance Group Hungary';
        put 'Member of Porsche Bank Group';
        put '1139 Budapest, Fáy u. 27.';
        put '-----------------------------------------';
    run;

    %if &syserr. eq 0 or &syserr. eq 4 %then %do;
        %put The Email was succesfully sent to the Administrator.;

        proc sql;
            update &logcheck_tbl.
            set   drive_status     = '1'
                , modifiedby       = "&username."
                , modificationdate = "&datetime."
            where drive = "&drive." and modificationclosed eq 'Y'
            ;
        quit;
    %end;

    filename my_msg clear;

    %exit:
        %put The %upcase(&sysmacroname.) is exiting.;
%mend sending_email;