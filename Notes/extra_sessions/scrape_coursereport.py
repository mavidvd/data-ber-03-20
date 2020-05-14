import pandas as pd
import datetime
import re
import requests
import bs4
import pymysql
import getpass

def get_suppe(url):
    resp = requests.get(url)
    return bs4.BeautifulSoup(resp.content, "html.parser")

def get_school_list(soup):
    return (soup
            .find("ul", id="schools")
            .find_all("li"))

def get_rank(school_item):
    rank_pattern = r"^(\d{1,2})\."
    rank = (school_item
            .find("h3")
            .find("a")
            .text)
    return int(re.findall(rank_pattern, rank)[0])

def get_name(school_item):
    name_pattern = r"^\d{1,2}\.\s(.+)"
    name = (school_item
            .find("h3")
            .find("a")
            .text)
    return re.findall(name_pattern, name)[0]

def get_rating(school_item):
    rating_pattern = r"\((.+)\)"
    rating = (school_item
              .find("span",
                    class_="longform-rating-text")
              .text)
    
    return float(re.findall(rating_pattern, rating)[0])

def get_reviews(school_item):
    reviews_pattern = r"(^\d*)\s"
    reviews = (school_item
               .find_all("span",
                         class_="longform-rating-text")[1]
               .find("a")
               .text)
    return int(re.findall(reviews_pattern, reviews)[0])

def get_locations(school_item):
    location_list = (school_item
                     .find("span",
                           class_="location")
                     .find_all("a"))
    return "|".join([loc.text for loc in location_list])

def get_description(school_item):
    return (school_item
            .find("div",
                  class_="desc-container")
            .find_all("p"))[1].text

def get_stars(school_item):
    stars_dict = {"icon-full_star": 1,
                  "icon-half_star": .5,
                  "icon-empty_star": 0}
    stars = (school_item
             .find("div",
                   class_="ratings title-rating")
             .find_all("span"))[1:]
    
    return float(sum([stars_dict[star["class"][0]] for star in stars]))

def get_record(school_item, bootcamp_type, date=datetime.date.today()):
    return {"date_id": date,
            "bootcamp_type": bootcamp_type,
            "rank": get_rank(school_item),
            "name": get_name(school_item),
            "rating": get_rating(school_item),
            "stars": get_stars(school_item),
            "reviews": get_reviews(school_item),
            "locations": get_locations(school_item),
            "description": get_description(school_item)}

def get_rankings(bootcamp_type, date=datetime.date.today()):
    url = f"https://www.coursereport.com/best-{bootcamp_type}-bootcamps"
    soup = get_suppe(url)
    school_list = get_school_list(soup)
    return pd.DataFrame([get_record(school, bootcamp_type, date) for school in school_list])

if __name__ == "__main__":
    list_of_bootcamps = ["coding", "data-science", "online"]
    datasets = {bc: get_rankings(bc) for bc in list_of_bootcamps}

    pw = getpass.getpass()
    conn = pymysql.connect(host="localhost",
                           port=3306,
                           user="ironhack",
                           passwd=pw)
    cursor = conn.cursor()

    for bc in list_of_bootcamps:
        table = bc if bc != "data-science" else "data_science"
        insert_query = f"INSERT INTO coursereport.{table} VALUES "

        for idx, row in datasets[bc].iterrows():
            if idx != 0:
                insert_query = insert_query + ", "
                
            insert_query = insert_query + str((row["date_id"].strftime("%Y-%m-%d"),
                                            row["bootcamp_type"],
                                            row["rank"],
                                            row["name"],
                                            row["rating"],
                                            row["stars"],
                                            row["reviews"],
                                            row["locations"],
                                            row["description"]))
        cursor.execute(insert_query)
    conn.commit()
    conn.close()
    print("Inserts completed! \\o/")
