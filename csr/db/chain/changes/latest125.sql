define version=125
@update_header

ALTER TABLE chain.COMPANY ADD (
	SECTOR_ID                    NUMBER(10, 0)
);

CREATE TABLE chain.SECTOR(
    APP_SID        NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    SECTOR_ID      NUMBER(10, 0)    NOT NULL,
    DESCRIPTION    VARCHAR2(255),
    ACTIVE         NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    CONSTRAINT CHK_SECTOR_ACTIVE_IN_0_1 CHECK (ACTIVE IN (0,1)),
    CONSTRAINT PK_SECTOR PRIMARY KEY (APP_SID, SECTOR_ID)
)
;


ALTER TABLE chain.COMPANY ADD CONSTRAINT FK_COMPANY_SECTOR 
    FOREIGN KEY (APP_SID, SECTOR_ID)
    REFERENCES chain.SECTOR(APP_SID, SECTOR_ID)
;


ALTER TABLE chain.SECTOR ADD CONSTRAINT FK_SECTOR_APP_SID 
    FOREIGN KEY (APP_SID)
    REFERENCES chain.CUSTOMER_OPTIONS(APP_SID)
;

CREATE OR REPLACE VIEW chain.v$company AS
	SELECT c.*, cou.name country_name, s.description sector_description
	  FROM chain.company c
	  LEFT JOIN chain.v$country cou ON c.country_code = cou.country_code
	  LEFT JOIN chain.sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.deleted = 0
;

@..\rls
@..\company_pkg
@..\helper_pkg
@..\company_user_pkg
@..\company_body
@..\helper_body
@..\company_filter_body
@..\company_user_body


@update_tail
