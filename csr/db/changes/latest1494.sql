-- Please update version.sql too -- this keeps clean builds in sync
define version=1494
@update_header

ALTER TABLE csr.dataview ADD rank_limit          NUMBER(10, 0)      DEFAULT 0 NOT NULL;
ALTER TABLE csr.dataview ADD rank_ind_sid        NUMBER(10, 0)      NULL;

ALTER TABLE csr.dataview ADD CONSTRAINT dataview_ris_ind 
    FOREIGN KEY (app_sid, rank_ind_sid) REFERENCES csr.ind (app_sid, ind_sid);

@..\dataview_pkg
@..\dataview_body
 
@update_tail
