-- Please update version.sql too -- this keeps clean builds in sync
define version=1426
@update_header

BEGIN
	FOR r IN (
		SELECT * FROM all_sequences WHERE sequence_name='PORTLET_ID_SEQ' AND sequence_owner='CSR'
	) LOOP
		EXECUTE IMMEDIATE 'drop sequence csr.portlet_id_seq';
	END LOOP;
END;
/


@update_tail
