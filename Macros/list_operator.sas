%macro list_operator(operator, list_part1, list_part2) / des= 'Create the UNION EXCEPT INTERSECT operator with list'
                                                         minoperator
                                                         mindelimiter= ' ';

    %let operator = %upcase(&operator.);

    %if NOT (%bquote(&operator.) IN (UNION EXCEPT INTERSECT)) %then %do;
        %put The operator does not exist!;
        %put The %upcase(&sysmacroname.) is exiting!;
        %goto eom;
    %end;

    %if (%bquote(&list_part1.) eq) and (%bquote(&list_part2.) eq) %then %do;
        %put The lists are empty!;
        %put The %upcase(&sysmacroname.) is exiting!;
        %goto eom;
    %end;

    %local new_list i word word_length where;

    %let list_part1 = %upcase(&list_part1.);
    %let list_part2 = %upcase(&list_part2.);

    %if (&operator. eq UNION) %then %do;
        /* if one is empty, the result is OK */
        %let new_list = &list_part1.%str( )&list_part2.;
    %end;
    %else %if (&operator. eq EXCEPT) %then %do;
        /* if missing list_part2 */
        %let new_list = &list_part1.;

        %if (%bquote(&list_part2.) ne) %then %do;
            %do i=1 %to %sysfunc(countw(&list_part2., %str( )));
                %let word        = %scan(&list_part2., &i., %str( ));
                %let word_length = %length(&word.);
                %let where       = %sysfunc(indexw(&new_list., &word.));

                %if (&where. gt 0) %then %do;
                    /* first in the list */
                    %if (&where. eq 1) %then %do;
                        %if (&new_list. eq &word.) %then %do;
                            %let new_list = ;
                        %end;
                        %else %do;
                            /* beginning of the next word */
                            %let new_list = %sysfunc(substrn(&new_list., %eval(&word_length. + 2)));
                        %end;
                    %end;
                    /* last in the list */
                    %else %if (&where. eq %eval(%length(&new_list.) - &word_length. + 1)) %then %do;
                        /* end of the previous word */
                        %let new_list = %sysfunc(substrn(&new_list., 1, %eval(&where. - 2)));
                    %end;
                    %else %do;
                        /* in the middle of the list */
                        %let new_list = %sysfunc(catx(%str( )
                                                      , %sysfunc(substrn(&new_list., 0, &where.))
                                                      , %sysfunc(substrn(&new_list., %eval(&where. + %length(&word.))))));
                    %end;
                %end;
            %end;
        %end;
    %end;
    %else %if (&operator. eq INTERSECT) %then %do;
        %if (%bquote(&list_part1.) ne) %then %do;
            %if (%bquote(&list_part2.) ne) %then %do;
                %do i= 1 %to %sysfunc(countw(&list_part1., %str( )));
                    %let word = %scan(&list_part1., &i., %str( ));

                    %if (%sysfunc(indexw(&list_part2., &word.)) gt 0) %then %do;
                        %let new_list = &new_list.%str( )&word.;
                    %end;
                %end;
            %end;
            %else %do;
                %let new_list = &list_part1.;
            %end;
        %end;
    %end;

    %do;
        %distinctlist(&new_list.)
    %end;

    %eom:
%mend list_operator;

/*
%put %list_operator(UNION, a b c v f, e f g h a b);

%put %list_operator(EXCEPT, a b c v f, c v f);

%put %list_operator(EXCEPT, a, a);

%put %list_operator(INTERSECT, a b c d e, e f g c d);
*/
