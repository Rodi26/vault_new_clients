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
![image](https://user-images.githubusercontent.com/30529563/217593564-1c23eb31-8f43-4f8e-ac18-3b15c3fdddc4.png)


is_active_during_period is a flag to understand if the created entite during the period has been active. If not, the value is 0 and the client is not count for licensing. 
