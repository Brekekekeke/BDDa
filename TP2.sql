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
    Alors NOT OVERLAPS (Horaires[ I1[NumEpr] ].DateHeureDebut, Epreuves[ I1[NumEpr] ].DureeEpr,
            Horaires[ I2[NumEpr] ].DateHeureDebut, Epreuves[ I2[NumEpr] ].DureeEpr)
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
  
/* Jeu de tests C1 */
  /* C1_Modif_Epr Un étudiant inscrit à deux épreuves qui ne se chevauchent pas */
  INSERT INTO Inscriptions (NumEtu, NumEpr) VALUES (1, 1);
  INSERT INTO Inscriptions VALUES (1, 2);
  INSERT INTO Horaires (NumEpr, DateHeureDebut) VALUES (1, '01/01/2015 00:00:00');
  INSERT INTO Horaires VALUES (2, '02/01/2015 00:00:00');
  /* Erreur Update on Epreuves: Modification de la durée de l'épreuve 1 pour créer un chevauchement */
  UPDATE Epreuves SET DureeEpr = '+01 10:00:00' /* Erreur -20000: Viol C1_Modif_Epr */
    WHERE Epreuves.NumEpr = 1
  /* Pas d'erreur Update on Epreuves: Modification de la durée de l'épreuve 1 sans créer un chevauchement */
  UPDATE Epreuves SET DureeEpr = '+00 10:00:00' /* Pas d'erreur */
    WHERE Epreuves.NumEpr = 1
    
    /* Reset */ 
    DELETE FROM Inscriptions;
    DELETE FROM Horaires;
    UPDATE Epreuves SET DureeEpr = '+00 01:00:00'
      WHERE Epreuves.NumEpr = 1
    
  /* C1_Modif_Ins Deux épreuves qui se chevauchent, deux qui ne chevauchent pas */
  INSERT INTO Horaires (NumEpr, DateHeureDebut) VALUES (1, '01/01/2015 00:00:00');
  INSERT INTO Horaires (NumEpr, DateHeureDebut) VALUES (3, '01/01/2015 00:30:00');
  INSERT INTO Horaires Values (2, '02/01/2015 00:00:00');
  INSERT INTO Horaires Values (4, '05/01/2015 00:00:00');
  /* Erreur Insert on Inscriptions: Insertion d'une inscription d'un même étudiant sur les deux épreuves qui se chevauchent */
  INSERT INTO Inscriptions (NumEtu, NumEpr) VALUES (1, 1);
  INSERT INTO Inscriptions VALUES (1, 3); /* Erreur -20001: Viol C1_Modif_Ins */
  /* Pas d'erreur Insert on Inscriptions: Inscription d'un étudiant sur deux épreuves qui ne se chevauchent pas */
  INSERT INTO Inscriptions (NumEtu, NumEpr) VALUES (1, 2);
  /* Erreur Update on Inscriptions: Modification de cette inscription sur une épreuve qui chevauche */
  UPDATE Inscriptions SET NumEpr = 3 /* Erreur -20001: Viol C1_Modif_Ins */
    WHERE
      Inscriptions.NumEtu = 1 AND
      Inscriptions.NumEpr = 2;
  /* Pas d'erreur Update on Inscriptions: Modification de cette inscription sur une épreuve qui ne chevauche pas */
  UPDATE Inscriptions SET NumEpr = 4 /* Pas d'erreur */
    WHERE
      Inscriptions.NumEtu = 1 AND
      Inscriptions.NumEpr = 2;

    /* Reset */
    DELETE FROM Inscriptions;
    DELETE FROM Horaires;
  
  /* C1_Modif_Hor Un étudiant inscrit à deux épreuves non programmées */
  INSERT INTO Inscriptions (NumEtu, NumEpr) VALUES (1, 1);
  INSERT INTO Inscriptions VALUES (1, 2);
  /* Erreur Insert on Horaires: Programmation des épreuves en chevauchement */
  INSERT INTO Horaires (NumEpr, DateHeureDebut) VALUES (1, '01/01/2015 00:00:00');
  INSERT INTO Horaires VALUES (2, '01/01/2015 00:30:00'); /* Erreur -20002: Viol C1_Modif_Hor */
  /* Pas Erreur Insert on Horaires: Programmation des épreuves sans chevauchement */
  INSERT INTO Horaires (NumEpr, DateHeureDebut) VALUES (2, '05/01/2015 00:00:00'); /* Pas d'erreur */  
  /* Erreur Update on Horaires: Les deux épreuves ne se chevauchaient pas, elles le font désormais */
  UPDATE Horaires SET DateHeureDebut = '01/01/2015 00:00:00' /* Erreur -20002: Viol C1_Modif_Hor */
    WHERE Horaires.NumEpr = 2
  /* Pas d'erreur Update on Horaires: Les deux épreuves ne se chevauchent toujours pas */
  UPDATE Horaires SET DateHeureDebut = '10/01/2015 00:00:00' /* Pas d'erreur */
    WHERE Horaires.NumEpr = 2
    
    /* Reset */
    DELETE FROM Inscriptions;
    DELETE FROM Horaires;
    
    
    
