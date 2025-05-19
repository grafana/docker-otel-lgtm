@ECHO OFF
:loop
	cls
	curl -s http://localhost:8080/rolldice
	curl -s http://localhost:8081/rolldice
	curl -s http://localhost:8082/rolldice
	curl -s http://localhost:8083/rolldice
	curl -s http://localhost:8084/rolldice
	timeout /t 2
goto loop
