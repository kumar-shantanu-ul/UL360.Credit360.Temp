define version=42
@update_header

ALTER TABLE ALL_COMPONENT
ADD (DELETED NUMBER(1) DEFAULT 0 NOT NULL);

@update_tail

