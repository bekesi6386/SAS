/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Send text+attachment or just html attachment type email.
    Parameter: content_type: TEXT or PROC
               input: TEXT type: txt file full path. This will be the email body.
                      PROC type: data set table table and html output to attach separated by '#'
                      emailid: email options emailid
                      to: the person(s) to send
                          maximum: 255 characters
                      from: the person(s) from
                            maximum: 255 characters
                      cc: send copy to the the person(s)
                          maximum: 255 characters
                      subject: the theme of the email
                      replyto: the person(s) to reply
                               maximum: 255 characters
                      importance: LOW NORMAL HIGH 
                                  default: NORMAL
                      sender: If the message cannot be delivered, a notification is sent ti the sender email address.
                      bcc: secret send copy to the the person(s)
                           maximum: 255 characters
                      sensitivity: NORMAL PRIVATE PERSONAL CONFIDENTAL COMPANY 
                                   default: NORMAL
    Inner macro call: %put_params_to_log
                      %parameter_check
    Created at: 2022.01.06.
    Modified at: 2022.01.12. - Header fix

    Use cases:
        options mprint mlogic;

        1:  %email_sending(text
                            , \\srv3\users$\bekesid\proba.txt
                            , bekesid@mnb.hu
                            , bekesid@mnb.hu karolyid@mnb.hu
                            , bekesid@mnb.hu
                            , 
                            , PROBA_CHECKLOG_EREDMENY)

            %email_sending(PROC
                            , work.CHECKLOG_TABLE#\\srv3\users$\bekesid\proba.html
                            , bekesid@mnb.hu
                            , bekesid@mnb.hu karolyid@mnb.hu
                            , bekesid@mnb.hu
                            , 
                            , PROBA_CHECKLOG_EREDMENY)
**/

