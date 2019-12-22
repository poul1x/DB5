DROP TABLE Vertice CASCADE;
DROP TABLE AdjMatrix CASCADE;

CREATE TABLE Vertice(
  node_id INT NOT NULL PRIMARY KEY AUTOINC,
  node_name VARCHAR(16) UNIQUE
);

CREATE TABLE AdjMatrix(
  id_link INT NOT NULL PRIMARY KEY AUTOINC,
  id_in INT,
  id_out INT,
  FOREIGN KEY(id_in) REFERENCES Vertice(node_id)
      ON UPDATE CASCADE 
      ON DELETE CASCADE,
  FOREIGN KEY(id_out) REFERENCES Vertice(node_id)
      ON UPDATE CASCADE 
      ON DELETE CASCADE
);

-- п. 7
CREATE OR REPLACE TABLE VectorP(
  node_id INT NOT NULL PRIMARY KEY,
  prev_node_id INT NOT NULL,
  is_visited INT NOT NULL,
  cost INT
);

-- п. 7
CREATE OR REPLACE TABLE RouteP(
  id INT NOT NULL PRIMARY KEY AUTOINC,
  node_name VARCHAR(16) NOT NULL UNIQUE
);

--|--------------------------------------------------------------------------------
--| 1. Добавление вершины
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE AddVertice(
  IN node_name VARCHAR(16);
)
CODE
  EXECUTE "INSERT INTO Vertice(node_name) VALUES(?)", node_name;
END;

--|--------------------------------------------------------------------------------
--| 2. Удаление вершины
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE RemoveVertice(
  IN node_name VARCHAR(16);
)
CODE
  EXECUTE "DELETE FROM Vertice 
    WHERE node_name=?", node_name;
END;

--|--------------------------------------------------------------------------------
--| 3. Добавление дуги
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE AddArc(
  IN node_name_from VARCHAR(16);
  IN node_name_to VARCHAR(16);
)
DECLARE
VAR node_id_from, node_id_to INT;
CODE
  EXECUTE "SELECT node_id FROM Vertice
    WHERE node_name=?", node_name_from into node_id_from;
  EXECUTE "SELECT node_id FROM Vertice 
    WHERE node_name=?", node_name_to into node_id_to;
  EXECUTE "INSERT INTO AdjMatrix(id_in, id_out) 
    VALUES(?, ?)", node_id_to, node_id_from;
END;

--|--------------------------------------------------------------------------------
--| 4. Удаление дуги
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE RemoveArc(
  IN node_name_from VARCHAR(16);
  IN node_name_to VARCHAR(16);
)
DECLARE
  VAR node_id_from, node_id_to INT;
CODE
  EXECUTE "SELECT node_id FROM Vertice
    WHERE node_name=?", node_name_from into node_id_from;
  EXECUTE "SELECT node_id FROM Vertice 
    WHERE node_name=?", node_name_to into node_id_to;
  EXECUTE "DELETE FROM AdjMatrix 
    WHERE id_in=? AND id_out=?", node_id_to, node_id_from;
END;

 CREATE OR REPLACE PROCEDURE ShowMatrix(
 ) RESULT CURSOR(id_link INT, name_from VARCHAR(16), name_to VARCHAR(16))
 DECLARE
   VAR c typeof(result);
 CODE
  OPEN c FOR 
  "SELECT am.id_link, v1.node_name, v2.node_name
  FROM Vertice v1 JOIN Vertice v2 INNER JOIN AdjMatrix am
  ON v1.node_id=am.id_out AND v2.node_id=am.id_in";
  RETURN c;
 END;

--|--------------------------------------------------------------------------------
--| 5. Определить смежность вершин
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE CheckAdjacency(
  IN node_name_from VARCHAR(16);
  IN node_name_to VARCHAR(16);
) RESULT INT
DECLARE
  VAR cnt, node_id_from, node_id_to INT;
CODE
  EXECUTE "SELECT node_id FROM Vertice
    WHERE node_name=?", node_name_from into node_id_from;
  EXECUTE "SELECT node_id FROM Vertice 
    WHERE node_name=?", node_name_to into node_id_to;
  EXECUTE "SELECT count(*) FROM AdjMatrix
    WHERE id_in=? AND id_out=?", node_id_to, node_id_from into cnt;
  RETURN cnt;
END;

--|--------------------------------------------------------------------------------
--| 6. Определить инцидентность узла к ребру
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE CheckIncidence(
  IN node_name VARCHAR(16);
  IN link_value INT;
) RESULT INT
DECLARE
  VAR node_id INT;
  VAR cnt INT;
CODE
  EXECUTE "SELECT node_id FROM Vertice
    WHERE node_name=?", node_name into node_id;
  EXECUTE "SELECT count(*) FROM AdjMatrix
    WHERE (id_link=? AND id_in=?) OR (id_link=? AND id_out=?)",
    link_value, node_id, link_value, node_id into cnt;
  RETURN cnt;
END;

--|--------------------------------------------------------------------------------
--| 9. Определить наличие циклов в графе
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE FindLoops()
DECLARE
  VAR n INT;
CODE
  LOOP
    EXECUTE "call RemoveNodesWithOnlyInArcs()";
    EXECUTE "SELECT count(*) FROM GetNodesWithOnlyInArcs()" into n;
  UNTIL n = 0;  
END;

--|--------------------------------------------------------------------------------
--| 10. Выделить вершины только с входными дугами
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetNodesWithOnlyInArcs(
) RESULT CURSOR(node_id INT, node_name VARCHAR(16))
DECLARE
  VAR c typeof(result);
