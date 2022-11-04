# vault_new_clients

This program creates a CSV which contains the list of created entites during a period pass as a parameter. The purpose of this list is to analyse the new clients. 


Pre-REQ:
VAULT_TOKEN & VAULT_ADDR env variables must be set
jq, sed, python3 & dateutil must be installed. 


How to launch the program : 
./analyse_new_clients.sh start_date end_date

ex:
./analyse_new_clients.sh 2022-05-01 2022-10-31


Output:
A CSV file  "Output.csv" with ; as a delimiter is created in /tmp and the file

ex: 
id ; name ; creation_time ; namespace_id ; namespace_name ; accessor ; mount_path ; mount_name ; is_active_during_period
766c0dfa-b386-c134-528b-d4a5582ca5ec ; entity_e4a3662e ; 2022-10-31T16:41:07.26523Z ; root ; root ; auth_userpass_2f2fe2f6 ; null ; admin ; 1
aa3de9ab-62c2-22ae-b9c3-c0e0b3d821ef ; entity_8e00fd40 ; 2022-10-31T16:36:43.084358Z ; root ; root ; auth_kubernetes_7f756c01 ; null ; 35573728-cb2a-40ab-98e9-509accca0daf ; 1

is_active_during_period is a flag to understand if the created entite during the period has been active. If not, the value is 0 and the client is not count for licensing. 
