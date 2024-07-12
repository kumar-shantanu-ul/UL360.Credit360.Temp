-- Please update version.sql too -- this keeps clean builds in sync
define version=633
@update_header

INSERT INTO csr.PORTLET (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (portlet_id_seq.nextval, 'Region roles', 'Credit360.Portlets.RegionRoles', '/csr/site/portal/Portlets/RegionRoles.js');
INSERT INTO csr.PORTLET (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (portlet_id_seq.nextval, 'Philips - Site ORUs', 'Philips.Portlets.SiteORUs', '/philips/site/portlets/SiteORUs.js');

CREATE OR REPLACE VIEW csr.V$TAB_USER AS
	SELECT t.TAB_ID, t.APP_SID, t.LAYOUT, t.NAME, t.IS_SHARED, tu.USER_SID, tu.POS, tu.IS_OWNER, tu.IS_HIDDEN, t.PORTAL_GROUP
	  FROM TAB t, TAB_USER tu
	 WHERE t.TAB_ID = tu.TAB_ID;

CREATE TABLE csr.DELEGATION_ROLE (
    APP_SID         NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DELEGATION_SID  NUMBER(10) NOT NULL,
    ROLE_SID        NUMBER(10) NOT NULL,
    IS_READ_ONLY	NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_DELEGATION_ROLE PRIMARY KEY (APP_SID, DELEGATION_SID, ROLE_SID)
);
 
ALTER TABLE csr.DELEGATION_ROLE ADD CONSTRAINT FK_DELEG_ROLE_DELEG
    FOREIGN KEY (APP_SID, DELEGATION_SID)
    REFERENCES csr.DELEGATION(APP_SID, DELEGATION_SID);

ALTER TABLE csr.DELEGATION_ROLE ADD CONSTRAINT FK_DELEG_ROLE_ROLE
    FOREIGN KEY (APP_SID, ROLE_SID)
    REFERENCES csr.ROLE(APP_SID, ROLE_SID);

-- combined "normal" delegation user and via roles
CREATE OR REPLACE VIEW csr.v$delegation_user AS
    SELECT app_sid, delegation_sid, user_sid
      FROM delegation_user
     UNION -- removes duplicates introduced by join to delegation_region etc
    SELECT d.app_sid, d.delegation_sid, rrm.user_sid
      FROM delegation d
        JOIN delegation_role dlr ON d.delegation_sid = dlr.delegation_sid AND d.app_sid = dlr.app_sid
        JOIN delegation_region dr ON d.delegation_sid = dr.delegation_sid AND d.app_sid = dr.app_sid
        JOIN region_role_member rrm ON dr.region_sid = rrm.region_sid AND dlr.role_sid = rrm.role_sid AND dr.app_sid = rrm.app_sid AND dlr.app_sid = rrm.app_sid
        ;

CREATE OR REPLACE VIEW csr.v$deleg_region_role_user AS
    SELECT d.app_sid, d.delegation_sid, dr.region_sid, dlr.role_sid, rrm.user_sid, dlr.is_read_only
      FROM delegation d
        JOIN delegation_role dlr ON d.delegation_sid = dlr.delegation_sid AND d.app_sid = dlr.app_sid
        JOIN delegation_region dr ON d.delegation_sid = dr.delegation_sid AND d.app_sid = dr.app_sid
        JOIN region_role_member rrm ON dr.region_sid = rrm.region_sid AND dlr.role_sid = rrm.role_sid AND dr.app_sid = rrm.app_sid AND dlr.app_sid = rrm.app_sid
        ;

@..\portlet_body

@update_tail
