#!/bin/bash

set -m

iris session irispython -U%SYS '##class(Security.Users).UnExpireUserPasswords("*")'

iris session irispython < /irisfiles/pasosiniciales.script