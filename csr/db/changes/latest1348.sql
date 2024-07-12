-- Please update version.sql too -- this keeps clean builds in sync
define version=1348
@update_header

begin
	for r in (select distinct app_sid
				from csr.internal_audit
			   where internal_audit_type_id is null) loop
		insert into csr.internal_audit_type (app_sid, internal_audit_type_id, label)
		values (r.app_sid, csr.internal_audit_type_id_seq.nextval, 'Default');
		update csr.internal_audit
		   set internal_audit_type_id = csr.internal_audit_type_id_seq.currval
		 where app_sid = r.app_sid
		   and internal_audit_type_id IS NULL;
	end loop;
end;
/

begin
	for r in (select nullable from all_tab_columns where owner='CSR' and table_name='INTERNAL_AUDIT' and column_name='INTERNAL_AUDIT_TYPE_ID' and nullable='Y') loop
		execute immediate 'ALTER TABLE csr.INTERNAL_AUDIT MODIFY INTERNAL_AUDIT_TYPE_ID NOT NULL';
	end loop;
end;
/

@update_tail