%macro email_sending(content_type
                     , input
                     , emailid
                     , to
                     , from
                     , cc
                     , subject
                     , attach
                     , replyto
                     , importance
                     , sender
                     , bcc 
                     , sensitivity) / minoperator
                                      mindelimiter= ' ';

    /* print params and values to log */
    %put_params_to_log(email_sending)

    %local param_err i to_element from_element sender_element bcc_element cc_element replyto_element attach_element
           to_parameter from_parameter sender_parameter bcc_parameter cc_parameter replyto_parameter attach_parameter
           input_data_table input_dir_name input_table_name
    ;

    /* content_type check */
    %parameter_check(content_type, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    %let content_type = %upcase(&content_type.);

    %if NOT (%bquote(&content_type.) IN (TEXT PROC)) %then %do;
        %put The content_type parameter must be in the list: (TEXT PROC)! (&=content_type);
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* input check */
    %parameter_check(input, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    %if (%bquote(&content_type.) eq TEXT) %then %do;
        %parameter_check(input, FILE_EXIST, param_err)
        %if (&param_err.) %then %do;
            %put The %upcase(&sysmacroname.) is exiting...;
            %put;
            %goto eom_param_err;
        %end;
    %end;

    %if (%bquote(&content_type.) eq PROC) %then %do;
        %if (%sysfunc(countw(&input., %str(#))) lt 2) %then %do;
            %put Input parameter in PROC mode must be two element (data set table and html file full path)! (&=input);
            %put The %upcase(&sysmacroname.) is exiting...;
            %put;
            %goto eom_param_err;
        %end;

        %let input_data_table = %scan(&input., 1, %str(#));

        %if (%sysfunc(index(&input_data_table., %str(.))) gt 0) %then %do;
            %let input_dir_name   = %scan(&input_data_table., -2, %str(.));
            %let input_table_name = %scan(&input_data_table., -1, %str(.));
        %end;
        %else %do;
            %let input_dir_name   = work;
            %let input_table_name = &input_data_table.;
        %end;

        %if (%length(&input_dir_name.) gt 8) %then %do;
            %put;
            %put There input directory name (&=input_dir_name) is too long (%length(&input_dir_name.))!;
            %put The %upcase(&sysmacroname.) is exiting...;
            %put;
            %goto eom_param_err;
        %end;

        %if (%length(&input_table_name.) gt 32) %then %do;
            %put;
            %put There input table name (&=input_table_name) is too long (%length(&input_table_name.))!;
            %put The %upcase(&sysmacroname.) is exiting...;
            %put;
            %goto eom_param_err;
        %end;

        %let ods_html_file = %scan(&input., 2, %str(#));

        %delete_file(&ods_html_file.)
    %end;

    /* emailid check */
    %parameter_check(emailid, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* to check */
    %parameter_check(to, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    %if (%length(&from.) gt 255) %then %do;
        %put The upper limit for to parameter is 255! (%length(&to.));
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* from check */
    %parameter_check(from, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    %if (%length(&from.) gt 255) %then %do;
        %put The upper limit for from parameter is 255! (%length(&from.));
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* cc check */
    %if (%length(&cc.) gt 255) %then %do;
        %put The upper limit for cc parameter is 255! (%length(&cc.));
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* subject check */
    %parameter_check(subject, PARAM_NULL, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* replyto check */
    %if (%length(&cc.) gt 255) %then %do;
        %put The upper limit for cc parameter is 255! (%length(&cc.));
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* importance check */
    %if (%bquote(&importance.) ne) %then %do;
        %if NOT (%bquote(upcase(&importance.)) IN (LOW NORMAL HIGH)) %then %do;
            %put The importance parameter be in the list: (LOW NORMAL HIGH)! (&=importance);
            %put The %upcase(&sysmacroname.) is exiting...;
            %put;
            %goto eom_param_err;
        %end;
    %end;

    /* bcc check */
    %if (%length(&bcc.) gt 255) %then %do;
        %put The upper limit for bcc parameter is 255! (%length(&bcc.));
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto eom_param_err;
    %end;

    /* sensitivity check */
    %if (%bquote(&sensitivity.) ne) %then %do;
        %if NOT (%bquote(upcase(&sensitivity.)) IN (NORMAL PRIVATE PERSONAL CONFIDENTAL COMPANY)) %then %do;
            %put The sensitivity parameter be in the list: (NORMAL PRIVATE PERSONAL CONFIDENTAL COMPANY)! (&=sensitivity);
            %put The %upcase(&sysmacroname.) is exiting...;
            %put;
            %goto eom_param_err;
        %end;
    %end;

    /* complete parameters */
    %do i=1 %to %sysfunc(countw(&to., %str( )));
       %let to_element = %scan(&to., &i., %str( ));

       %let to_parameter = &to_parameter. "&to_element.";
    %end;

    %let to_parameter = (&to_parameter.);

    %do i=1 %to %sysfunc(countw(&from., %str( )));
        %let from_element = %scan(&from., &i., %str( ));

        %let from_parameter = &from_parameter. "&from_element.";
    %end;

    %let from_parameter = (&from_parameter.);
    
    %if (%bquote(&sender.) ne) %then %do;
        %do i=1 %to %sysfunc(countw(&sender., %str( )));
            %let sender_element = %scan(&sender., &i., %str( ));

            %let sender_parameter = &sender_parameter. "&sender_element.";
        %end;

        %let sender_parameter = (&sender_parameter.);
    %end;
    %else %do;
        %let sender_parameter = '';
    %end;
    
    %if (%bquote(&bcc.) ne) %then %do;
        %do i=1 %to %sysfunc(countw(&bcc., %str( )));
            %let bcc_element = %scan(&bcc., &i., %str( ));

            %let bcc_parameter = &bcc_parameter. "&bcc_element.";
        %end;

        %let bcc_parameter = (&bcc_parameter.);
    %end;
    %else %do;
        %let bcc_parameter = '';
    %end;

    %if (%bquote(&cc.) ne) %then %do;
        %do i=1 %to %sysfunc(countw(&cc., %str( )));
            %let cc_element = %scan(&cc., &i., %str( ));

            %let cc_parameter = &cc_parameter. "&cc_element.";
        %end;

        %let cc_parameter = (&cc_parameter.);
    %end;
    %else %do;
        %let cc_parameter = '';
    %end;

    %if (%bquote(&replyto.) ne) %then %do;
        %do i=1 %to %sysfunc(countw(&replyto., %str( )));
            %let replyto_element = %scan(&replyto., &i., %str( ));

            %let replyto_parameter = &replyto_parameter. "&replyto_element.";
        %end;

        %let replyto_parameter = (&replyto_parameter.);
    %end;
    %else %do;
        %let replyto_parameter = '';
    %end;

    %if (%bquote(&attach.) ne) %then %do;
        %do i=1 %to %sysfunc(countw(&attach., %str( )));
            %let attach_element = %scan(&attach., &i., %str( ));

            %let attach_parameter = &attach_parameter. "&attach_element.";
        %end;

        %let attach_parameter = (&attach_parameter.);
    %end;
    %else %do;
        %let attach_parameter =;
    %end;

    options emailid= "&emailid.";

    filename outemail email to= &to_parameter.
                            from= &from_parameter.
                            sender= &sender_parameter.
                            bcc= &bcc_parameter.
                            cc= &cc_parameter.
                            replyto= &replyto_parameter.
                            importance= %if (%bquote(&importance.) ne) %then %do;
                                            "&importance."
                                        %end;
                                        %else %do;
                                            'NORMAL'
                                        %end;
                            sensitivity= %if (%bquote(&sensitivity.) ne) %then %do;
                                             "&sensitivity."
                                         %end;
                                         %else %do;
                                             'NORMAL'
                                         %end;
                            subject= "&subject."
                            %if (%bquote(&attach_parameter.) ne) %then %do;
                                attach= &attach_parameter.
                            %end;
    ;

    %if (%bquote(&content_type.) eq TEXT) %then %do;
        filename input "&input." encoding= 'utf-8';

        data _null_;
            file outemail;

            infile input lrecl= 32767 
                         length= linelength
            ;

            informat emailtext $3000.;

            input emailtext $varying3000. linelength;

            put emailtext;
        run;

        filename input clear;
    %end;
    %else %if (%bquote(&content_type.) eq PROC) %then %do;
        ods html body= "&ods_html_file.";

        proc print data= &input_dir_name..&input_table_name.;
        run;

        ods html close;

        data _null_;
            file outemail attach= "&ods_html_file.";
        run;

        %delete_file(&ods_html_file.)
    %end;

    filename outemail clear;

    %eom_param_err:

%mend email_sending;
