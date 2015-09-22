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
      
  /* Remplissage tables simples */
  INSERT INTO Enseignants (NumEns, NomEns, PrenomEns) VALUES (1, 'Svete', 'Pierre');
  INSERT INTO Enseignants VALUES (2, 'Spor', 'Paul');
  INSERT INTO Enseignants VALUES (3, 'Fransai', 'Jacques');
  INSERT INTO Enseignants VALUES (4, 'Mat', 'Jean');
  INSERT INTO Enseignants VALUES (6, 'Histoar', 'Michel');
  
  INSERT INTO Etudiants (NumEtu, NomEtu, PrenomEtu) VALUES (1, 'Durand', 'Maxime');
  INSERT INTO Etudiants VALUES (2, 'Dasilva', 'Pablo');
  INSERT INTO Etudiants VALUES (3, 'Pais', 'Marie');
  INSERT INTO Etudiants VALUES (5, 'Poujol', 'Simon');
  INSERT INTO Etudiants VALUES (7, 'Bonet', 'Clement');
  
  INSERT INTO Salles (NumSal, NomSal, CapaciteSal) VALUES (1, 'A', 10);
  INSERT INTO Salles VALUES (10, 'B', 150);
  INSERT INTO Salles VALUES (8, 'C', 200);
  INSERT INTO Salles VALUES (1, 'D', 50);
  INSERT INTO Salles VALUES (8, 'E', 1);
  INSERT INTO Salles VALUES (8, 'F', 2);
  
  INSERT INTO Epreuves (NumEpr, NomEpr, DureeEpr) VALUES (1, 'SVT', '+00 01:00:00');
  INSERT INTO Epreuves VALUES (2, 'Sport', '+01 00:00:00');
  INSERT INTO Epreuves VALUES (3, 'Francais', '+00 02:00:00');
  INSERT INTO Epreuves VALUES (4, 'Maths', '+00 04:00:00');
  INSERT INTO Epreuves VALUES (5, 'Histoire', '+00 02:30:00');
  INSERT INTO Epreuves VALUES (6, 'Informatique', '+00 10:00:00');

  
   
  
/* C1 : Deux épreuves qui se chevauchent ne peuvent rassembler le même étudiant */
  /*
    Pour tout I1, I1 € Inscription
    Si I1[NumEtu, NumEpr] == I2[NumEtu, NumEpr]
    Alors NOT OVERLAPS (Horaires[ I1[NumEpr] ].DateHeureDebut, idem + Epreuves[ I1[NumEpr] ].DureeEpr,
            Horaires[ I2[NumEpr] ].DateHeureDebut, idem + Epreuves[ I2[NumEpr] ].DureeEpr)
	*/
	/*
                  Insert	Delete	Update
		Epreuves		  -		    -		    Diff
		Inscriptions	Imm		  -		    Diff
		Horaires		  Imm		  -		    Imm
	*/
  
  /* Sur Epreuves */
	CREATE OR REPLACE TRIGGER C1_Modif_Epr
		AFTER UPDATE OF DureeEpr ON Epreuves 
		DECLARE N INTEGER;
		BEGIN
			SELECT 1 INTO N FROM Inscriptions I1, Inscriptions I2, Horaires H1, Horaires H2, Epreuves E1, Epreuves E2
			WHERE
				I1.NumEtu = I2.NumEtu AND
				I1.NumEpr > I2.NumEpr AND
        I1.NumEpr = H1.NumEpr AND
        I1.NumEpr = E1.NumEpr AND
        I2.NumEpr = H2.NumEpr AND
        I2.NumEpr = E2.NumEpr AND
				(H1.DateHeureDebut, E1.DureeEpr) OVERLAPS (H2.DateHeureDebut, E2.DureeEpr);
        RAISE TOO_MANY_ROWS;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN NULL;
				WHEN TOO_MANY_ROWS THEN raise_application_error(-20000, 'Viol C1_Modif_Epr');
		END;
		/
    
  /* Sur Inscriptions */
  CREATE OR REPLACE TRIGGER C1_Modif_Ins
    AFTER UPDATE OF NumEtu, NumEpr OR INSERT ON Inscriptions 
    DECLARE N INTEGER;
    BEGIN
      SELECT 1 INTO N FROM Inscriptions I1, Inscriptions I2, Horaires H1, Horaires H2, Epreuves E1, Epreuves E2
      WHERE
				I1.NumEtu = I2.NumEtu AND
				I1.NumEpr > I2.NumEpr AND
        I1.NumEpr = H1.NumEpr AND
        I1.NumEpr = E1.NumEpr AND
        I2.NumEpr = H2.NumEpr AND
        I2.NumEpr = E2.NumEpr AND
				(H1.DateHeureDebut, E1.DureeEpr) OVERLAPS (H2.DateHeureDebut, E2.DureeEpr);        
        RAISE TOO_MANY_ROWS;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
        WHEN TOO_MANY_ROWS THEN raise_application_error(-20001, 'Viol C1_Modif_Ins');
    END;
    /
  
  /* Sur Horaires */
  CREATE OR REPLACE TRIGGER C1_Modif_Hor
    AFTER UPDATE OF NumEpr, DateHeureDebut OR INSERT ON Horaires
    DECLARE N INTEGER;
    BEGIN
      SELECT 1 INTO N FROM Inscriptions I1, Inscriptions I2, Horaires H1, Horaires H2, Epreuves E1, Epreuves E2
      WHERE
				I1.NumEtu = I2.NumEtu AND
				I1.NumEpr > I2.NumEpr AND
        I1.NumEpr = H1.NumEpr AND
        I1.NumEpr = E1.NumEpr AND
        I2.NumEpr = H2.NumEpr AND
        I2.NumEpr = E2.NumEpr AND
				(H1.DateHeureDebut, E1.DureeEpr) OVERLAPS (H2.DateHeureDebut, E2.DureeEpr);        
        RAISE TOO_MANY_ROWS;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
        WHEN TOO_MANY_ROWS THEN raise_application_error(-20002, 'Viol C1_Modif_Hor');
    END;
    /
  
