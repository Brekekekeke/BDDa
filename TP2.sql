CREATE TABLE Etudiants (
  NumEtu numeric(10),
  NomEtu VARCHAR(99) NOT NULL,
  PrenomEtu VARCHAR(99) NOT NULL,
  PRIMARY KEY (NumEtu)
);

CREATE TABLE Enseignants (
  NumEns numeric(10),
  NomEns VARCHAR(99) NOT NULL,
  PrenomEns VARCHAR(99) NOT NULL,
  PRIMARY KEY (NumENs)
);

CREATE TABLE Salles (
  NumSal numeric(10),
  NomSal VARCHAR(99) NOT NULL,
  CapaciteSal numeric(10) DEFAULT '0' NOT NULL,
  PRIMARY KEY (NumSal)
);

CREATE TABLE Epreuves (
  NumEpr numeric (10),
  NomEpr VARCHAR(99) NOT NULL,
  DureeEpr INTERVAL DAY TO SECOND(0) NOT NULL,
  PRIMARY KEY (NumEpr)
);

CREATE TABLE Inscriptions (
  NumEtu numeric(10) REFERENCES Etudiants,
  NumEpr numeric(10) REFERENCES Epreuves,
  PRIMARY KEY (NumEtu, NumEpr)
);

CREATE TABLE Horaires (
  NumEpr numeric(10) REFERENCES Epreuves,
  DateHeureDebut TIMESTAMP(0),
  PRIMARY KEY (NumEpr)
  );
  
  CREATE TABLE OCCUPATIONS (
    NumSal numeric(10) REFERENCES Salles,
    NumEpr numeric(10) REFERENCES Epreuves,
    NbPlacesOcc numeric(10) DEFAULT '0' NOT NULL,
    PRIMARY KEY (NumSal, NumEpr)
  );
  
  CREATE TABLE Surveillances (
    NumEns numeric(10) REFERENCES Enseignants,
    DateHeureDebut TIMESTAMP(0),
    NumSal numeric(10) REFERENCES Salles,
    PRIMARY KEY (NumEns, DateHeureDebut)
  );
  
  
  CREATE SEQUENCE seq_NumEns START WITH 1;
  CREATE TRIGGER indentNumEns
    BEFORE INSERT ON Enseignants FOR EACH ROW
    BEGIN
    :New.NumEns := seq_NumEns.nextval;
    END;
    /
    
    CREATE SEQUENCE seq_NumEpr START WITH 1;
    CREATE TRIGGER indentNumEpr
      BEFORE INSERT ON Epreuves FOR EACH ROW
      BEGIN
      :New.NumEpr := seq_NumEpr.nextval;
      END;
      /
      
    CREATE SEQUENCE seq_NumEtu START WITH 1;
    CREATE TRIGGER indentNumEtu
      BEFORE INSERT ON Etudiants FOR EACH ROW
      BEGIN
      :New.NumEtu := seq_NumEtu.nextval;
      END;
      /

    CREATE SEQUENCE seq_NumSal START WITH 1;
    CREATE TRIGGER indentNumSal
      BEFORE INSERT ON Salles FOR EACH ROW
      BEGIN
      :New.NumSal := seq_NumSal.nextval;
      END;
      /
      
      
    INSERT INTO Enseignants (NumEns, NomEns, PrenomEns) VALUES (1, 'Svete', 'Pierre');
    INSERT INTO Enseignants (NumEns, NomEns, PrenomEns) VALUES (2, 'Spor', 'Paul');
    INSERT INTO Enseignants (NumEns, NomEns, PrenomEns) VALUES (3, 'Fransai', 'Jacques');
    INSERT INTO Enseignants (NumEns, NomEns, PrenomEns) VALUES (4, 'Mat', 'Jean');
    INSERT INTO Enseignants (NumEns, NomEns, PrenomEns) VALUES (6, 'Histoar', 'Michel');
    
    INSERT INTO Etudiants (NumEtu, NomEtu, PrenomEtu) VALUES (1, 'Durand', 'Maxime');
    INSERT INTO Etudiants (NumEtu, NomEtu, PrenomEtu) VALUES (2, 'Dasilva', 'Pablo');
    INSERT INTO Etudiants (NumEtu, NomEtu, PrenomEtu) VALUES (3, 'Pais', 'Marie');
    INSERT INTO Etudiants (NumEtu, NomEtu, PrenomEtu) VALUES (5, 'Poujol', 'Simon');
    INSERT INTO Etudiants (NumEtu, NomEtu, PrenomEtu) VALUES (7, 'Bonet', 'Clement');