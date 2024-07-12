-- Please update version.sql too -- this keeps clean builds in sync
define version=3060
define minor_version=22
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE chain.saved_filter_column (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	saved_filter_sid				NUMBER(10) NOT NULL,
	column_name						VARCHAR2(255) NOT NULL,
	pos								NUMBER(10) NOT NULL,
	width							NUMBER(10),
	CONSTRAINT pk_saved_filter_column PRIMARY KEY (app_sid, saved_filter_sid, column_name),
	CONSTRAINT fk_saved_fltr_col_saved_fltr FOREIGN KEY (app_sid, saved_filter_sid)
		REFERENCES chain.saved_filter (app_sid, saved_filter_sid)
);

CREATE TABLE csrimp.chain_saved_filter_column (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	saved_filter_sid				NUMBER(10) NOT NULL,
	column_name						VARCHAR2(255) NOT NULL,
	pos								NUMBER(10) NOT NULL,
	width							NUMBER(10),
	CONSTRAINT pk_chain_saved_filter_column PRIMARY KEY (csrimp_session_id, saved_filter_sid, column_name),
	CONSTRAINT fk_chain_saved_fltr_col_is FOREIGN KEY
		(csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE chain.saved_filter ADD (
	order_by						VARCHAR2(255),
	order_direction					VARCHAR2(4),
	results_per_page				NUMBER(10)
);

ALTER TABLE csrimp.chain_saved_filter ADD (
	order_by						VARCHAR2(255),
	order_direction					VARCHAR2(4),
	results_per_page				NUMBER(10)
);

-- *** Grants ***
grant select, insert, update, delete on csrimp.chain_saved_filter_column to tool_user;
grant select, insert, update on chain.saved_filter_column to csrimp;
grant select on chain.saved_filter_column to csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/filter_pkg
@../schema_pkg

@../chain/filter_body
@../chain/chain_body
@../schema_body
@../csrimp/imp_body

@update_tail