/* Jeu de tests */
  /* Un étudiant inscrit à deux épreuves qui ne se chevauchent pas */
  INSERT INTO Inscriptions (NumEtu, NumEpr) VALUES (1, 1);
  INSERT INTO Inscriptions VALUES (1, 2);
  INSERT INTO Horaires VALUES (1, '01/01/2015 00:00:00');
  INSERT INTO Horaires VALUES (2, '02/01/2015 00:00:00');
  /* Update on Epreuves: Modification de la durée de l'épreuve 1 pour créer un chevauchement */
  UPDATE Epreuves SET DureeEpr = '+01 10:00:00' /* Erreur -20000: Viol C1_Modif_Epr */
    WHERE Epreuves.NumEpr = 1
  
  DELETE FROM Inscriptions;
  DELETE FROM Horaires;
  
  /* Deux épreuves qui se chevauchent, une qui ne chevauche pas */
  INSERT INTO Horaires (NumEpr, DateHeureDebut) VALUES (1, '01/01/2015 00:00:00');
  INSERT INTO Horaires VALUES (3, '01/01/2015 00:30:00');
  INSERT INTO Horaires Values (2, '02/01/2015 00:00:00');
  /* Insert on Inscriptions: Insertion d'une inscription d'un même étudiant sur les deux épreuves qui se chevauchent */
  INSERT INTO Inscriptions (NumEtu, NumEpr) VALUES (1, 1);
  INSERT INTO Inscriptions VALUES (1, 3); /* Erreur -20001: Viol C1_Modif_Ins */
  DELETE FROM Inscriptions;
  /* Update on Inscriptions: Inscription d'un étudiant sur deux épreuves qui ne se chevauchent pas, puis modification de cette inscription */
  INSERT INTO Inscriptions VALUES (1, 1);
  INSERT INTO Inscriptions VALUES (1, 2);
  UPDATE Inscriptions SET NumEpr = 3 /* Erreur -20001: Viol C1_Modif_Ins */
    WHERE
      Inscriptions.NumEtu = 1 AND
      Inscriptions.NumEpr = 2;
  
  DELETE FROM Inscriptions;
  DELETE FROM Horaires;
  
  /* Un étudiant inscrit à deux épreuves */
  INSERT INTO Inscriptions (NumEtu, NumEpr) VALUES (1, 1);
  INSERT INTO Inscriptions VALUES (1, 2);
  /* Insert on Horaires: Programmation des épreuves en chevauchement */
  INSERT INTO Horaires (NumEpr, DateHeureDebut) VALUES (1, '01/01/2015 00:00:00');
  INSERT INTO Horaires VALUES (2, '01/01/2015 00:30:00'); /* Erreur -20002: Viol C1_Modif_Hor */
  DELETE FROM Horaires;
  /* Update on Horaires: Les deux épreuves ne se chevauchaient pas, elles le font désormais */
  INSERT INTO Horaires VALUES (1, '01/01/2015 00:00:00');
  INSERT INTO Horaires VALUES (2, '02/01/2015 00:00:00');
  UPDATE Horaires SET DateHeureDebut = '01/01/2015 00:00:00' /* Erreur -20002: Viol C1_Modif_Hor */
    WHERE Horaires.NumEpr = 2 AND
    Horaires.DateHeureDebut = '02/01/2015 00:00:00'