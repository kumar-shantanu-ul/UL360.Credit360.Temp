-- Please update version.sql too -- this keeps clean builds in sync
define version=3173
define minor_version=4
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
DECLARE 
	v_cnt NUMBER(10) := 0;
BEGIN
	FOR r IN (
		SELECT app_sid, compliance_item_id 
		  FROM csr.compliance_item
		 WHERE reference_code IS NULL
	) 
	LOOP 
		v_cnt := v_cnt +1;
		UPDATE csr.compliance_item
		   SET reference_code = 'AUTO_GEN_REF_' || v_cnt
		 WHERE app_sid = r.app_sid
		   AND compliance_item_id = r.compliance_item_id;
	END LOOP;
END;
/

ALTER TABLE csr.compliance_item MODIFY (reference_code NOT NULL);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../compliance_pkg
@../compliance_body

@update_tail
