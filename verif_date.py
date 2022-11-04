import datetime, dateutil.parser
import sys
import re


creation_date = (dateutil.parser.parse(sys.argv[1].strip('"')).isoformat())
#print("date av fucnt",sys.argv[1].strip('"'))
#print("creation date",creation_date)
min_date = (dateutil.parser.parse(sys.argv[2]+'T00:00:00.000000+00:00').isoformat())
max_date = (dateutil.parser.parse(sys.argv[3]+'T23:59:59.000000+00:00').isoformat())
#print(min_date)
#print(max_date)
if min_date <= creation_date <= max_date:
    sys.exit(1)
else:   
   sys.exit(0)




