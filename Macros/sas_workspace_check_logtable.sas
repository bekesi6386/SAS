data log.SAS_Workspace_Check;
    length drive            $1
           drive_status     $1
           modifiedby       $20
           modificationdate $20
    ;
    do drive= 'C', 'D', 'E', 'S';
        drive_status     = '0';
        modifiedby       = 'BEKESID';
        modificationdate = strip(put(%sysfunc(datetime()), b8601dt.));
        output;
    end;
run;