/* C2 : Deux épreuves qui se chevauchent et se déroulent dans la même salle commencent au même moment */
  /*
    Pour tout E1, E2 € Epreuves
    Si Occupations[E1].NumSal == Occupations[E2].NumSal
    Et si
      (Horaires[E1].DateHeureDebut, Epreuves[E1].DureeEpr)
      Overlaps
      (Horaires[E2].DateHeureDebut, Epreuves[E2].DureeEpr)
    Alors Horaires[E1].DateHeureDebut == Horaires[E2].DateHeureDebut
  */
  /*
                  Insert  Delete  Update
      Epreuves    -       -       Imm
      Horaires    -       -       Diff
      Occupations Imm     -       Diff
  */
  
  /* Sur Epreuves */
  CREATE OR REPLACE TRIGGER C2_Modif_Epr
    AFTER UPDATE OF DureeEpr ON Epreuves 
		DECLARE N INTEGER;
		BEGIN
			SELECT 1 INTO N FROM Horaires H1, Horaires H2, Epreuves E1, Epreuves E2, Occupations O1, Occupations O2
      WHERE
        O1.NumSal = O2.NumSal AND
        O1.NumEpr > O2.NumEpr AND
        O1.NumEpr = H1.NumEpr AND
        O1.NumEpr = E1.NumEpr AND
        O2.NumEpr = H2.NumEpr AND
        O2.NumEpr = E2.NumEpr AND
        (H1.DateHeureDebut, E1.DureeEpr) OVERLAPS (H2.DateHeureDebut, E2.DureeEpr);
        RAISE TOO_MANY_ROWS;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
        WHEN TOO_MANY_ROWS THEN raise_application_error(-20010, 'Viol C2_Modif_Epr');
    END;
    /

  /* Sur Horaires */
  CREATE OR REPLACE TRIGGER C2_Modif_Hor
    AFTER UPDATE OF NumEpr, DateHeureDebut ON Horaires 
		DECLARE N INTEGER;
		BEGIN
			SELECT 1 INTO N FROM Horaires H1, Horaires H2, Epreuves E1, Epreuves E2, Occupations O1, Occupations O2
      WHERE
        O1.NumSal = O2.NumSal AND
        O1.NumEpr > O2.NumEpr AND
        O1.NumEpr = H1.NumEpr AND
        O1.NumEpr = E1.NumEpr AND
        O2.NumEpr = H2.NumEpr AND
        O2.NumEpr = E2.NumEpr AND
	/* H1.DateHeureDebut <> H2.DateHeureDebut AND */
        (H1.DateHeureDebut, E1.DureeEpr) OVERLAPS (H1.DateHeureDebut, E1.DureeEpr);
        RAISE TOO_MANY_ROWS;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
        WHEN TOO_MANY_ROWS THEN raise_application_error(-20010, 'Viol C2_Modif_Hor');
    END;
    /
  
  /* Sur Occupations */
  CREATE OR REPLACE TRIGGER C2_Modif_Occ
    AFTER UPDATE OF NumSal, NumEpr ON Occupations 
		DECLARE N INTEGER;
		BEGIN
			SELECT 1 INTO N FROM Horaires H1, Horaires H2, Epreuves E1, Epreuves E2, Occupations O1, Occupations O2
      WHERE
        O1.NumSal = O2.NumSal AND
        O1.NumEpr > O2.NumEpr AND
        O1.NumEpr = H1.NumEpr AND
        O1.NumEpr = E1.NumEpr AND
        O2.NumEpr = H2.NumEpr AND
        O2.NumEpr = E2.NumEpr AND
        (H1.DateHeureDebut, E1.DureeEpr) OVERLAPS (H1.DateHeureDebut, E1.DureeEpr);
        RAISE TOO_MANY_ROWS;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
        WHEN TOO_MANY_ROWS THEN raise_application_error(-20010, 'Viol C2_Modif_Occ');
    END;
    /
    
