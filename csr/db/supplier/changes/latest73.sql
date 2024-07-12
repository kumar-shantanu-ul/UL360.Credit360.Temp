-- Please update version.sql too -- this keeps clean builds in sync
define version=73
@update_header

ALTER TABLE VERSION ADD (
    PART          VARCHAR2(64)     NULL
);

UPDATE VERSION SET PART='generic';

ALTER TABLE VERSION MODIFY PART NOT NULL;

ALTER TABLE VERSION ADD CONSTRAINT PK127 PRIMARY KEY (PART);

BEGIN
    INSERT INTO VERSION (part, db_version) VALUES ('greentick', 0);
    INSERT INTO VERSION (part, db_version) VALUES ('naturalproducts', 0);
    INSERT INTO VERSION (part, db_version) VALUES ('wood', 0);
    INSERT INTO VERSION (part, db_version) VALUES ('nnsupplier', 0);
END;
/

@update_tail
