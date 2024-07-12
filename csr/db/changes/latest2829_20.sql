-- Please update version.sql too -- this keeps clean builds in sync
define version=2829
define minor_version=20
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE chain.capability_flow_capability (
	app_sid					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	flow_capability_id		NUMBER(10, 0) NOT NULL,
	capability_id			NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_cap_flow_cap PRIMARY KEY (app_sid, flow_capability_id, capability_id),
	CONSTRAINT uk_cap_flow_cap_capability UNIQUE (app_sid, capability_id),
	CONSTRAINT fk_cap_flow_cap_capability FOREIGN KEY (capability_id) REFERENCES chain.capability (capability_id)
);

CREATE TABLE CSRIMP.CHAIN_CAPABILITY_FLOW_CAP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	FLOW_CAPABILITY_ID NUMBER(10,0) NOT NULL,
	CAPABILITY_ID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_CHAIN_CAPABI_FLOW_CAPABI PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_CAPABILITY_ID, CAPABILITY_ID),
	CONSTRAINT FK_CHAIN_CAPABI_FLOW_CAPABI_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables
-- *** Grants ***
GRANT select, references ON csr.customer_flow_capability TO chain;
grant select, insert, update, delete on csrimp.chain_capability_flow_cap to web_user;
grant select, insert, update on chain.capability_flow_capability to csr;
grant select, insert, update on chain.capability_flow_capability to csrimp;

-- ** Cross schema constraints ***
ALTER TABLE chain.capability_flow_capability ADD (
	CONSTRAINT fk_cap_flow_cap_flow_cap FOREIGN KEY (app_sid, flow_capability_id) REFERENCES csr.customer_flow_capability (app_sid, flow_capability_id) ON DELETE CASCADE
);

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- This is right in basedata but was wrong on my machine.
UPDATE chain.capability SET capability_type_id = 2 WHERE capability_name = 'Deactivate company';

-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../flow_pkg
@../chain/type_capability_pkg

@../flow_body
@../chain/type_capability_body

@update_tail
