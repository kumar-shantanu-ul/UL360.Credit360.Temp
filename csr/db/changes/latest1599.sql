-- Please update version.sql too -- this keeps clean builds in sync
define version=1599
@update_header
--
-- NEW IMPORT TABLES (section related)
--

CREATE TABLE CSRIMP.SECTION_TRANS_COMMENT(
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    SECTION_TRANS_COMMENT_ID    NUMBER(10, 0)    NOT NULL,
    SECTION_SID                 NUMBER(10, 0)    NOT NULL,
    ENTERED_BY_SID              NUMBER(10, 0)    NOT NULL,
    ENTERED_DTM                 DATE             NOT NULL,
    COMMENT_TEXT                CLOB             NOT NULL,
    CONSTRAINT PK_SECTION_TRANS_COMMENT PRIMARY KEY (CSRIMP_SESSION_ID, SECTION_TRANS_COMMENT_ID),
    CONSTRAINT FK_SECTION_TRANS_COMMENT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);


CREATE TABLE CSRIMP.SECTION_ALERT (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SECTION_ALERT_ID          NUMBER(10, 0)    NOT NULL,
    CUSTOMER_ALERT_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    SECTION_SID               NUMBER(10, 0)    NOT NULL,
    RAISED_DTM                DATE             NOT NULL,
    FROM_USER_SID             NUMBER(10, 0)    NOT NULL,
    NOTIFY_USER_SID           NUMBER(10, 0)    NOT NULL,
    FLOW_STATE_ID             NUMBER(10, 0)    NOT NULL,
    ROUTE_STEP_ID             NUMBER(10, 0),
    SENT_DTM                  DATE,
    CANCELLED_DTM             DATE,
    CONSTRAINT PK_SECTION_ALERT PRIMARY KEY (CSRIMP_SESSION_ID, SECTION_ALERT_ID, SECTION_SID),
    CONSTRAINT FK_SECTION_ALERT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);


--
-- NEW COLUMNS
--

ALTER TABLE CSRIMP.ROUTE_STEP 			ADD POS                                  NUMBER(10, 0)    DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.ROUTE_STEP_USER 	ADD REMINDER_SENT_DTM                    DATE;
ALTER TABLE CSRIMP.FLOW_ITEM 			ADD LAST_FLOW_STATE_TRANSITION_ID        NUMBER(10);
ALTER TABLE CSRIMP.FLOW_ITEM 			ADD LAST_FLOW_STATE_LOG_ID               NUMBER(10);
ALTER TABLE CSRIMP.FLOW_STATE 			ADD STATE_COLOUR                         NUMBER(10, 0);
ALTER TABLE CSRIMP.FLOW_STATE 			ADD POS                                  NUMBER(10, 0)    DEFAULT 0 NOT NULL;

--
-- NEW MAP TABLES
--
CREATE TABLE csrimp.map_section_alert (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_section_alert_id			NUMBER(10)	NOT NULL,
	new_section_alert_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_section_alert PRIMARY KEY (old_section_alert_id) USING INDEX,
	CONSTRAINT uk_map_section_alert UNIQUE (new_section_alert_id) USING INDEX,
   CONSTRAINT FK_MAP_SECTION_ALERT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_section_trans_comment (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_section_t_comment_id			NUMBER(10)	NOT NULL,
	new_section_t_comment_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_section_t_comment PRIMARY KEY (old_section_t_comment_id) USING INDEX,
	CONSTRAINT uk_map_section_t_comment UNIQUE (new_section_t_comment_id) USING INDEX,
    CONSTRAINT FK_MAP_SECTION_T_COMMENT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

--
-- GRANTS
--

grant insert, update on csr.flow_item to csrimp;
grant select,insert on csr.section_alert to csrimp;
grant select,insert,update on csr.section_trans_comment to csrimp;
grant select on csr.section_alert_id_seq to csrimp;
grant select on csr.section_trans_comment_id_seq to csrimp;
grant insert,select,update,delete on csrimp.section_alert to web_user;
grant insert,select,update,delete on csrimp.section_trans_comment to web_user;

@../schema_pkg
@../schema_body
@../csrimp/imp_pkg
@../csrimp/imp_body

@update_tail