init:
	gilt overlay

get-gilt:
	pip install python-gilt
deploy-perks:
	scp -r perks slavko@192.168.3.100:~
