-- Please update version.sql too -- this keeps clean builds in sync
define version=54
@update_header

alter table delegation add (grid_xml clob null);


DROP TYPE T_FROM_TO;

CREATE OR REPLACE TYPE T_FROM_TO_ROW AS 
  OBJECT ( 
	FROM_SID	NUMBER(10,0),
	TO_SID		NUMBER(10,0)
  );
/
CREATE OR REPLACE TYPE T_FROM_TO_TABLE AS 
  TABLE OF T_FROM_TO_ROW;
/


CREATE TABLE VERSION(
    DB_VERSION    NUMBER(10, 0)     DEFAULT 0 NOT NULL
)
;

insert into version (db_version) values (54);
commit;

@update_tail
