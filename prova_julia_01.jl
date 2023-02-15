##########
 # @ Author: Jordi Gual
 # @ Create Time: 2023-02-13 16:54:18
 # @ Modified time: 2023-02-14 19:02:19
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

DTF = DateFormat("d/m/y")

DATA_ZERO = Date("01/01/2015", DTF)
DATA_ZERO_CONVS = Date("01/01/2018", DTF)
DATA_ANALISI = Date("01/07/2021", DTF)

# Nombre de dies a associar a aquelles convocatòries que no obtenen resposta
# Derivat del model de Poisson de la resposta a les convocatòries
T_POISSON = 808.59

# Toggle per a seleccionar donants convocables entre (Si) o (Si, No: Sense donacions durant 3 anys)
NOMES_SIS = true


#########################################
### Definició de funcions
#########################################

"""
    nombre_total_donacions(convs, dncs)

Calcula el nombre de donacions fetes amb anterioritat
a una data i afegeix la nova columna a convs
Args:
    convs: (dataframe): Convocatòries
    dncs: (dataframe): Donacions
Returns:
    convs: (dataframe): convs + nova columna
"""
function nombre_total_donacions(convs, dncs)
    # Iniciem la columna resultant   
    convs[!, :"total_dncs_previes"] .= -1

    # Per cada convocatòria...
    for (i_cnv, conv_concreta) in enumerate(convs)

        # Busquem les donacions fetes pel donant
        dncs_fetes = dncs[dncs.DONANTID .== conv_concreta.DONANTID]

        # Filtro les donacions amb data anterior a la data convocatòria
        dncs_fetes = dncs_fetes[dncs_fetes.DDONACIO .<
                                conv_concreta.DCONV]

        # I actualitzo el valor de la columna 'total_dncs_previes'
        convs[i_cnv, "total_dncs_previes"] = len(dncs_fetes)

    return convs
end

#########################################
### Programa principal
#########################################

##########
### Lectura dels fitxers
#########

# Donacions-Donants
@time begin
    arxiu = joinpath(WDIR, "DNCS_DNTS_sang_2015-21.csv")
    df = CSV.read(arxiu, DataFrame; decimal=",", delim=";")
    if NOMES_SIS
        df = df[df.CONVOCABLE == "Si", :]
    df = df[~df.GrupABO.isnull(), :]
end

# Convocatòries
@time begin
    arxiu = joinpath(WDIR, "convs_DCONV_sang.csv")
    convs = CSV.read(arxiu, DataFrame; decimal=",", delim=";")
end

# Sessions
@time begin
    arxiu = joinpath(WDIR, "CRM_SESSIONS_CREACIO2_ALL.csv")
    clcts = CSV.read(arxiu, DataFrame; decimal=",", delim=";")
    clcts = clcts[["INN_CODSESCOLECTA",
                   "INN_NOMCPCOLECTA",
                   "INN_CPCOLECTA"]]
end

##########
### Tractament de dates
#########
@time begin

    df.DDONACIO = Date(df.DDONACIO, DTF)
    df.DNAIXEMENT = Date(df.DNAIXEMENT, DTF)
    df.DPRIMERADONACIO = Date(df.DPRIMERADONACIO, DTF)

    # Filtrat de dades errònies
    # Eliminem dates 1a donació anteriors a 1950
    dummy = Date("01/01/1950", DTF)
    df = df[df.DPRIMERADONACIO > dummy] 

    # Calculem l'edat de la primera donació
    # Anys en float els passem a int
    df["Edat_1a_Don"] = (df.DPRIMERADONACIO - df.DNAIXEMENT)
    df.Edat_1a_Don = df.Edat_1a_Don.apply(lambda x: x.days/365.2425)
    df.Edat_1a_Don = df.Edat_1a_Don.astype(int)

    # Convertim a int l'edat del donant
    df.Age = df.Age.astype(int)

    # Transformació de les dates de convocatòria a tipus datetime
    convs.DCONV = Date(convs.DCONV, DTF)

    # Selecció de les dades a partir de 2018 per poder generar característiques
    # amb un mínim de 3 anys d'informació
    convs = convs[convs.DCONV >= DATA_ZERO_CONVS]
end

##########
### Resampling
#########
@time begin

    # Selecció de les convocatòries fetes a donants que realment han donat plasma
    convs = convs[convs.DONANTID.isin(df.DONANTID.unique())]

    # Proporció Ateses/No Ateses
    # .value_counts()[1] torna els 'S', que sempre són menys que els 'N'
    prop = convs.Atesa_SN.value_counts()

    # Tria aleatòria donants no-responedors segons 'conv.DONACIO == N',
    # en mateix nombre que els responedors:
    convs_no_ateses = convs[convs.Atesa_SN == 'N'].sample(prop[1])

    # Les ajuntem amb les convocatòries respostes
    convs = pd.concat([convs_no_ateses, convs[convs.Atesa_SN == 'S']], axis=0)
end

##########
### Fusions
#########
@time begin
    dncs = pd.merge(df, clcts,
                    left_on="COLECTAID",
                    right_on="INN_CODSESCOLECTA",
                    how="left")

    convs = pd.merge(convs, clcts,
                    left_on="COLECTAID",
                    right_on="INN_CODSESCOLECTA",
                    how="left")
end

##########
### Construcció de Features
#########

###
# Total donacions prèvies
###
@time begin
    convs = nombre_total_donacions(convs, dncs)
    convs.head()
end