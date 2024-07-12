-- Please update version.sql too -- this keeps clean builds in sync
define version=1563
@update_header

BEGIN
	FOR r IN (
		SELECT * FROM dual
		 WHERE NOT EXISTS (SELECT 1 FROM all_tables WHERE owner='CSR' and table_name='TEMP_REGION_TREE')
	) LOOP
		EXECUTE IMMEDIATE 'CREATE GLOBAL TEMPORARY TABLE CSR.temp_region_tree
		(
			root_region_sid		number(10) not null,
			child_region_sid	number(10) not null
		) ON COMMIT DELETE ROWS';
		EXECUTE IMMEDIATE 'CREATE INDEX CSR.ix_temp_region_tree_root ON CSR.temp_region_tree(root_region_sid)';
		EXECUTE IMMEDIATE 'CREATE INDEX CSR.ix_temp_region_tree_child ON CSR.temp_region_tree(child_region_sid)';
	END LOOP;
END;
/

-- Trigger scrag to run on all existing customers
BEGIN
	security.user_pkg.LogonAdmin;
	FOR r IN (
		SELECT c.app_sid, c.host, aig.aggregate_ind_group_id
		  FROM csr.customer c
		  JOIN csr.aggregate_ind_group aig ON c.app_sid = aig.app_sid
		 WHERE aig.name = 'InternalAudit'
	) LOOP
		UPDATE csr.app_lock
		   SET dummy = 1
		 WHERE lock_type = 1
		   AND app_sid = r.app_sid;
		
		security.user_pkg.LogonAdmin(r.host);
		MERGE /*+ALL_ROWS*/ INTO csr.aggregate_ind_calc_job aicj
		USING (SELECT 1
				 FROM dual) r
			   ON (aicj.aggregate_ind_group_id = r.aggregate_ind_group_id)
			 WHEN MATCHED THEN
				UPDATE
				   SET aicj.start_dtm = LEAST(aicj.start_dtm, date '1990-01-01'),
					   aicj.end_dtm = GREATEST(aicj.end_dtm, date '2020-01-01')
			 WHEN NOT MATCHED THEN
				INSERT (aicj.aggregate_ind_group_id, aicj.start_dtm, aicj.end_dtm)
				VALUES (r.aggregate_ind_group_id, date '1990-01-01', date '2020-01-01');
	END LOOP;
END;
/

@..\audit_body

@update_tail