/* Jeu de tests C2 */
  /* C2_Modif_Epr Deux épreuves dans la même salle ne se chevauchent pas */
  INSERT INTO Horaires (NumEpr, DateHeureDebut) VALUES (1, '01/01/2015 00:00:00');
  INSERT INTO Horaires VALUES (2, '02/01/2015 00:00:00');
  INSERT INTO Occupations (NumSal, NumEpr, NbPlacesOcc) VALUES (1, 1, 0);
  INSERT INTO Occupations VALUES (1, 2, 0);
  /* Erreur Update On Epreuves: Modification de la durée de l'épreuve 1 pour créer un chevauchement */
  UPDATE Epreuves SET DureeEpr = '+15 00:00:00' /* Erreur -20010 C2_Modif_Epr */
    WHERE Epreuves.NumEpr = 1
  /* Pas d'erreur Update On Epreuves: Modification de la durée de l'épreuve 1 sans créer un chevauchement */
  UPDATE Epreuves SET DureeEpr = '+00 00:00:01' /* Pas d'erreur */
    WHERE Epreuves.NumEpr = 1
    
  /* Reset */
  DELETE FROM Horaires;
  DELETE FROM Occupations;
  UPDATE Epreuves SET DureeEpr = '+00 01:00:00'
    WHERE Epreuves.NumEpr = 1

/* A TESTER ! */
  /* Jeux de tests C2_Modif_Hor */
  /* C2_Modif_Hor Deux epreuves dans la même salle ne se chevauchent pas */
  INSERT INTO Horaires (NumEpr, DateHeureDebut) VALUES (1, '01/01/20015 00:00:00');
  INSERT INTO Horaires VALUES (2, '02/01/2015 00:00:00');
  INSERT INTO Occupations (NumSal, NumEpr, NbPlacesOcc) VALUES (1,1,0);
  INSERT INTO Occupations VALUES (1, 2, 0);
  /* Erreur Update On Horaires: Modification de la date de l'épreuve 2 pour créer un chevauchement */
  UPDATE Horaires SET DateHeureDebut = '01/01/2015 00:10:00' /* Erreur XXXXXXXXXXXXXXX */
    WHERE Horaires.NumEpr = 2

  /* Pas d'erreur Update On Horaires: Modification de la date de l'épreuve 2 sans créer de chevauchement */
  UPDATE Horaires SET DateHeureDebut = '03/01/2015 00:00:00' /* Pas d'erreur */
    WHERE Horaires.NumEpr = 2
  /* Pas d'erreur Update On Horaires: Modification de la date de l'épreuve 2 pour commencer au même moment */
  UPDATE Horaires SET DateHeureDebut = '01/01/2015 00:00:00' /* Pas d'erreur */
    WHERE Horaires.NumEpr = 2
  /* Erreur Insert On Horaires: Ajout d'une épreuve en chevauchement */
  INSERT INTO Occupations (NumSal, NumEpr, NbPlacesOcc) VALUES (1, 3, 0);
  INSERT INTO Horaires (NumEpr, DateHeureDebut) VALUES (3, '01/01/2015 00:01:00'); /* Erreur XXXXXXXXXXXXX */
  /* Pas d'erreur Insert On Horaires : Ajout d'une épreuve commencant au même moment */
  INSERT INTO Horaires (NumEpr, DateHeureDebut) VALUES (3, '01/01/2015 00:00:00'); /* Erreur XXXXXXXXXXXXX */
 
  /* Reset */
  DELETE FROM Horaires;
  DELETE FROM Occupations;

  /* Jeu de tests C2_Modif_Occ */
  /* C2_Modif_Occ Les épreuves 1 et 2 commencent au même moment, la 3 chevauche la 1, la 4 ne chevauche pas. Affectation d'une salle pour l'épreuve 1 */
  INSERT INTO Horaires (NumEpr, DateHeureDebut) VALUES (1, '01/01/2015 00:00:00');
  INSERT INTO Horaires VALUES (2, '01/01/2015 00:00:00');
  INSERT INTO Horaires VALUES (3, '01/01/2015 00:01:00');
  INSERT INTO Horaires VALUES (4, '05/01/2015 00:00:00');
  INSERT INTO Occupations (NumSal, NumEpr, NbPlacesOcc) VALUES (1, 1, 0);
  /* Erreur Insert On Occupations: Affectation de l'épreuve 3 dans la salle 1 */
  INSERT INTO Occupations (NumSal, NumEpr, NbPlacesOcc) VALUES (1, 3, 0); /* ErreurXXXXXXXXX */
  /* Pas d'erreur Insert On Occupations: Affectation de l'épreuve 2 dans la salle 1 */
  INSERT INTO Occupations (NumSal, NumEpr, NbPlacesOcc) VALUES (1, 2, 0); /* Pas d'erreur */
  /* Pas d'erreur Insert On Occupations: Affectation de l'épreuve 4 dans la salle 1 */
  INSERT INTO Occupations (NumSal, NumEpr, NbPlacesOcc) VALUES (1, 3, 0); /* Pas d'erreur */
  /* Pas d'erreur Insert On Occupations: Affectation de l'épreuve 3 dans la salle 2 */
  INSERT INTO Occupations (NumSal, NumEpr, NbPlacesOcc) VALUES (2, 3, 0); /* Pas d'erreur */
  /* Erreur Update On Occupations: Affectation de la salle 1 pour l'épreuve 3 > Ne commencent pas au même moment et chevauchement */
  UPDATE Occupations SET NumSal = 1 /* Erreur XXXXXXXXXX */
    WHERE Occupations.NumEpr = 3
  /* Pas d'erreur Update On Occupations: Affectation de la salle 4 pour l'épreuve 2 */
  UPDATE Occupations SET NumSal = 4 /* Pas d'erreur */
    WHERE Occupations.NumEpr = 2
  /* Pas d'erreur Update On Occupations: Affectation de la salle 1 pour l'épreuve 2  > Commencent au même moment */
  UPDATE Occupations SET NumSal = 1 /* Pas d'erreur */
    WHERE Occupations.NumEpr = 2
  /* Pas d'erreur Update On Occupations: Affectation de la salle 1 pour l'épreuve 4 > Pas de chevauchement */
  UPDATE Occupations SET NumSal = 1 /* Pas d'erreur */
    WHERE Occupations.NumEpr = 4

  /* Reset */
  DELETE FROM Occupations;
  DELETE FROM Horaires;

