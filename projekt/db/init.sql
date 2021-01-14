CREATE DATABASE notes DEFAULT CHARACTER SET utf8 COLLATE utf8_polish_ci;
USE notes;

CREATE TABLE user (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nickname VARCHAR(40) NOT NULL UNIQUE,
    password_hash VARCHAR(256) NOT NULL,
    mail VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE note (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    author VARCHAR(40) NOT NULL ,
    name VARCHAR(40) NOT NULL ,
    note VARBINARY (4000) NOT NULL,
    public BOOLEAN,
    encrypted BOOLEAN
);

CREATE TABLE shared (
    id VARCHAR(60) NOT NULL UNIQUE,
    nickname  VARCHAR(40) NOT NULL ,
    author VARCHAR(40) NOT NULL ,
    name VARCHAR(40) NOT NULL ,
    note VARBINARY (4000) NOT NULL,
    public BOOLEAN,
    encrypted BOOLEAN
);
CREATE TABLE last_login(
    ip VARCHAR(60) NOT NULL UNIQUE,
    bad_logins INTEGER NOT NULL
);


INSERT INTO user(nickname, password_hash, mail) VALUES ("test","cokolwiek","mail");