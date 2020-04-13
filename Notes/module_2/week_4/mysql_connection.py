import pymysql
import getpass

def connect():
    pw = getpass.getpass("Please insert your password:")
    return pymysql.connect(host="localhost",
                           port=3306,
                           user="ironhack",
                           passwd=pw,
                           db="olist")