/* C3: Le nombre de places occupées dans une salle par toutes les épreuves qui s'y déroulent au me moment ne peut excéder la capacité de la salle */
  /*
    Pour toute E1, En € Epreuves
    Pour toute S1 € Salles
	  Si Occupations[E1].NumSal == Occupations[En].NumSal == S1
	  Et (Horaires[E1].DateHeureDebut, E1.DureeEpr) OVERLAPS (Horaires[En].DateHeureDebut, En.DureeEpr)
	  Alors Somme (Occupation[E1].NbPlacesOcc .. Occupation[En].NbPlacesOcc) <= S1.CapaciteSal
  */
  /*
				Insert	Delete	Update
    Epreuves	-		-		Diff
    Salles		-		-		Imm		Pas de pb on DELETE, impossible si la salle est affectée dans Occupation
	Horaires	Imm		-		Diff
    Occupations	Imm		-		Diff
  */
  
  /* Sur Epreuves */
  CREATE OR REPLACE TRIGGER C3_Modif_Epr
    AFTER UPDATE OF DureeEpr ON Epreuves 
		DECLARE N INTEGER;
		BEGIN
		/*
		  SELECT 1 INTO N FROM dual
		  WHERE
		*/
		SELECT SUM(NbPlacesOcc) AS nb_pl_occ
		FROM Horaires H1, Horaires H2, Epreuves E1, Epreuves E2, Occupations O1, Occupations O2, Salles S1, Salles S2
		/* GROUP BY NumEpr */
			WHERE
				E1.NumEpr < E2.NumEpr AND
				O1.NumEpr = E1.NumEpr AND
				O2.NumEpr = E2.NumEpr AND
				O1.NumSal = O2.NumSal AND
				H1.NumEpr = E1.NumEpr AND
				H2.NumEpr = E2.NumEpr AND
				(H1.DateHeureDebut, E1.DureeEpr) OVERLAPS (H2.DateHeureDebut, E2.DureeEpr)
			IF (nb_pl_occ > O1.NumSal)
				{ RAISE TOO_MANY_ROWS;}
			ELSE
				{ RAISE NO_DATA_FOUND;}
		  EXCEPTION
			WHEN NO_DATA_FOUND THEN NULL;
			WHEN TOO_MANY_ROWS THEN raise_application_error(-20020, 'Viol C3_Modif_Epr');
	END;
    /
    
  /* Sur Salles */
  CREATE OR REPLACE TRIGGER C3_Modif_Sal
    AFTER UPDATE OF CapaciteSal ON Salles 
		DECLARE N INTEGER;
		BEGIN
		/*
		  SELECT 1 INTO N FROM dual
		  WHERE
		 */
			SELECT SUM(NbPlacesOcc) AS nb_pl_occ
			FROM Horaires H1, Horaires H2, Epreuves E1, Epreuves E2, Occupations O1, Occupations O2, Salles S1, Salles S2
			/* GROUP BY NumEpr */
				WHERE
					E1.NumEpr < E2.NumEpr AND
					O1.NumEpr = E1.NumEpr AND
					O2.NumEpr = E2.NumEpr AND
					O1.NumSal = O2.NumSal AND
					H1.NumEpr = E1.NumEpr AND
					H2.NumEpr = E2.NumEpr AND
					(H1.DateHeureDebut, E1.DureeEpr) OVERLAPS (H2.DateHeureDebut, E2.DureeEpr)
			IF (nb_pl_occ > O1.NumSal)
				{ RAISE TOO_MANY_ROWS;}
			ELSE
				{ RAISE NO_DATA_FOUND;}
			EXCEPTION
				WHEN NO_DATA_FOUND THEN NULL;
				WHEN TOO_MANY_ROWS THEN raise_application_error(-20021, 'Viol C3_Modif_Sal');
	END;
	/
	
  /* Sur Horaires */
  CREATE OR REPLACE TRIGGER C3_Modif_Hor
    AFTER INSERT OR UPDATE OF DateHeureDebut ON Horaires 
		DECLARE N INTEGER;
		BEGIN
		/*
		  SELECT 1 INTO N FROM dual
		  WHERE
		 */
			SELECT SUM(NbPlacesOcc) AS nb_pl_occ
			FROM Horaires H1, Horaires H2, Epreuves E1, Epreuves E2, Occupations O1, Occupations O2, Salles S1, Salles S2
			/* GROUP BY NumEpr */
				WHERE
					E1.NumEpr < E2.NumEpr AND
					O1.NumEpr = E1.NumEpr AND
					O2.NumEpr = E2.NumEpr AND
					O1.NumSal = O2.NumSal AND
					H1.NumEpr = E1.NumEpr AND
					H2.NumEpr = E2.NumEpr AND
					(H1.DateHeureDebut, E1.DureeEpr) OVERLAPS (H2.DateHeureDebut, E2.DureeEpr)
			IF (nb_pl_occ > O1.NumSal)
				{ RAISE TOO_MANY_ROWS;}
			ELSE
				{ RAISE NO_DATA_FOUND;}
			EXCEPTION
				WHEN NO_DATA_FOUND THEN NULL;
				WHEN TOO_MANY_ROWS THEN raise_application_error(-20022, 'Viol C3_Modif_Hor');
	END;
	/
	
  /* Sur Occupations */
  CREATE OR REPLACE TRIGGER C3_Modif_Occ
    AFTER INSERT OR UPDATE OF NbPlacesOcc ON Occupations 
		/* DECLARE N INTEGER; */
		BEGIN
		/*
		  SELECT 1 INTO N FROM dual
		  WHERE
		 */
			SELECT SUM(NbPlacesOcc) AS nb_pl_occ
			FROM Horaires H1, Horaires H2, Epreuves E1, Epreuves E2, Occupations O1, Occupations O2, Salles S1, Salles S2
			/* GROUP BY NumEpr */
				WHERE
					E1.NumEpr < E2.NumEpr AND
					O1.NumEpr = E1.NumEpr AND
					O2.NumEpr = E2.NumEpr AND
					O1.NumSal = O2.NumSal AND
					H1.NumEpr = E1.NumEpr AND
					H2.NumEpr = E2.NumEpr AND
					(H1.DateHeureDebut, E1.DureeEpr) OVERLAPS (H2.DateHeureDebut, E2.DureeEpr)
			IF (nb_pl_occ > O1.NumSal)
				{ RAISE TOO_MANY_ROWS;}
			ELSE
				{ RAISE NO_DATA_FOUND;}
			EXCEPTION
				WHEN NO_DATA_FOUND THEN NULL;
				WHEN TOO_MANY_ROWS THEN raise_application_error(-20024, 'Viol C3_Modif_Occ');
	END;
	/

  /* Jeux de tests C3 */
  /* Pour rappel : Salle 1 capacité 10. Epreuve 1 durée 1h. Epreuve 2 durée 1jour. */
  /* C3_Modif_Epr Deux épreuves programmées dans la même salle a des horaires différentes sans chevauchement */
  INSERT INTO Occupations (NumSal, NumEpr, NbPlacesOcc) VALUES (1, 1, 5);
  INSERT INTO Occupations Values (1, 2, 5);
  INSERT INTO Horaires (NumEpr, DateHeureDebut) VALUES (2, '01/01/2015 00:00:00');
  INSERT INTO Horaires VALUES (1, '02/01/2015 00:00:00');
  /* Erreur Update On Epreuves: Modification de la durée de l'épreuve 2 pour créer un chevauchement */
  UPDATE Epreuves SET DureeEpr = '+01 01:00:00') /* Erreur XXXXXX */
	WHERE Epreuves.NumEpr = 2
  /* Pas d'erreur Update On Epreuves: Modification de la durée de l'épreuve 2 sans créer de chevauchement */
  UPDATE Epreuves SET DureeEpr = '+00 23:00:00') /* Pas d'erreur */
	WHERE Epreuve.NumEpr = 2

  /* Reset */
  DELETE FROM Horaires;
  UPDATE Epreuves SET DureeEpr = '+01 00:00:00'
	WHERE Epreuves.NumEpr = 2

  /* C3_Modif_Sal Deux épreuves programmées dans la même salle à la même heure sans dépassement de capacité */
  INSERT INTO Horaires (NumEpr, DateHeureDebut) VALUES (1, '01/01/2015 00:00:00');
  INSERT INTO Horaires VALUES (2, '01/01/2015 00:00:00');
  /* Erreur Update On Salles: Diminution de la capacité de la salle */
  UPDATE Salles SET CapaciteSal = 0 /* Erreur XXXXXX */
	WHERE Salles.NumSal = 1
  /* Pas d'erreur Update On Salles: Augmentation de la capacité de la salle */
  UPDATE Salles SET CapaciteSal = 100 /* Pas d'erreur */
	WHERE Salles.NumSal = 1

  /* Reset */
  DELETE FROM Occupations;
  DELETE FROM Horaires;
  UPDATE Salles SET CapaciteSal = 10
	WHERE Salles.NumSal = 1

  /* C3_Modif_Hor Trois épreuves prévues dans la même salle */
    INSERT INTO Occupations (NumSal, NumEpr, NbPlacesOcc) VALUES (1, 1, 1);
	INSERT INTO Occupations VALUES (1, 2, 10);
	INSERT INTO Occupation VALUES (1, 3, 1);
  /* Pas d'erreur Insert on Horaires: Programmation d'une première épreuve */
    INSERT INTO Horaires (NumEpr, DateHeureDebut) VALUES (1, '01/01/2015 00:00:00'); /* Pas d'erreur */
  /* Erreur Insert On Horaires: Programmation au même moment (dépassement de capacité) */
	INSERT INTO Horaires VALUES (2, '01/01/2015 00:00:00'); /* Erreur XXXXXX */
  /* Pas d'erreur Insert On Horaires: Programmation au même moment (pas de dépassement de capacité) */
	INSERT INTO Horaires VALUES (3, '01/01/2015 00:00:00'); /* Pas d'erreur */
  /* Erreur Update On Horaires: Insertion de l'épreuve 2 sans chevauchement, puis modification (dépassement de capacité) */
	INSERT INTO Horaires VALUES (2, '02/01/2015 00:00:00');
	UPDATE Horaires SET DateHeureDebut = '01/01/2015 00:00:00') /* Erreur XXXXX */
	  WHERE Horaires.NumEpr = 2
  /* Pas d'erreur Update On Horaires: Modification sur un créneau différent */
    UPDATE Horaires SET DateHeureDebut = '03/01/2015 00:00:00') /* Pas d'erreur */
	  WHERE Horaires.NumEpr = 2
	  
  /* Reset */
  DELETE FROM Occupations;
  DELETE FROM Horaires;
  
  /* C3_Modif_Occ Epreuves 1 et 2 prévues à la même heure, épreuve 3 un autre jour */
  INSERT INTO Horaires (NumEpr, DateHeureDebut) VALUES (1, '01/01/2015 00:00:00');
  INSERT INTO Horaires VALUES (2, '01/01/2015 00:00:00');
  INSERT INTO Horaires VALUES (3, '02/01/2015 00:00:00');
  /* Pas d'erreur Insert On Occupations: Affectation de l'épreuve 1 dans la salle 1 */
  INSERT INTO Occupations (NumSal, NumEpr, NbPlacesOcc) VALUES (1, 1, 1); /* Pas d'erreur */
  /* Erreur Insert On Occupations: Affectation de l'épreuve 2 dans la salle 1 avec dépassement de capacité */
  INSERT INTO Occupation VALUES (1, 2, 10);
  
  /* Erreur Update On Occupations: Modification de l'affectation de l'épreuve 1 avec dépassement de capacité */
  UPDATE Occupation SET NbPlacesOcc = 100 /* Erreur XXXXXX */
	WHERE Occupations.NumEpr = 1
  /* Pas d'erreur Update On Occupations: Modification de l'affectation de l'épreuve 1 sans dépassement de capacité */
  UPDATE Occupations SET NbPlacesOcc = 2 /* Pas d'erreur */
	WHERE Occupations.NumEpr = 1
  /* Pas d'erreur Update On Occupations: Ajout d'une épreuve 2 dans la salle 1, puis modification sans dépassement de capacité */
  INSERT INTO Occupations (NumSal, NumEpr, NbPlacesOcc) VALUES (1, 2, 5);
  UPDATE Occupations SET NbPlacesOcc = 1 /* Pas d'erreur */
	WHERE Occupations.NumEpr = 2
  /* Erreur Update On Occupations: Ajout d'une épreuve 2 dans la salle 1, puis modification avec dépassement de capacité */
  INSERT INTO Occupations (NumSal, NumEpr, NbPlacesOcc) VALUES (1, 2, 5);
  UPDATE Occupations SET NbPlacesOcc = 100 /* Erreur XXXXXX */
	WHERE Occupations.NumEpr = 2
	
  /* Reset */
  DELETE FROM Horaires;
  DELETE FROM Occupations;
  
