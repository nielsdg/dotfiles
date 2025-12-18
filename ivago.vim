# Use the following commands in vim to clean up the Ivago ICS file. You need
# to run the first one as many times as needed until ICS file no longer
# changes

%s/\(BEGIN:VEVENT\nUID:.*\nDTSTAMP:.*\nSUMMARY:\)\(.*\)\n\(DTSTART;VALUE=DATE:.*\nEND:VEVENT\)\n\(BEGIN:VEVENT\nUID:.*\nDTSTAMP:.*\nSUMMARY:\)\(.*\)\n\3/\1\2, \5\r\3/g
%s/GLAS/\L\u&
%s/PAPIER/\L\u&
%s/RESTAFVAL/\L\u&
