-- Please update version.sql too -- this keeps clean builds in sync
define version=3459
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

CREATE GLOBAL TEMPORARY TABLE CMS.TT_REGION_PATH
(
	REGION_SID		NUMBER(10),
	DESCRIPTION		VARCHAR2(1023),
	PATH			VARCHAR2(4000),
	GEO_COUNTRY		VARCHAR2(2)
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE CMS.TT_IND_PATH
(
	IND_SID			NUMBER(10),
	DESCRIPTION		VARCHAR2(1023),
	PATH			VARCHAR2(4000)
) ON COMMIT PRESERVE ROWS;

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
