CREATE OR REPLACE PACKAGE donations.bae_helper_pkg
IS

PROCEDURE AfterSave(
    in_donation_id			IN	security_pkg.T_SID_ID
);


PROCEDURE GetFieldMappings(
	out_cur		OUT	security_pkg.T_OUTPUT_CUR	
);

END bae_helper_pkg;
/