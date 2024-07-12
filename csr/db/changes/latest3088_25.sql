-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=25
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE csr.score_type_audit_type (
	app_sid						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	score_type_id				NUMBER(10, 0)	NOT NULL,
	internal_audit_type_id		NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_score_type_audit_type PRIMARY KEY (app_sid, score_type_id, internal_audit_type_id)
)
;

CREATE TABLE csrimp.score_type_audit_type (
	csrimp_session_id			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	score_type_id				NUMBER(10, 0)	NOT NULL,
	internal_audit_type_id		NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_score_type_audit_type PRIMARY KEY (csrimp_session_id, score_type_id, internal_audit_type_id)
)
;

create index csr.ix_score_type_au_internal_audi on csr.score_type_audit_type (app_sid, internal_audit_type_id);

-- Alter tables

ALTER TABLE csr.score_type_audit_type ADD CONSTRAINT fk_score_typ_aud_typ_aud_typ
	FOREIGN KEY (app_sid, internal_audit_type_id)
	REFERENCES csr.internal_audit_type (app_sid, internal_audit_type_id)
;

ALTER TABLE csr.score_type_audit_type ADD CONSTRAINT fk_score_typ_aud_typ_score_typ
	FOREIGN KEY (app_sid, score_type_id)
	REFERENCES csr.score_type (app_sid, score_type_id)
;

ALTER TABLE csrimp.score_type_audit_type ADD CONSTRAINT fk_score_type_audit_type_is 
	FOREIGN KEY (csrimp_session_id)
	REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
;

-- *** Grants ***

grant select, insert, update on csr.score_type_audit_type to csrimp;
grant select, insert, update, delete on csrimp.score_type_audit_type to tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../audit_pkg
@../audit_body
@../quick_survey_pkg
@../quick_survey_body
@../csr_app_body
@../schema_pkg
@../schema_body
@../csrimp/imp_body

@update_tail