/* C4 Un enseignant ne surveille une salle que si une épreuve s'y déroule */
 /*
	Pour toute Su € Surveillances
	Il existe O1 € Occupations et E1 € Epreuves tels que
	Su.NumSal == O1.NumSal,
	O1.NumEpr == E1.NumEpr,
	et Su.DateHeureDebut == E1.DateHeureDebut
 */
 /*
					Insert	Delete	Update
	Occupations		-		Imm		-
	Epreuves		-		Imm		-
	Surveillance	Imm		-		Diff
 */
  /* Sur Occupations */
  CREATE OR REPLACE TRIGGER C4_Delete_Occ
    BEFORE DELETE ON Occupations
    FOR EACH ROW
    DECLARE N INTEGER
    BEGIN
      SELECT 1 INTO N FROM Epreuves E1, Occupations O1, Surveillances S1, Horaires H1
      WHERE
		E1.NumEpr = O1.NumEpr AND
		E1.NumEpr = H1.NumEpr AND
		S1.NumSal = O1.NumSal AND
		H1.DateHeureDebut = S1.DateHeureDebut
	  EXCEPTION
		WHEN NO_DATA_FOUND THEN raise_application_error(-20030, 'Viol C4_Delete_Occ');
    END;
    /
    /* Sur Epreuves */
  CREATE OR REPLACE TRIGGER C4_Delete_Epr
    BEFORE DELETE ON Epreuves
    FOR EACH ROW
    DECLARE N INTEGER
    BEGIN
      SELECT 1 INTO N FROM Epreuves E1, Occupations O1, Surveillances S1, Horaires H1
      WHERE
		E1.NumEpr = O1.NumEpr AND
		E1.NumEpr = H1.NumEpr AND
		S1.NumSal = O1.NumSal AND
		H1.DateHeureDebut = S1.DateHeureDebut
	  EXCEPTION
		WHEN NO_DATA_FOUND THEN raise_application_error(-20031, 'Viol C4_Delete_Epr');
    END;
    /
    /* Sur Surveillances */
  CREATE OR REPLACE TRIGGER C4_Modif_Sur
    BEFORE DELETE OR UPDATE OF NumSal ON Surveillances
    FOR EACH ROW
    DECLARE N INTEGER
    BEGIN
      SELECT 1 INTO N FROM Epreuves E1, Occupations O1, Surveillances S1, Horaires H1
      WHERE
		E1.NumEpr = O1.NumEpr AND
		E1.NumEpr = H1.NumEpr AND
		S1.NumSal = O1.NumSal AND
		H1.DateHeureDebut = S1.DateHeureDebut
	  EXCEPTION
		WHEN NO_DATA_FOUND THEN raise_application_error(-20032, 'Viol C4_Modif_Sur');
    END;
    /
    
    /* Jeu de tests C4 */
    /* C4_Delete_Occ Affectation de l'épreuve 1 et du prof 1 dans la salle 1 à la même heure */
    INSERT INTO Horaires (NumEpr, DateHeureDebut) VALUES (1, '01/01/2015 00:00:00');
    INSERT INTO Occupations (NumSal, NumEpr, NbPlacesOcc) VALUES (1, 1, 0);
    INSERT INTO Surveillances (NumEns, DateHeureDebut, NumSal) VALUES (1, '01/01/2015 00:00:00', 1);
    /* Erreur Delete On Occupations */
    DELETE FROM Occupations; /* Erreur XXXXXX */
    /* Pas d'erreur Delete On Occupations: Retrait préalable du surveillant */
    DELETE FROM Surveillances;
    DELETE FROM Occupations; /* Pas d'erreur */
    /* C4_Delete_Epr Erreur Delete On Epreuves */
    INSERT INTO Occupations (NumSal, NumEpr, NbPlacesOcc) VALUES (1, 1, 0);
    INSERT INTO Surveillances (NumEns, DateHeureDebut, NumSal) VALUES (1, '01/01/2015 00:00:00', 1);
    DELETE FROM Epreuves WHERE NumEpr = 1; /* Erreur XXXXX */
    /* Pas d'erreur Delete On Epreuves */
    DELETE FROM Epreuves WHERE NumEpr = 2; /* Pas d'erreur */
	/* C4_Modif_Sur Erreur Insert On Surveillances: Mauvaise salle */
	INSERT INTO Surveillances (NumEns, DateHeureDebut, NumSal) VALUES (1, '01/01/2015 00:00:00', 2); /* Erreur XXXXX */
	/* Erreur Insert On Surveillances: Mauvaise heure */
	INSERT INTO Surveillances (NumEns, DateHeureDebut, NumSal) VALUES (1, '01/01/2015 20:00:00', 1); /* Erreur XXXXX */
	/* Pas d'erreur Insert On Surveillances */
	INSERT INTO Surveillances (NumEns, DateHeureDebut, NumSal) VALUES (2, '01/01/2015 00:00:00', 1);
	/* Erreur Update On Surveillances: Changement d'heure */
	UPDATE Surveillances SET DateHeureDebut = '01/01/2015 20:00:00' /* Erreur XXXX */
	  WHERE
	    Surveillances.NumEns = 1 AND
	    DateHeureDebut = '01/01/2015 00:00:00'
	/* Erreur Update On Surveillances: Changement de salle */
	UPDATE Surveillances SET NumSal = 2 /* Erreur XXXX */
	  WHERE
	    Surveillances.NumEns = 1 AND
	    DateHeureDebut = '01/01/2015 00:00:00'
	/* Pas d'erreur Update On Surveillances: Changement de salle d'un surveillant */
    INSERT INTO Horaires (NumEpr, DateHeureDebut) VALUES (2, '01/01/2015 00:00:00');
    INSERT INTO Occupations (NumSal, NumEpr, NbPlacesOcc) VALUES (2, 2, 0);
    INSERT INTO Surveillances (NumEns, DateHeureDebut, NumSal) VALUES (2, '01/01/2015 00:00:00', 1);
    	UPDATE Surveillances SET NumSal = 1 /* Pas d'erreur */
	  WHERE
	    Surveillances.NumEns = 2 AND
	    DateHeureDebut = '01/01/2015 00:00:00'
