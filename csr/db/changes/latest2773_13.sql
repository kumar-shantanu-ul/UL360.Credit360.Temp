-- Please update version.sql too -- this keeps clean builds in sync
define version=2773
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE csr.flow_involvement_cover (
	app_sid							NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	user_cover_id					NUMBER(10)		NOT NULL,
	user_giving_cover_sid			NUMBER(10, 0)   NOT NULL,
    user_being_covered_sid			NUMBER(10, 0)   NOT NULL,
	flow_involvement_type_id		NUMBER(10, 0)	NOT NULL,
	flow_item_id					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_flow_inv_cover PRIMARY KEY (app_sid, user_cover_id, user_giving_cover_sid, user_being_covered_sid, flow_involvement_type_id, flow_item_id),
	CONSTRAINT fk_flow_inv_cover_id FOREIGN KEY (app_sid, user_cover_id, user_giving_cover_sid, user_being_covered_sid) 
		REFERENCES csr.user_cover(app_sid, user_cover_id, user_giving_cover_sid, user_being_covered_sid),
	CONSTRAINT fk_flow_inv_cover_fit FOREIGN KEY (app_sid, flow_involvement_type_id)
		REFERENCES csr.flow_involvement_type (app_sid, flow_involvement_type_id),
	CONSTRAINT fk_flow_inv_cover_fi FOREIGN KEY (app_sid, flow_item_id)
		REFERENCES csr.flow_item (app_sid, flow_item_id)
);

CREATE TABLE CSRIMP.FLOW_INVOLVEMENT_COVER
(
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	USER_COVER_ID					NUMBER(10)		NOT NULL,
	USER_GIVING_COVER_SID			NUMBER(10, 0)   NOT NULL,
    USER_BEING_COVERED_SID			NUMBER(10, 0)   NOT NULL,
	FLOW_INVOLVEMENT_TYPE_ID		NUMBER(10, 0)	NOT NULL,
	FLOW_ITEM_ID					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_FLOW_INV_COVER PRIMARY KEY (CSRIMP_SESSION_ID, USER_COVER_ID, USER_GIVING_COVER_SID, USER_BEING_COVERED_SID, FLOW_INVOLVEMENT_TYPE_ID, FLOW_ITEM_ID),
	CONSTRAINT FK_FLOW_INV_COVER_IS FOREIGN KEY	(CSRIMP_SESSION_ID) 
		REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- Alter tables

ALTER TABLE csr.flow_item_involvement
ADD CONSTRAINT UK_FLOW_ITEM_INV UNIQUE (flow_item_id, flow_involvement_type_id, user_sid);

-- *** Grants ***

grant insert on csr.flow_involvement_cover to csrimp;
grant select,insert,update,delete on csrimp.flow_involvement_cover to web_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **


-- *** Packages ***

@..\user_cover_body
@..\unit_test_pkg
@..\unit_test_body

@..\csr_app_body
@..\csrimp\imp_body

@update_tail
