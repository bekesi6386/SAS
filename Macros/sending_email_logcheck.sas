%macro sending_email_logcheck(text);
    %if %sysevalf(%superq(text)=, boolean) %then %do;
        %put The text parameter is missing!;
        %goto exit;
    %end;

    options emailhost= ('smtp.in.porsche.hu' id= 'extern.d.bekesi@porschebank.hu' pw= 'Spartan2020');

    %put Sending the Email to the Administrator(s).;

    filename my_msg email sender='extern.d.bekesi@porschebank.hu'
                          subject="&sysparm. ArchiveData JOB hibásan futott!"
                          importance='high'
    ;

    data _null_;
        file my_msg to=('bekesi.david@bsce.hu' 'v.lipecz@porschebank.hu');
        put 'Tisztelt Adminisztrátor(ok)!';
        put;
        put "A (&sysparm.) ArchiveData JOB ERROR-t tartalmaz!";
        put "A hibát tartalmazó sor:";
        put "%bquote(&text.)";
        put;
        put 'Üdvözlettel,';
        put 'Porsche Finance Group Hungary';
        put 'Member of Porsche Bank Group';
        put '1139 Budapest, Fáy u. 27.';
        put '-----------------------------------------';
    run;

    %if &syserr. eq 0 or &syserr. eq 4 %then %do;
        %put The Email was succesfully sent to the Administrator.;
    %end;
    %else %do;
        %put There was a problem in the email sending!;
    %end;

    filename my_msg clear;

    %exit:
        %put The %upcase(&sysmacroname.) is exiting.;
%mend sending_email_logcheck;
