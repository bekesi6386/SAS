%macro delete_members(member_list, type= DATA) / des= 'Delete MEMBERS from a given library'
                                                 minoperator
                                                 mindelimiter= ' ';
    %if %sysevalf(%superq(member_list)=, boolean) %then %do;
        %goto eom;
    %end;

    %if NOT (%bquote(&type.) IN (ACCESS ALL VIEW CATALOG DATA FDB MDDB PROGRAM VIEW)) %then %do;
        %put The MEMTYPE argument is not valid!;
        %put The %upcase(&sysmacroname.) is exiting!;
        %goto eom;
    %end;
    
    %local distinct_member_list fullname i lib libs j;

    %let distinct_member_list = %distinctlist(%lowcase(&member_list.));

    %do i=1 %to %sysfunc(countw(&distinct_member_list., %str( )));

        %let fullname = %scan(&distinct_member_list., &i., %str( ));

        %if (%sysfunc(exist(&fullname., &type.)) or %index(&fullname., %str(:)) gt 0) %then %do;
            /* ures, ha nincs lib */
            %let lib = %scan(&fullname., -2, %str(.));
            %if (%bquote(&lib.) eq) %then %do;
                %let lib = WORK;
            %end;

            %let libs = %list_operator(UNION, &libs., &lib.);

            %local lib_&lib.;

            %let lib_&lib. = &&lib_&lib.. %scan(&fullname., -1, %str(.));
        %end;
    %end;

    %do j=1 %to %sysfunc(countw(&libs., %str( )));
        %let lib = %scan(&libs., &j., %str( ));
        
        proc datasets lib= &lib. memtype= &type. nolist nodetails nowarn;
            delete &&lib_&lib..
            run;
        quit;
    %end;

    %eom:
%mend delete_members;

/*
%delete_members(work.x: y z x.x:)
*/
