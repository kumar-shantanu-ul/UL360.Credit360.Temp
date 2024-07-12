define version=77
@update_header

ALTER TABLE chain.SUPPLIER_RELATIONSHIP DROP COLUMN CAN_SEE_CHILDREN;

CREATE OR REPLACE TYPE chain.T_NUMBER_LIST IS TABLE OF NUMBER(10);
/

ALTER TABLE chain.COMPANY ADD (USER_LEVEL_MESSAGING         NUMBER(10, 0)     DEFAULT 0 NOT NULL);

--
-- TABLE: PURCHASER_FOLLOWER 
--

CREATE TABLE chain.PURCHASER_FOLLOWER(
    APP_SID                  NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    PURCHASER_COMPANY_SID    NUMBER(10, 0)    NOT NULL,
    SUPPLIER_COMPANY_SID     NUMBER(10, 0)    NOT NULL,
    USER_SID                 NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK312 PRIMARY KEY (APP_SID, PURCHASER_COMPANY_SID, SUPPLIER_COMPANY_SID, USER_SID)
)
;

-- 
-- TABLE: SUPPLIER_FOLLOWER 
--

CREATE TABLE chain.SUPPLIER_FOLLOWER(
    APP_SID                  NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    PURCHASER_COMPANY_SID    NUMBER(10, 0)    NOT NULL,
    SUPPLIER_COMPANY_SID     NUMBER(10, 0)    NOT NULL,
    USER_SID                 NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK307 PRIMARY KEY (APP_SID, PURCHASER_COMPANY_SID, SUPPLIER_COMPANY_SID, USER_SID)
)
;

-- 
-- TABLE: PURCHASER_FOLLOWER 
--

ALTER TABLE chain.PURCHASER_FOLLOWER ADD CONSTRAINT RefSUPPLIER_RELATIONSHIP785 
    FOREIGN KEY (APP_SID, PURCHASER_COMPANY_SID, SUPPLIER_COMPANY_SID)
    REFERENCES chain.SUPPLIER_RELATIONSHIP(APP_SID, PURCHASER_COMPANY_SID, SUPPLIER_COMPANY_SID)
;

ALTER TABLE chain.PURCHASER_FOLLOWER ADD CONSTRAINT RefCHAIN_USER786 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES chain.CHAIN_USER(APP_SID, USER_SID)
;

-- 
-- TABLE: SUPPLIER_FOLLOWER 
--

ALTER TABLE chain.SUPPLIER_FOLLOWER ADD CONSTRAINT RefSUPPLIER_RELATIONSHIP787 
    FOREIGN KEY (APP_SID, PURCHASER_COMPANY_SID, SUPPLIER_COMPANY_SID)
    REFERENCES chain.SUPPLIER_RELATIONSHIP(APP_SID, PURCHASER_COMPANY_SID, SUPPLIER_COMPANY_SID)
;

ALTER TABLE chain.SUPPLIER_FOLLOWER ADD CONSTRAINT RefCHAIN_USER788 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES chain.CHAIN_USER(APP_SID, USER_SID)
;



BEGIN
	INSERT INTO chain.supplier_follower
	(app_sid, purchaser_company_sid, supplier_company_sid, user_sid)
	SELECT DISTINCT sr.app_sid, sr.purchaser_company_sid, sr.supplier_company_sid, i.from_user_sid
	  FROM supplier_relationship sr, (
	  			SELECT app_sid, from_company_sid, to_company_sid, from_user_sid
	  			  FROM chain.invitation 
	  			 UNION 
	  			SELECT i.app_sid, i.from_company_sid, i.to_company_sid, iqt.added_by_user_sid
	  			  FROM chain.invitation i, chain.invitation_qnr_type iqt
	  			 WHERE i.app_sid = iqt.app_sid
	  			   AND i.invitation_id = iqt.invitation_id
	  	   ) i
	 WHERE sr.app_sid = i.app_sid
	   AND sr.purchaser_company_sid = i.from_company_sid
	   AND sr.supplier_company_sid = i.to_company_sid;

	INSERT INTO chain.purchaser_follower
	(app_sid, purchaser_company_sid, supplier_company_sid, user_sid)
	SELECT DISTINCT i.app_sid, i.from_company_sid, i.to_company_sid, NVL(cu.merged_to_user_sid, cu.user_sid)
	  FROM chain.supplier_relationship sr, chain.invitation i, chain.chain_user cu
	 WHERE i.app_sid = cu.app_sid
	   AND i.to_user_sid = cu.user_sid
	   AND sr.purchaser_company_sid = i.from_company_sid
	   AND sr.supplier_company_sid = i.to_company_sid;
END;
/

@update_tail