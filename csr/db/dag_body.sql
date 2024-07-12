CREATE OR REPLACE PACKAGE BODY csr.dag_pkg AS

PROCEDURE addEdge
(
	g								IN OUT NOCOPY Graph,
	u								IN BINARY_INTEGER,
	v								IN BINARY_INTEGER,
	weight							IN BINARY_INTEGER
)
AS
	el								GraphEdgeList;
BEGIN
	g.edges(u)(v) := weight;
	-- ensure the to node exists even if it has no edges
	IF NOT g.edges.EXISTS(v) THEN		
		g.edges(v) := el;
	END IF;
END;

PROCEDURE topologicalSortRecursive
(
	g								IN OUT NOCOPY Graph,
	v								IN BINARY_INTEGER,
	visited							IN OUT NOCOPY GraphEdgeList,
	result							IN OUT NOCOPY GraphEdgeList
)
AS
	i 								BINARY_INTEGER;
BEGIN
	-- Mark the current node as visited
	visited(v) := 1;
 
    -- Follow all the vertices leaving this vertex
    --dbms_output.put_line('top sort on '||v);
    i := g.edges(v).FIRST;
    WHILE i IS NOT NULL LOOP
    	IF NOT visited.EXISTS(i) THEN
    		--dbms_output.put_line('rec top sort on '||i);
    		topologicalSortRecursive(g, i, visited, result);
    	END IF;
    	i := g.edges(v).NEXT(i);
    END LOOP;

	-- Push current vertex to stack which stores topological sort
	result(result.COUNT + 1) := v;
END;

PROCEDURE topologicalSort
(
	g								IN OUT NOCOPY Graph,
	topSorted						IN OUT NOCOPY GraphEdgeList
)
AS 
	visited							GraphEdgeList;
	i								BINARY_INTEGER;
BEGIN
    -- Recurse for all vertices
    i := g.edges.FIRST;
    WHILE i IS NOT NULL LOOP
    	--dbms_output.put_line('edge vertex num ' || i);
    	IF NOT visited.EXISTS(i) THEN
    		topologicalSortRecursive(g, i, visited, topSorted);
    	END IF;
    	i := g.edges.NEXT(i);
    END LOOP;
END;
 
-- Find the longest path from the given vertex
FUNCTION longestPath(
	g								IN OUT NOCOPY Graph,
	s								IN BINARY_INTEGER
)
RETURN BINARY_INTEGER
AS
	visited							GraphEdgeList;
	dist							GraphEdgeList;
	topSorted						GraphEdgeList;
	i								BINARY_INTEGER;
	u								BINARY_INTEGER;
	p								BINARY_INTEGER;
	d								BINARY_INTEGER;
BEGIN
	-- top sort the graph
	topologicalSort(g, topSorted);
	
    -- Initialize distances to source as 0
    dist(s) := 0;
 
    -- Process vertices in topological order
    WHILE topSorted.COUNT > 0 LOOP
        -- Get the next vertex from topological order
        u := topSorted(topSorted.LAST);
        topSorted.DELETE(topSorted.LAST);
 
        -- Update distances of all adjacent vertices
        IF dist.EXISTS(u) THEN
        	i := g.edges(u).FIRST;
        	WHILE i IS NOT NULL LOOP
        		p := dist(u) + g.edges(u)(i);
        		IF NOT dist.EXISTS(i) OR dist(i) < p THEN
        			dist(i) := p;
        		END IF;
        		i := g.edges(u).NEXT(i);
        	END LOOP;
        END IF;
	END LOOP;

    -- Find the longest distance    
  	d := 0;
    i := dist.FIRST;
    WHILE i IS NOT NULL LOOP
    	p := -1;
    	IF dist.EXISTS(i) THEN
    		p := dist(i);
    		d := GREATEST(p, d);
    	END IF;
    	--dbms_output.put_line('vert ' || i || ' dist ' || p);
    	i := dist.NEXT(i);
    END LOOP;

    RETURN d;
END;

end;
/
