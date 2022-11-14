# +------------+--------+--------------------------------------------------------+
# | Date       | Author | Change                                                 |
# +------------+--------+--------------------------------------------------------+
# |            | A.McC. | Original version. Scrape 1000 surnames, male forenames,|
# |            |        | and female forename into text files for Oracle to load.|
# +------------+--------+--------------------------------------------------------+

import re, requests
from urllib.request import urlopen
from bs4 import BeautifulSoup

# append a newline character to each name and write them all out to a file
def writeNamesToFile(filename, listOfNames):
    oFile = open("/home/pi/Development/Python/Scraping/{}.txt".format(filename), "w")
    listOfNames = map(lambda x:x + "\n", listOfNames)
    oFile.writelines(listOfNames)
    oFile.close()

# scrape 1000 surnames

url = "https://surnames.behindthename.com/top/lists/united-states/1990"
html = urlopen(url)
soup = BeautifulSoup(html, "lxml")
text = soup.get_text()
text.replace(r'\xa0', ' ').encode('utf-8')
surnames = re.findall("(?<=\.  )([A-Z,a-z]+)(?=\n)", text)
writeNamesToFile("surnames", surnames)

# scrape 1000 male forenames

headers = requests.utils.default_headers()
headers.update({ 'User-Agent': 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0'})
url = "https://www.verywellfamily.com/top-1000-baby-boy-names-2757618"
req = requests.get(url, headers)
soup = BeautifulSoup(req.content, "html.parser")
text = soup.prettify()
forenames = re.findall("(?<=<li>)([A-Z,a-z]+)(?=<\/li>)", text.replace(" ","").replace("\n", ""))
writeNamesToFile("forenames_male", forenames)

# scrape 1000 female forenames

headers = requests.utils.default_headers()
headers.update({ 'User-Agent': 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0'})
url = "https://www.verywellfamily.com/top-1000-baby-girl-names-2757832"
req = requests.get(url, headers)
soup = BeautifulSoup(req.content, "html.parser")
text = soup.prettify()
forenames = re.findall("(?<=<li>)([A-Z,a-z]+)(?=<\/li>)", text.replace(" ","").replace("\n",""))
writeNamesToFile("forenames_female", forenames)