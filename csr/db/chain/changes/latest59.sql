define version=59
@update_header

ALTER TABLE COMPONENT_TYPE_CONTAINMENT ADD (
	ALLOW_ADD_EXISTING NUMBER(1, 0) DEFAULT 1 NOT NULL,
	ALLOW_ADD_NEW	   NUMBER(1, 0) DEFAULT 1 NOT NULL
);

CREATE GLOBAL TEMPORARY TABLE TT_COMPONENT_TYPE_CONTAINMENT
(
	CONTAINER_COMPONENT_TYPE_ID	NUMBER(10) NOT NULL,
	CHILD_COMPONENT_TYPE_ID		NUMBER(10) NOT NULL,
	ALLOW_ADD_EXISTING			NUMBER(1)  NOT NULL,
	ALLOW_ADD_NEW				NUMBER(1)  NOT NULL	
)
ON COMMIT PRESERVE ROWS;

@..\chain_pkg
@..\chain_link_pkg
@..\component_pkg

@..\chain_body
@..\chain_link_body
@..\component_body

@..\rls

@update_tail
