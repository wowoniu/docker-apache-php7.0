all: apache-phpmodule

apache-phpmodule:
	docker build -t apache2:php7module .
