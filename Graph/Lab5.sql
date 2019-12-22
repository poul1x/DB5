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
