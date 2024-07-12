-- Please update version.sql too -- this keeps clean builds in sync
define version=3343
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
@latestUD4083_packages

DECLARE
	v_audit_msg VARCHAR2(1024);
	v_host		csr.customer.host%TYPE;
BEGIN	
	FOR r IN (
		SELECT DISTINCT imsi.ind_sid, imsi.app_sid
		  FROM csr.initiative_metric_state_ind imsi
		  JOIN csr.ind i ON imsi.ind_sid = i.ind_sid AND imsi.app_sid = i.app_sid
		  JOIN csr.aggregate_ind_group_member aigm ON aigm.ind_sid = imsi.ind_sid and aigm.app_sid = imsi.app_sid
		 WHERE (i.ind_type = 0 OR i.is_system_managed = 0)
		UNION
		SELECT DISTINCT imti.ind_sid, imti.app_sid
		  FROM csr.initiative_metric_tag_ind imti
		  JOIN csr.ind i ON imti.ind_sid = i.ind_sid AND imti.app_sid = i.app_sid
		  JOIN csr.aggregate_ind_group_member aigm ON aigm.ind_sid = imti.ind_sid and aigm.app_sid = imti.app_sid
		 WHERE (i.ind_type = 0 OR i.is_system_managed = 0)
	)
	LOOP
		SELECT host
		  INTO v_host
		  FROM csr.customer c
		 WHERE c.app_sid = r.app_sid;
		
		security.user_pkg.logonadmin(v_host);

		UPDATE csr.ind
		   SET ind_type = 3,
		       is_system_managed = 1
		 WHERE ind_sid = r.ind_sid;

		v_audit_msg := 'Set to system managed and ind type 3 (Initiative metric mapping correction: UD-4083).';
		
		csr.temp_csr_data_pkg.WriteAuditLogEntry(
			in_act_id			=> SYS_CONTEXT('SECURITY', 'ACT'),
			in_audit_type_id	=> 4,  --AUDIT_TYPE_CHANGE_SCHEMA
			in_app_sid			=> SYS_CONTEXT('SECURITY', 'APP'),
			in_object_sid		=> r.ind_sid,
			in_description		=> v_audit_msg
		);
		security.user_pkg.logonadmin();
	END LOOP;
END;
/

DROP PACKAGE csr.temp_csr_data_pkg;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\indicator_body
@..\initiative_metric_body

@..\indicator_pkg

@update_tail
