-- Please update version.sql too -- this keeps clean builds in sync
define version=3440
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CSR.CUSTOMER ADD RENDER_CHARTS_AS_SVG NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CK_RENDER_CHARTS_AS_SVG CHECK (RENDER_CHARTS_AS_SVG IN (0,1));
ALTER TABLE CSRIMP.CUSTOMER ADD RENDER_CHARTS_AS_SVG NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.CUSTOMER MODIFY (RENDER_CHARTS_AS_SVG DEFAULT NULL);
ALTER TABLE CSRIMP.CUSTOMER ADD CONSTRAINT CK_RENDER_CHARTS_AS_SVG CHECK (RENDER_CHARTS_AS_SVG IN (0,1));


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP)
	VALUES (75, 'Toggle render charts as SVG', 'Toggles between rendering charts as SVG or PNG (Default, historic behaviour)', 'ToggleRenderChartsAsSvg');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../customer_pkg
@../util_script_pkg

@../customer_body
@../util_script_body

@update_tail
