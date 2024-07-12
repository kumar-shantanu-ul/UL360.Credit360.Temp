-- Please update version.sql too -- this keeps clean builds in sync
define version=46
@update_header

ALTER TABLE IND_TEMPLATE ADD (
	INPUT_LABEL		VARCHAR2(1024)		NULL
);

BEGIN
	UPDATE IND_TEMPLATE
	   SET input_label = description;
	COMMIT;
END;
/

ALTER TABLE IND_TEMPLATE MODIFY
	INPUT_LABEL		VARCHAR2(1024)		NOT NULL
;


DROP TABLE INITIATIVE_PROPERTIES;

CREATE GLOBAL TEMPORARY TABLE INITIATIVE_PROPERTIES
(
	REGION_SID			NUMBER(10, 0)	NOT NULL,
	REGION_DESC			VARCHAR2(1024)	NOT NULL,
	COUNTRY_SID			NUMBER(10, 0)	NOT NULL,
	COUNTRY_DESC		VARCHAR2(1024)	NOT NULL,
	PROPERTY_SID		NUMBER(10, 0)	NULL,
	PROPERTY_DESC		VARCHAR2(1024)	NULL
)
ON COMMIT DELETE ROWS;


-- run as csr
PROMPT Enter connection (e.g. ASPEN)
connect csr/csr@&&1

grant select, references on ind_tag to actions;
grant select, references on search_tag to actions;

-- re-connect to actions to run @update_tail
connect actions/actions@&&1

@update_tail
