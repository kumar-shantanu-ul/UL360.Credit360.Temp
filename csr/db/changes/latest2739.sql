-- Please update version.sql too -- this keeps clean builds in sync
define version=2739
@update_header

BEGIN
	-- clean all sessions as we adding NOT NULL columns
	for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
		execute immediate 'truncate table csrimp.'||r.table_name;
	end loop;
	delete from csrimp.csrimp_session;
	commit;
END;
/
-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csrimp.SECTION_VERSION  
	MODIFY (TITLE VARCHAR2(2047 BYTE) );

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@update_tail
