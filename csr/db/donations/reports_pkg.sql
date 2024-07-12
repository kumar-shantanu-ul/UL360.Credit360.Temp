CREATE OR REPLACE PACKAGE DONATIONS.reports_Pkg
IS

PROCEDURE GetRecipients(
	out_cur		OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPossibleDupeRecipients(
	out_cur		OUT security_pkg.T_OUTPUT_CUR
);


END reports_Pkg;
/
