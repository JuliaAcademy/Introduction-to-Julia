##########
 # @ Author: Jordi Gual
 # @ Create Time: 2023-02-13 16:54:18
 # @ Modified time: 2023-02-14 11:32:20
 # @ Description: Prova càlcul atribut amb Julia.
 ##########

#########################################
### Llibreries
#########################################

using Pkg
Pkg.add("DataFrames")
Pkg.add("CSV")

using DataFrames
using CSV
using Dates

#########################################
### Variables globals
#########################################

WDIR = "C:/Users/jgual/Documents/Projectes BST/Dades BST/"

DATA_ZERO = Date("01/01/2015", "%d/%m/%Y")
DATA_ZERO_CONVS = Date("01/01/2018", "%d/%m/%Y")
DATA_ANALISI = Date("01/07/2021", "%d/%m/%Y")

# Nombre de dies a associar a aquelles convocatòries que no obtenen resposta
# Derivat del model de Poisson de la resposta a les convocatòries
T_POISSON = 808.59

# Toggle per a seleccionar donants convocables entre (Si) o (Si, No: Sense donacions durant 3 anys)
NOMES_SIS = true