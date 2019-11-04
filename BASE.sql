--TP INTEGRADOR LABORATORIO III 2019 2C
--IGNACIO LACIOPPA, LEGAJO 19992, DNI 38788859

--ej 1 ok
--ej 2 ok
--ej 3 ok
--ej 4 ok
--ej 5 FALTA!!!
--EJ 6 FALTA!!!
--EJ 7 FALTA!!!

--1 - Elaborar una vista que permita conocer para cada cliente: el apellido y nombres, los números de
--cuenta, el saldo de la cuenta, la cantidad de movimientos realizados por cada cuenta y el saldo
--acumulado entre todas las cuentas de cada cliente.

create view Vista_ej1 as(
select cli.APELLIDO, cli.NOMBRE, cue.IDCUENTA, cue.SALDO,
(select count(*) from MOVIMIENTOS  where IDCUENTA=cue.IDCUENTA) as 'Cant Mov',
(select sum(saldo) from CUENTAS where IDCLIENTE= cli.IDCLIENTE) as 'Saldo Total'
from clientes as cli
inner join CUENTAS as cue on cli.IDCLIENTE=cue.IDCLIENTE
)

select*from Vista_ej1

--2 - Elaborar un procedimiento almacenado que permita crear una cuenta. El procedimiento debe recibir:
--@IDCliente, @Tipo y @Limite. Debe permitir cumplir la siguiente condición:
--Los tipos de cuenta pueden ser: CA - Caja de ahorro y CC - Cuenta corriente. De lo contrario, impedir el ingreso.
--- Si el tipo es Caja de Ahorro entonces el límite de la cuenta debe ser obligatoriamente cero.
--- Si el tipo es Cuenta corriente entonces el límite puede ser cualquier número mayor o igual que
--cero. Tener en cuenta que en el límite siempre se almacena con un valor negativo.
--- El saldo siempre será cero y el estado siempre será uno.
--Ejemplo:
--EXEC SP_NuevaCuenta 1, 'CC', 5000
--Deberá registrar lo siguiente:
--INSERT INTO Cuentas (IDCliente, Tipo, Limite, Saldo, Estado) VALUES (1, 'CC', -5000, 0, 1)
--En cambio:
--EXEC SP_NuevaCuenta 1, 'CA', 5000
--Deberá registrar lo siguiente:
--INSERT INTO Cuentas (IDCliente, Tipo, Limite, Saldo, Estado) VALUES (1, 'CA', 0, 0, 1)

SELECT * FROM CUENTAS
CREATE PROCEDURE PR_AGREGARCUENTA @IDCLIENTE BIGINT , @TIPO VARCHAR(2) , @LIMITE MONEY
AS
IF( @TIPO = 'cc' OR @TIPO = 'CC' )
BEGIN
IF @LIMITE <= 0 
BEGIN
INSERT INTO CUENTAS VALUES( @idCliente, @tipo, @limite, 0 ,1)
END
ELSE BEGIN
RAISERROR ('limite incorrecto',16, 1)
END
END
ELSE IF( @TIPO = 'ca' or @TIPO = 'CA')

BEGIN
  insert into CUENTAS VALUES (@IDCLIENTE,@TIPO,0,0,1)
END

EXEC PR_AGREGARCUENTA 3,CA,0

--3 - Realizar un trigger que al registrar una nueva cuenta le sea otorgada una tarjeta de débito. La misma
--se identifica con un valor 'D' en el Tipo de la tarjeta.

CREATE TRIGGER TG_ASIGNAR_DEBITO ON CUENTAS
AFTER INSERT
AS
declare @idCuenta   bigint
select @idCuenta=IDCUENTA FROM inserted
INSERT INTO TARJETAS VALUES ( @idCuenta,'D',1)


--4 - Realizar un trigger que al registrar un nuevo usuario le sea otorgada una Caja de Ahorro nueva.
create trigger TG_ASIGNARCUENTA on CLIENTES
AFTER INSERT
AS
declare @idCliente bigint
select @idCliente = IDCLIENTE from inserted

INSERT INTO CUENTAS VALUES (@idCliente,'CA',0,0,1)

--5 - Realizar un trigger que al eliminar un usuario realice la baja lógica del mismo. Si se elimina un usuario
--que ya se encuentra dado de baja lógica y dicho usuario no registra ni cuentas ni tarjetas, proceder a la
--baja física del usuario.
SELECT * FROM CLIENTES

CREATE TRIGGER TR_BAJAUSUARIO ON CLIENTES
INSTEAD OF UPDATE ,DELETE
AS
BEGIN
	DECLARE @IDCLIENTE BIGINT
	DECLARE @ESTADO BIT

	

	
	

END