CODE
  OPEN c FOR
  "SELECT node_id, node_name FROM Vertice 
  WHERE node_id IN
  SELECT id_in FROM AdjMatrix
  WHERE id_in NOT IN 
  SELECT id_out FROM AdjMatrix";
  RETURN c;
END;

--|--------------------------------------------------------------------------------
--| 11. Удалить вершины только с входными дугами
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE RemoveNodesWithOnlyInArcs()
CODE
  EXECUTE "DELETE FROM Vertice 
    WHERE node_id IN SELECT node_id FROM GetNodesWithOnlyInArcs()";
END;

--|--------------------------------------------------------------------------------
--| 12. Выделить вершины только с выходными дугами
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GetNodesWithOnlyOutArcs(
) RESULT CURSOR(node_id INT, node_name VARCHAR(16))
DECLARE
  VAR c typeof(result);
CODE
  OPEN c FOR
  "SELECT node_id, node_name FROM Vertice 
  WHERE node_id IN
  SELECT id_out FROM AdjMatrix
  WHERE id_out NOT IN 
  SELECT id_in FROM AdjMatrix";
  RETURN c;
END;

--|--------------------------------------------------------------------------------
--| 13. Удалить вершины только с выходными дугами
--|--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE RemoveNodesWithOnlyOutArcs()
CODE
  EXECUTE "DELETE FROM Vertice 
    WHERE node_id IN SELECT node_id FROM GetNodesWithOnlyOutArcs()";
END;

CREATE OR REPLACE PROCEDURE FindLoops()
DECLARE
  VAR n INT;
CODE
  LOOP
    EXECUTE "call RemoveNodesWithOnlyInArcs()";
    EXECUTE "SELECT count(*) FROM GetNodesWithOnlyInArcs()" into n;
  UNTIL n = 0;  
END;

CREATE OR REPLACE PROCEDURE BuildPathMap(
  IN node_name_start VARCHAR(16);
)
DECLARE
  VAR node_id_start, cur_node_id INT;
  VAR cur_node_cost, out_node_cost INT;
  VAR cnt_not_visited INT;
  VAR c CURSOR(node_id INT);
CODE
  /* get start id */
  EXECUTE "select node_id from Vertice 
    where node_name=?", node_name_start into node_id_start; 

  /* VectorP initialization */
  EXECUTE "INSERT INTO VectorP(node_id, prev_node_id, is_visited) 
    SELECT node_id, ?, 0 FROM Vertice", node_id_start;
  EXECUTE "UPDATE VectorP SET cost=0 
    WHERE node_id=?", node_id_start;
  
  LOOP
    /* select min cost of not visited */
    EXECUTE "select min(cost) from VectorP
      WHERE is_visited=0" into cur_node_cost;
    
    /* unreachable nodes are left */
    IF  cur_node_cost=NULL THEN
      BREAK;
    ENDIF;
    
    /* select node which is not visited and has min cost */
    EXECUTE "select node_id from VectorP 
      where is_visited=0 and cost=? LIMIT 1", 
      cur_node_cost into cur_node_id;

    /* get all near destination nodes of current node */
    OPEN c FOR
    "select id_in from AdjMatrix
      WHERE id_out=?", cur_node_id;

    /* update cost for each destination node */
    WHILE NOT outofcursor(c) LOOP
      EXECUTE "select cost from VectorP 
        WHERE node_id=?", c.node_id into out_node_cost;
    
      IF out_node_cost=NULL OR cur_node_cost + 1 < out_node_cost THEN
        EXECUTE "UPDATE VectorP SET cost=? 
          WHERE node_id=?", cur_node_cost + 1, c.node_id;
        EXECUTE "UPDATE VectorP SET prev_node_id=? 
          WHERE node_id=?", cur_node_id, c.node_id;
      ENDIF;

      fetch c;
    ENDLOOP;

    /* mark current node as visited */
    EXECUTE "UPDATE VectorP SET is_visited=1 
      WHERE node_id=?", cur_node_id;

    /* check not visited nodes still exist */
    EXECUTE "select count(node_id) from VectorP 
      where is_visited=0" into cnt_not_visited;

  UNTIL cnt_not_visited = 0;
END;

CREATE OR REPLACE PROCEDURE BuildRouteTo(
  IN node_name_to VARCHAR(16);
) RESULT INT
DECLARE
  VAR node_id_cur_cp, node_id_to INT;
  VAR is_visited, node_id_cur INT;
  VAR node_name_cur VARCHAR(16);
CODE
  EXECUTE "select node_id from Vertice 
    where node_name=?", node_name_to into node_id_to; 
  
  EXECUTE "select is_visited from VectorP 
    where node_id=?", node_id_to into is_visited; 

  IF is_visited=0 THEN
    return -1;
  ENDIF

  node_id_cur := node_id_to;
  node_name_cur := node_name_to;

  LOOP
    EXECUTE "insert into RouteP(node_name)
      values(?)", node_name_cur;

    node_id_cur_cp := node_id_cur;
    EXECUTE "select prev_node_id from VectorP
      WHERE node_id=? AND is_visited=1", node_id_cur into node_id_cur;
    
    EXECUTE "select node_name from Vertice
      WHERE node_id=?", node_id_cur into node_name_cur;

  UNTIL node_id_cur = node_id_cur_cp;  
  return 1;
END;

DELETE FROM Vertice;
DELETE FROM AdjMatrix;
DELETE FROM VectorP;
call AddVertice('A');
call AddVertice('B');
call AddVertice('C');
call AddVertice('D');
call AddArc('A', 'B');
call AddArc('B', 'C');
call AddArc('D', 'B');

call BuildPathMap('A');
call BuildRouteTo('D');
select * from RouteP order by id desc;