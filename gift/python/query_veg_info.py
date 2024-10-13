import pandas as pd
import xerox
import numpy as np
import re

excel_file = pd.ExcelFile('../xlsx/data.xlsx')

item_value_df = excel_file.parse('Item Values', header=1, index_col=0)
item_value_df.index = item_value_df.index.str.lower()

upgrade_value_df = excel_file.parse('Upgrade Values', index_col=0)
upgrade_value_df.index = upgrade_value_df.index.str.lower()

item_use_value_df = excel_file.parse('Item Use Values', header=1, index_col=0)
item_use_value_df.index = item_use_value_df.index.str.lower()

item_desc_df = pd.read_csv('../xlsx/item_desc.csv', index_col=0)
item_desc_df.index = item_desc_df.index.str.lower()


def to_snake_case(s: str) -> str:
    # Replace spaces and special characters with underscores
    s = re.sub(r'[\s]+', '_', s)  # Replace spaces with underscores
    s = re.sub(r'[^a-zA-Z0-9_]', '', s)  # Remove non-alphanumeric characters (except underscores)
    s = re.sub(r'[_]+', '_', s)  # Replace multiple underscores with a single underscore
    return s.lower()  # Convert to lowercase


def process_row(row: pd.Series, column_filter: str = None, column_filter_exclude: bool = False) -> str:
    result_list = []

    # Iterate over the columns of the row
    for column_name, value in row.items():
        if column_name in 'Diff' or 'Unnamed' in column_name:
            continue

        if not column_filter is None:
            if column_filter_exclude:
                if column_filter in column_name:
                    continue
            else:
                if not column_filter in column_name:
                    continue

        is_percent = False
        if "%" in column_name:
            column_name = column_name.replace('%','').strip()
            is_percent = True

        effects = ''
        # Check if the value is numeric (int or float)
        if isinstance(value, (np.int64, np.float64)):
            if value == 0:
                continue

            sign = ''
            if value > 0:
                sign = '+'
            if is_percent:
                value = '{0:.2f}%'.format(value*100)

            effects = f"{column_name} {sign}{value}"

        if effects:
            result_list.append(effects)

    # Join the list into a string, separated by new lines
    result_string = "<br/>".join(result_list)

    return result_string


def query(name: str) -> str:
    name = name.lower()

    item_value = item_value_df.loc[name]
    upgrade_value = upgrade_value_df.loc[name]
    item_use_value = item_use_value_df.loc[name]
    item_desc = item_desc_df.loc[name]['desc']

    upgrade_value_formated = process_row(upgrade_value, "cook", True)
    cook_value_formated = process_row(upgrade_value, "cook")
    cook_value_formated = cook_value_formated.replace(" cook", "")

    item_use_formated = process_row(item_use_value)

    sell_price = int(item_value['Sell'])
    buy_price = int(item_value['Buy'])
    rarity = item_value['Rarity']
    difficulty = upgrade_value['Diff']

    result_string = '{{{{RF4Vegetable\n|image name ={}_high\n|inbound =<!--empty means false-->\n|desc ={}\n|category =Vegetable\n|sell ={}\n|buy ={}\n|rarity ={}\n|effects ={}\n|cook ={}\n|difficulty ={}\n|upgrade ={}\n}}}}'.format(
        to_snake_case(name), item_desc, sell_price, buy_price, rarity, item_use_formated, cook_value_formated, difficulty, upgrade_value_formated)

    return result_string


if __name__ == '__main__':
    wiki_string = query("Mealy Apple")
    print(wiki_string)
    xerox.copy(wiki_string)
