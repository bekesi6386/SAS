%macro makedir(dir) /minoperator des= 'Make a directory if it is not exist.'; 
    %local os_sys rc;

    %if (%index(&syshostinfolong., WIN) gt 0) %then %do;
        %let os_sys = WINDOWS;
        options noxwait;
    %end;
    %else %do;
        %let os_sys = LINUX;
    %end;

    %put;
    %put &=os_sys;

    %if %bquote(&dir.) eq %then %do;
        %put;
        %put The parameter is missing!;
        %put The &=sysmacroname is exiting.;
        %goto exit;
        %put;
    %end;

    %let rc = %sysfunc(fileexist(&dir.));
    %if (&rc. ne 0) %then %do;
        %put;
        %put The directory &=dir. already exist!;
        %put The &=sysmacroname is exiting.;
        %goto exit;
        %put;  
    %end;

    %put;
    %put Creating &=dir.;

    %if (&os_sys. eq WINDOWS) %then %do;
        %sysexec md &dir.;
    %end;
    %else %if (&os_sys. eq LINUX) %then %do;
        %sysexec mkdir &dir.;
    %end;

    %if (&sysrc. eq 0) %then %do;
        %put;
        %put The directory created!;
        %put;
    %end;
    %else %do;
        %put;
        %put There was a problem with the creation!;
        %put &=syserrortext;
        %put;
    %end;

    %exit:
        %symdel os_sys rc /NOWARN;
%mend makedir;

/*
%makedir()
%makedir(c:\proba_dir)
*/
