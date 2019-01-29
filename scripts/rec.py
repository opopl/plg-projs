
import os
import records

projsdir = os.environ.get('projsdir','')
file = os.path.join(projsdir,'projs.sqlite')

print(projsdir)
print(file)
print('a')

db=records.Database('sqlite://' + file)
