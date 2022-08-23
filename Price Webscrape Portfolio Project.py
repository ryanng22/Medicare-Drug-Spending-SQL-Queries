#------------------------------------------------------------------------------
# WebScrape data of Mark Cuban's Cost Plus Drugs
#------------------------------------------------------------------------------
# import libraries
from bs4 import BeautifulSoup
import time
import pandas as pd
import matplotlib.pyplot as plt
from selenium.webdriver import Chrome

path = r'C:\Users\ryann\chromedriver_win32\chromedriver.exe'
driver = Chrome(executable_path=path)

# urls sourced for popular drug indications
url_list = ['https://costplusdrugs.com/medications/categories/diabetes/',
            'https://costplusdrugs.com/medications/categories/high-blood-pressure/',
            'https://costplusdrugs.com/medications/categories/high-cholesterol/',
            'https://costplusdrugs.com/medications/categories/gastrointestinal/',
            'https://costplusdrugs.com/medications/categories/allergies/',
            'https://costplusdrugs.com/medications/categories/infection/',
            ]

# Render HTML sourced from JavaScript file using Selenium
# Scrape tabular elements and append to list
data = []
for url in url_list:
    driver.get(url)
    time.sleep(8)
    pageSource = driver.page_source

    soup = BeautifulSoup(pageSource, 'html.parser')
    elements = soup.findAll('div',{'role':'cell'})
    for element in elements:
        rows = element.get_text()
        data.append(rows)
driver.quit()

# Split list into rows and store as pandas dataframe
final_list = []
for value in range(0, len(data), 6):
    final_list.append(data[value:value + 6])

df = pd.DataFrame(final_list, columns=['Medication','Form','Retail','Price','Savings','Button'])

# Clean data
# Drop unnecessary columns
df1 = df.drop(columns=['Button'])

# Remove unnecessary characters
df1['Medication'] = df1['Medication'].str.replace(r'Get Started','')
df1['Savings'] = df1['Savings'].str.replace(r'Save ','')
df1 = df1.replace('\$','', regex = True).replace(',','', regex = True)

# Split column, keep only first part of split, and remove whitespaces
df1['Medication'] = df1['Medication'].str.split('(', expand=True)[0]
df1['Medication'] = df1['Medication'].str.strip()

# Change to appropriate data type
df1[['Retail','Price','Savings']] = df1[['Retail','Price','Savings']].astype(float)

df1 = df1.set_index('Medication')

# Check data
df1.head()
df1.shape               #(131, 4)

df1.dtypes              #Form        object
                        #Retail     float64
                        #Price      float64
                        #Savings    float64
                        #dtype: object

df1.describe()          #           Retail       Price      Savings
                        #count   131.000000  131.000000   131.000000
                        #mean    133.116718   12.660305   120.456412
                        #std     293.272453   25.298812   279.959450
                        #min       6.080000    3.600000     1.230000
                        #25%      20.580000    4.500000    13.860000
                        #50%      41.960000    7.030000    33.000000
                        #75%     105.355000   11.100000    88.445000
                        #max    2072.880000  265.800000  2052.780000

df1.isna().sum()        #Form       0
                        #Retail     0
                        #Price      0
                        #Savings    0
                        #dtype: int64

# Plot distributions: Both figures show that the vast majority of values for
# price are less than 10, showing favorable pricing for many widely used
# medications even in comparison to popular Rx Discount Cards.

df1.hist(bins=25)
plt.boxplot(df1['Price'])
plt.show()

# Save dataframe to CSV file
df1.to_csv(r'C:\Users\ryann\OneDrive\Documents\Python_Project\df1.csv')
