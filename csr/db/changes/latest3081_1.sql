-- Please update version.sql too -- this keeps clean builds in sync
define version=3081
define minor_version=1
@update_header

-- Not really sure what went on here. Changes were copied to latest3082 but left here with
-- changes script comments and other bits removed.

--CREATE GLOBAL TEMPORARY TABLE csr.tt_audit_capability(
--	internal_audit_sid		NUMBER(10) NOT NULL, 
--	internal_audit_type_id	NUMBER(10) NOT NULL,
--	flow_capability_id		NUMBER(10) NOT NULL,
--	permission_set			NUMBER(10) NOT NULL
--) ON COMMIT DELETE ROWS;
--
--CREATE GLOBAL TEMPORARY TABLE csr.tt_audit_browse(
--	internal_audit_sid			NUMBER(10) NOT NULL, 
--	region_sid					NUMBER(10),
--	region_description			VARCHAR(1023),
--	audit_dtm					DATE NOT NULL,
--	label						VARCHAR(255) NOT NULL,
--	auditor_user_sid			NUMBER(10) NOT NULL,
--	auditor_full_name			VARCHAR(256),
--	custom_audit_id				VARCHAR(295),
--	open_non_compliances		NUMBER,
--	auditor_name				VARCHAR(50),
--	auditor_organisation		VARCHAR(50),
--	auditor_email				VARCHAR(256),
--	region_type					NUMBER(2),
--	region_type_class_name		VARCHAR2(64),
--	short_notes					CLOB,
--	full_notes					CLOB,
--	audit_type_id				NUMBER(10),
--	audit_type_label		 	VARCHAR2(255),
--	internal_audit_type_group_id NUMBER(10),
--	ia_type_group_label		 	VARCHAR2(255),
--	icon_image_filename			VARCHAR2(255),
--	icon_image_sha1				VARCHAR2(40),
--	internal_audit_type_id		NUMBER(10) NOT NULL,
--	flow_sid				 	NUMBER(10),
--	flow_label				  	VARCHAR2(255),
--	flow_item_id				NUMBER(10),
--	current_state_id			NUMBER(10),
--	flow_state_label			VARCHAR2(255),
--	flow_state_lookup_key		VARCHAR2(255),
--	flow_state_is_final		 	NUMBER(1),
--	survey_score_type_id	 	NUMBER(10),
--	survey_score_format_mask 	VARCHAR2(20),
--	survey_overall_max_score 	NUMBER(15,5),
--	survey_score_label			VARCHAR2(255),
--	nc_score_type_id			NUMBER(10),
--	nc_max_score				NUMBER(15,5),
--	nc_score_label				VARCHAR2(255),
--	nc_score_format_mask		VARCHAR2(20),
--	nc_score					NUMBER(15,5),
--	summary_survey_version		NUMBER(10),
--	summary_response_id 		NUMBER(10),
--	summary_survey_label		VARCHAR2(256),
--	summary_survey_sid			NUMBER(10),
--	auditee_user_sid			NUMBER(10),
--	auditee_full_name			VARCHAR2(256),
--	auditee_email				VARCHAR2(256),
--	survey_sid					NUMBER(10),
--	survey_label				VARCHAR2(256),
--	survey_completed			DATE,		
--	survey_response_id			NUMBER(10),
--	survey_version				NUMBER(10),
--	audit_closure_type_id		NUMBER(10),
--	closure_label				VARCHAR2(255),
--	survey_overall_score		NUMBER(15,5),
--	next_audit_due_dtm			DATE
--) ON COMMIT DELETE ROWS;
--
--DROP VIEW csr.v$audit_capability;

@../audit_pkg
@../audit_body

-- *** DDL ***
-- Create tables


-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.


-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
