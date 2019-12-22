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

CREATE OR REPLACE PROCEDURE AddVertice(
  IN node_name VARCHAR(16);
)
CODE
  EXECUTE "INSERT INTO Vertice(node_name) VALUES(?)", node_name;
END;

CREATE OR REPLACE PROCEDURE RemoveVertice(
  IN node_name VARCHAR(16);
)
CODE
  EXECUTE "DELETE FROM Vertice 
    WHERE node_name=?", node_name;
END;

CREATE OR REPLACE PROCEDURE AddEdge(
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

CREATE OR REPLACE PROCEDURE RemoveEdge(
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