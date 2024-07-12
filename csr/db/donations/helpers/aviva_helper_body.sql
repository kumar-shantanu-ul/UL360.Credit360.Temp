CREATE OR REPLACE PACKAGE BODY aviva_helper_pkg
IS


PROCEDURE AfterSave(
    in_donation_id			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE GetFieldMappings(
	out_cur		OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_oracle_schema		csr.customer.oracle_schema%TYPE;
BEGIN
	SELECT oracle_schema 
	  INTO v_oracle_schema
	  FROM csr.customer
	 WHERE app_sid = SYS_CONTEXT('security', 'app');
	 
	OPEN out_cur FOR
		'SELECT sf.label, actual_field_num, target_field_num, indirect_actual_field_num, indirect_target_field_num, total_actual_field_num, s.section_id, s.title, s.type, s.extra_field_guid, s.beneficiary_new_field_num, s.beneficiary_exist_field_num'
		|| ' FROM '||v_oracle_schema||'.section s, '||v_oracle_schema||'.section_field sf'
		|| ' WHERE s.section_id = sf.section_id'
		|| ' AND sf.app_sid = :1'
		|| ' ORDER BY s.pos, sf.pos'
		USING sys_context('security', 'app');
END;

END aviva_helper_pkg;
/

