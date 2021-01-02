%macro macronameexistcheck(macroname, scope) /minoperator des= 'Check the macroname existence (AUTOMATIC/GLOBAL).';
    %if %bquote(&macroname.) eq %then %do;
        %put;
        %put The macroname parameter is missing!;
        %put The &=sysmacroname is exiting.;
        %goto exit;
    %end;

    %local mexist dsid fetchable rc;

    %let mexist = 0;

    /* FULL */
    %if (%bquote(&scope.) eq) %then %do;
        %let scope = AUTOMATIC GLOBAL;
    %end;

    %let dsid = %sysfunc(open(sashelp.vmacro (where= (scope IN (%upcase(%pattern(&scope., %bquote('#')))) and name eq %upcase("&macroname."))), i));

    %let fetchable = %sysfunc(fetch(&dsid., NOSET));

    %if (&fetchable. eq 0) %then %do;
        %let mexist = 1;
    %end;

    %let rc = %sysfunc(close(&dsid.));

    %do;
        &mexist.
    %end;

    %exit:

%mend macronameexistcheck;

/*
%global i;

%macro test;
    %local test;

    %local i j;

    %let test = %macronameexistcheck(i);

    %put &=test;
%mend test;

%test

%macronameexistcheck(i, global)
%macronameexistcheck(i, local)
macronameexistcheck(i, automatic)
%macronameexistcheck(i)
%macronameexistcheck()
*/
