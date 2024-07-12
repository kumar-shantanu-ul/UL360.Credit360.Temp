-- Please update version.sql too -- this keeps clean builds in sync
define version=61
@update_header

/* check for CSR latest729 */
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM csr.version;
	IF v_version < 729 THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&version||' CANNOT BE APPLIED TO A *** CSR *** DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/

ALTER TABLE donations.DONATION_STATUS ADD (
    WARNING_MSG                 VARCHAR2(2000)
);

ALTER TABLE donations.RECIPIENT ADD (
    ACCOUNT_NUM         VARCHAR2(255),
    SORT_CODE           VARCHAR2(64),
    BANK_NAME           VARCHAR2(255)
);

@../donation_pkg
@../recipient_pkg

@../donation_body
@../recipient_body
@../status_body

@update_tail
