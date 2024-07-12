-- Please update version.sql too -- this keeps clean builds in sync
define version=3168
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.issue_scheduled_task ADD region_sid NUMBER(10);

ALTER TABLE csr.issue_scheduled_task ADD CONSTRAINT fk_issue_scheduled_task_region 
	FOREIGN KEY (app_sid, region_sid) 
	REFERENCES csr.region (app_sid, region_sid)
;

CREATE INDEX csr.ix_issue_scheduled_task_region ON csr.issue_scheduled_task (app_sid, region_sid); 

ALTER TABLE csrimp.issue_scheduled_task ADD region_sid NUMBER(10);
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

EXEC security.user_pkg.logonadmin('');

BEGIN
	FOR task in (
		SELECT ist.issue_scheduled_task_id, COALESCE(cir.region_sid, cp.region_sid) region_sid, ist.app_sid
		  FROM csr.issue_scheduled_task ist
		  LEFT JOIN csr.comp_item_region_sched_issue cirsi
			ON cirsi.issue_scheduled_task_id = ist.issue_scheduled_task_id AND cirsi.app_sid = ist.app_sid
		  LEFT JOIN csr.compliance_item_region cir
			ON cirsi.flow_item_id = cir.flow_item_id AND cirsi.app_sid = cir.app_sid
		  LEFT JOIN csr.comp_permit_sched_issue cpsi
			ON cpsi.issue_scheduled_task_id = ist.issue_scheduled_task_id AND cpsi.app_sid = ist.app_sid
		  LEFT JOIN csr.compliance_permit cp
			ON cpsi.flow_item_id = cp.flow_item_id AND cpsi.app_sid = cp.app_sid
		 WHERE ist.region_sid IS NULL AND COALESCE(cir.region_sid, cp.region_sid) IS NOT NULL
	)
	LOOP
		UPDATE csr.issue_scheduled_task 
		   SET region_sid = task.region_sid
		 WHERE issue_scheduled_task_id = task.issue_scheduled_task_id
		   AND app_sid = task.app_sid;
	END LOOP;
END;
/



BEGIN
	FOR task_issue in (
		SELECT i.issue_id, COALESCE(cir.region_sid, cp.region_sid) region_sid, i.app_sid
		  FROM csr.issue i
		  LEFT JOIN csr.issue_compliance_region icr
		  ON i.issue_compliance_region_id = icr.issue_compliance_region_id AND i.app_sid = icr.app_sid
		  LEFT JOIN csr.compliance_item_region cir ON icr.flow_item_id = cir.flow_item_id AND icr.app_sid = cir.app_sid
		  LEFT JOIN csr.compliance_permit cp ON i.permit_id = cp.compliance_permit_id AND i.app_sid = cp.app_sid 
		 WHERE i.region_sid IS NULL AND COALESCE(cir.region_sid, cp.region_sid) IS NOT NULL
	)
	LOOP
		UPDATE csr.issue 
		   SET region_sid =  task_issue.region_sid
		 WHERE issue_id = task_issue.issue_id
		   AND app_sid = task_issue.app_sid;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../issue_pkg

@../issue_body
@../permit_body
@../compliance_body
@../compliance_register_report_body
@../permit_report_body
@../schema_body
@../csrimp/imp_body

@update_tail
