CREATE OR REPLACE PACKAGE csr.dag_pkg AS

TYPE GraphEdgeList IS TABLE OF BINARY_INTEGER INDEX BY BINARY_INTEGER;
TYPE GraphEdgeLists IS TABLE OF GraphEdgeList INDEX BY BINARY_INTEGER;
TYPE Graph IS RECORD (
	edges       					GraphEdgeLists
);

PROCEDURE addEdge
(
	g								IN OUT NOCOPY Graph,
	u								IN BINARY_INTEGER,
	v								IN BINARY_INTEGER,
	weight							IN BINARY_INTEGER
);

PROCEDURE topologicalSort
(
	g								IN OUT NOCOPY Graph,
	topSorted						IN OUT NOCOPY GraphEdgeList
);

FUNCTION longestPath(
	g								IN OUT NOCOPY Graph,
	s								IN BINARY_INTEGER
)
RETURN BINARY_INTEGER;

END;
/
