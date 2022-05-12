/**
    Author: Dávid Békési
    Version: 9.4M5
    Brief: Create the global macro date variables.
    Parameter: SAS date numeric value.
    Inner macro call: %put_params_to_log
                      %parameter_check
    Created at: 2021.10.29.
    Modified at: 2021.11.18. - add &mmdd.
                 2022.01.12. - Header fix
                 2022.03.17. - weekday_hun fix

    Use cases:
        options mprint mlogic;

        1:  %set_dates(%sysfunc(mdy(01,01,2020)))
            %put _global_;

        2:  %set_dates('20feb2020'd)
            %put _global_;

        3:  %set_dates(21979)
            %put _global_;
**/

%macro set_dates(date) / des= 'Create the global macro date variables.';
    %put_params_to_log(set_dates)

    %local param_err i;

    %parameter_check(date, DATE_NUM, param_err)
    %if (&param_err.) %then %do;
        %put The %upcase(&sysmacroname.) is exiting...;
        %put;
        %goto param_err;
    %end;

    data _null_;
        length day week month qtr year weekday 8
               weekday_hun                     $9
        ;

        day     = day(&date.);
        week    = week(&date.);
        month   = month(&date.);
        qtr     = qtr(&date.);
        year    = year(&date.);
        weekday = weekday(&date.);

        select(weekday);
            when(1) weekday_hun = 'Vasárnap';
            when(2) weekday_hun = 'Hétfõ';
            when(3) weekday_hun = 'Kedd';
            when(4) weekday_hun = 'Szerda';
            when(5) weekday_hun = 'Csütörtök';
            when(6) weekday_hun = 'Péntek';
            when(7) weekday_hun = 'Szombat';
            otherwise;
        end;

        /**************** SAS numeric shifts ****************/

        /* day */
        /* -1 -> -5 */
        /* +1 -> +5 */
        call symputx('day',      day,                      'G');
        call symputx('weekday',  weekday,                  'G');
        call symputx('prev_day', intnx('DAY', &date., -1), 'G');
        call symputx('next_day', intnx('DAY', &date.,  1), 'G');

        %do i=2 %to 5;
            call symputx("prev&i._day", intnx('DAY', &date., -&i.), 'G');
            call symputx("next&i._day", intnx('DAY', &date.,  &i.), 'G');
        %end;

        /* week */
        /* 0 */
        call symputx('week', week, 'G');
        /* -1 -> -4 */
        /* +1 -> +4 */
        call symputx('week_begin',      intnx('WEEK', &date.,  0, 'BEGIN'), 'G');
        call symputx('week_end',        intnx('WEEK', &date.,  0, 'END'),   'G');
        call symputx('prev_week_end',   intnx('WEEK', &date., -1, 'END'),   'G');
        call symputx('prev_week_begin', intnx('WEEK', &date., -1, 'BEGIN'), 'G');
        call symputx('prev_week',       intnx('WEEK', &date., -1, 'SAME'),  'G');
        call symputx('next_week_end',   intnx('WEEK', &date.,  1, 'END'),   'G');
        call symputx('next_week_begin', intnx('WEEK', &date.,  1, 'BEGIN'), 'G');
        call symputx('next_week',       intnx('WEEK', &date.,  1, 'SAME'),  'G');

        %do i=2 %to 4;
            call symputx("prev&i._week_end",   intnx('WEEK', &date., -&i., 'END'),   'G');
            call symputx("prev&i._week_begin", intnx('WEEK', &date., -&i., 'BEGIN'), 'G');
            call symputx("prev&i._week",       intnx('WEEK', &date., -&i., 'SAME'),  'G');
            call symputx("next&i._week_end",   intnx('WEEK', &date.,  &i., 'END'),   'G');
            call symputx("next&i._week_begin", intnx('WEEK', &date.,  &i., 'BEGIN'), 'G');
            call symputx("next&i._week",       intnx('WEEK', &date.,  &i., 'SAME'),  'G');
        %end;

        /* month */
        /* 0 */
        call symputx('month', month, 'G');
        /* -1 -> -5 */
        /* +1 -> +5 */
        call symputx('month_begin',      intnx('MONTH', &date.,  0, 'BEGIN'), 'G');
        call symputx('month_end',        intnx('MONTH', &date.,  0, 'END'),   'G');
        call symputx('prev_month_end',   intnx('MONTH', &date., -1, 'END'),   'G');
        call symputx('prev_month_begin', intnx('MONTH', &date., -1, 'BEGIN'), 'G');
        call symputx('prev_month',       intnx('MONTH', &date., -1, 'SAME'),  'G');
        call symputx('next_month_end',   intnx('MONTH', &date.,  1, 'END'),   'G');
        call symputx('next_month_begin', intnx('MONTH', &date.,  1, 'BEGIN'), 'G');
        call symputx('next_month',       intnx('MONTH', &date.,  1, 'SAME'),  'G');

        %do i=2 %to 5;
            call symputx("prev&i._month_end",   intnx('MONTH', &date., -&i., 'END'),   'G');
            call symputx("prev&i._month_begin", intnx('MONTH', &date., -&i., 'BEGIN'), 'G');
            call symputx("prev&i._month",       intnx('MONTH', &date., -&i., 'SAME'),  'G');
            call symputx("next&i._month_end",   intnx('MONTH', &date.,  &i., 'END'),   'G');
            call symputx("next&i._month_begin", intnx('MONTH', &date.,  &i., 'BEGIN'), 'G');
            call symputx("next&i._month",       intnx('MONTH', &date.,  &i., 'SAME'),  'G');
        %end;

        /* qtr */
        /* 0 */
        call symputx('qtr', qtr, 'G');
        /* -1 -> -4 */
        /* +1 -> +4 */
        call symputx('qtr_begin',      intnx('QTR', &date.,  0, 'BEGIN'), 'G');
        call symputx('qtr_end',        intnx('QTR', &date.,  0, 'END'),   'G');
        call symputx('prev_qtr_end',   intnx('QTR', &date., -1, 'END'),   'G');
        call symputx('prev_qtr_begin', intnx('QTR', &date., -1, 'BEGIN'), 'G');
        call symputx('prev_qtr',       intnx('QTR', &date., -1, 'SAME'),  'G');
        call symputx('next_qtr_end',   intnx('QTR', &date.,  1, 'END'),   'G');
        call symputx('next_qtr_begin', intnx('QTR', &date.,  1, 'BEGIN'), 'G');
        call symputx('next_qtr',       intnx('QTR', &date.,  1, 'SAME'),  'G');

        %do i=2 %to 4;
            call symputx("prev&i._qtr_end",   intnx('QTR', &date., -&i., 'END'),   'G');
            call symputx("prev&i._qtr_begin", intnx('QTR', &date., -&i., 'BEGIN'), 'G');
            call symputx("prev&i._qtr",       intnx('QTR', &date., -&i., 'SAME'),  'G');
            call symputx("next&i._qtr_end",   intnx('QTR', &date.,  &i., 'END'),   'G');
            call symputx("next&i._qtr_begin", intnx('QTR', &date.,  &i., 'BEGIN'), 'G');
            call symputx("next&i._qtr",       intnx('QTR', &date.,  &i., 'SAME'),  'G');
        %end;

        /* year */
        /* 0 */
        call symputx('year', year, 'G');
        /* -1 -> -4 */
        /* +1 -> +4 */
        call symputx('year_begin',      intnx('YEAR', &date.,  0, 'BEGIN'), 'G');
        call symputx('year_end',        intnx('YEAR', &date.,  0, 'END'),   'G');
        call symputx('prev_year_end',   intnx('YEAR', &date., -1, 'END'),   'G');
        call symputx('prev_year_begin', intnx('YEAR', &date., -1, 'BEGIN'), 'G');
        call symputx('prev_year',       intnx('YEAR', &date., -1, 'SAME'),  'G');
        call symputx('next_year_end',   intnx('YEAR', &date.,  1, 'END'),   'G');
        call symputx('next_year_begin', intnx('YEAR', &date.,  1, 'BEGIN'), 'G');
        call symputx('next_year',       intnx('YEAR', &date.,  1, 'SAME'),  'G');

        %do i=2 %to 4;
            call symputx("prev&i._year_end",   intnx('YEAR', &date., -&i., 'END'),   'G');
            call symputx("prev&i._year_begin", intnx('YEAR', &date., -&i., 'BEGIN'), 'G');
            call symputx("prev&i._year",       intnx('YEAR', &date., -&i., 'SAME'),  'G');
            call symputx("next&i._year_end",   intnx('YEAR', &date.,  &i., 'END'),   'G');
            call symputx("next&i._year_begin", intnx('YEAR', &date.,  &i., 'BEGIN'), 'G');
            call symputx("next&i._year",       intnx('YEAR', &date.,  &i., 'SAME'),  'G');
        %end;

        /*************** YYYYMMDD char shifts ***************/

        /* day */
        /* 0 */
        /* -1 -> -5 */
        /* +1 -> +5 */
        call symputx('yyyymmdd',    put(&date., yymmddn8.),               'G');
        call symputx('weekday_hun', weekday_hun,                          'G');
        call symputx('weekday_eng', scan(put(&date., weekdate.), 1, ','), 'G');
        %do i=1 %to 5;
            call symputx("yyyymmddp&i.d", put(intnx('DAY', &date., -&i.), yymmddn8.), 'G');
            call symputx("yyyymmddn&i.d", put(intnx('DAY', &date.,  &i.), yymmddn8.), 'G');
        %end;

        /* week */
        /* -1 -> -4 */
        /* +1 -> +4 */
        %do i=1 %to 4;
            call symputx("yyyymmddp&i.w_end",   put(intnx('WEEK', &date., -&i., 'END'),   yymmddn8.), 'G');
            call symputx("yyyymmddp&i.w_begin", put(intnx('WEEK', &date., -&i., 'BEGIN'), yymmddn8.), 'G');
            call symputx("yyyymmddp&i.w",       put(intnx('WEEK', &date., -&i., 'SAME'),  yymmddn8.), 'G');
            call symputx("yyyymmddn&i.w_end",   put(intnx('WEEK', &date.,  &i., 'END'),   yymmddn8.), 'G');
            call symputx("yyyymmddn&i.w_begin", put(intnx('WEEK', &date.,  &i., 'BEGIN'), yymmddn8.), 'G');
            call symputx("yyyymmddn&i.w",       put(intnx('WEEK', &date.,  &i., 'SAME'),  yymmddn8.), 'G');
        %end;

        /* month */
        /* -1 -> -4 */
        /* +1 -> +4 */
        %do i=1 %to 4;
            call symputx("yyyymmddp&i.m_end",   put(intnx('MONTH', &date., -&i., 'END'),   yymmddn8.), 'G');
            call symputx("yyyymmddp&i.m_begin", put(intnx('MONTH', &date., -&i., 'BEGIN'), yymmddn8.), 'G');
            call symputx("yyyymmddp&i.m",       put(intnx('MONTH', &date., -&i., 'SAME'),  yymmddn8.), 'G');
            call symputx("yyyymmddn&i.m_end",   put(intnx('MONTH', &date.,  &i., 'END'),   yymmddn8.), 'G');
            call symputx("yyyymmddn&i.m_begin", put(intnx('MONTH', &date.,  &i., 'BEGIN'), yymmddn8.), 'G');
            call symputx("yyyymmddn&i.m",       put(intnx('MONTH', &date.,  &i., 'SAME'),  yymmddn8.), 'G');
        %end;

        /* qtr */
        /* -1 -> -4 */
        /* +1 -> +4 */
        %do i=1 %to 4;
            call symputx("yyyymmddp&i.q_end",   put(intnx('QTR', &date., -&i., 'END'),   yymmddn8.), 'G');
            call symputx("yyyymmddp&i.q_begin", put(intnx('QTR', &date., -&i., 'BEGIN'), yymmddn8.), 'G');
            call symputx("yyyymmddp&i.q",       put(intnx('QTR', &date., -&i., 'SAME'),  yymmddn8.), 'G');
            call symputx("yyyymmddn&i.q_end",   put(intnx('QTR', &date.,  &i., 'END'),   yymmddn8.), 'G');
            call symputx("yyyymmddn&i.q_begin", put(intnx('QTR', &date.,  &i., 'BEGIN'), yymmddn8.), 'G');
            call symputx("yyyymmddn&i.q",       put(intnx('QTR', &date.,  &i., 'SAME'),  yymmddn8.), 'G');
        %end;

        /* year */
        /* -1 -> -4 */
        /* +1 -> +4 */
        %do i=1 %to 4;
            call symputx("yyyymmddp&i.y_end",   put(intnx('YEAR', &date., -&i., 'END'),   yymmddn8.), 'G');
            call symputx("yyyymmddp&i.y_begin", put(intnx('YEAR', &date., -&i., 'BEGIN'), yymmddn8.), 'G');
            call symputx("yyyymmddp&i.y",       put(intnx('YEAR', &date., -&i., 'SAME'),  yymmddn8.), 'G');
            call symputx("yyyymmddn&i.y_end",   put(intnx('YEAR', &date.,  &i., 'END'),   yymmddn8.), 'G');
            call symputx("yyyymmddn&i.y_begin", put(intnx('YEAR', &date.,  &i., 'BEGIN'), yymmddn8.), 'G');
            call symputx("yyyymmddn&i.y",       put(intnx('YEAR', &date.,  &i., 'SAME'),  yymmddn8.), 'G');
        %end;

        /* yyyymm */
        call symputx('yyyymm', cats(year, put(month, z2.)), 'G');

        /* yyyyqq */
        call symputx('yyyyqq', cats(year, put(qtr, z2.)), 'G');

        /* mmdd */
        call symputx('mmdd', cats(put(month, z2.), put(day, z2.)), 'G');
    run;

    %param_err:

%mend set_dates;
