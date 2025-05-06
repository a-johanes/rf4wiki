import pandas as pd
import xerox
import numpy as np
import re
import yaml

from status_parser import parse_status_hex

excel_file = pd.ExcelFile('gift/xlsx/data.xlsx')

item_value_df = excel_file.parse('Item Values', header=1, index_col=0)
item_value_df.index = item_value_df.index.str.lower()

upgrade_value_df = excel_file.parse('Upgrade Values', index_col=0)
upgrade_value_df.index = upgrade_value_df.index.str.lower()

item_use_value_df = excel_file.parse('Item Use Values', header=1, index_col=0)
item_use_value_df.index = item_use_value_df.index.str.lower()

item_desc_df = pd.read_csv('gift/xlsx/item_desc.csv', index_col=0)
item_desc_df.index = item_desc_df.index.str.lower()

crop_values_df = excel_file.parse('Crop Values', header=1, index_col=0)
crop_values_df.index = crop_values_df.index.str.strip().str.lower()


def to_snake_case(s: str) -> str:
    # Replace spaces and special characters with underscores
    s = re.sub(r'[\s]+', '_', s)  # Replace spaces with underscores
    s = re.sub(r'[^a-zA-Z0-9_]', '', s)  # Remove non-alphanumeric characters (except underscores)
    s = re.sub(r'[_]+', '_', s)  # Replace multiple underscores with a single underscore
    return s.lower()  # Convert to lowercase

def to_title_case(s: str) -> str:
    # Replace spaces and special characters with underscores
    s = re.sub(r'[^a-zA-Z0-9_\s]', '', s)  # Remove non-alphanumeric characters (except underscores)
    s = re.sub(r'[_]+', '_', s)  # Replace multiple underscores with a single underscore

    # Split the string into words
    words = s.split(' ')

    # Capitalize the first letter of each word
    words = [word.capitalize() for word in words]

    # Join the words together
    return ' '.join(words)


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
                value = '{0:.2f}'.format(value*100).rstrip('0').rstrip('.') + '%'

            effects = f"{column_name} {sign}{value}"

        if effects:
            result_list.append(effects)

    # Join the list into a string, separated by new lines
    result_string = "<br/>".join(result_list)

    return result_string

def build_rf4_info_template(name, item_desc="", category="", sell_price="", buy_price="",
                                 rarity="", item_use_formated="", cook_value_formated="",
                                difficulty="", upgrade_value_formated="", growth="", 
                                regrowth="", harvested="",crops_value_price="", produce=""):
    """
    Builds RF4 vegetable template string, only including fields with values.
    """

    template = "RF4ItemInfobox"
    if "seeds" in name or "sds" in name:
        template = "RF4SeedInfobox"

    # Start with the required fields
    template_parts = [
        f"{{{{{template}",
        f"|image name ={to_snake_case(name)}_high"
    ]

    # Dictionary of optional fields and their values
    optional_fields = {
        "inbound": "<!--empty means false-->",  # Special case that's always included
        "desc": item_desc,
        "category": category,
        "sell": sell_price,
        "buy": buy_price,
        "rarity": rarity,
        "effects": item_use_formated,
        "cook": cook_value_formated,
        "difficulty": difficulty,
        "upgrade": upgrade_value_formated
    }

    if "seeds" or "sds" in name:
        optional_fields.update({
            "name": to_title_case(name),
            "crop": to_title_case(produce),
            "crop sell price": crops_value_price,
            "growth": growth,
            "harvested": harvested,
        })

        if regrowth:
            optional_fields["regrowth"] = regrowth

    # Add each field if it has a value
    for field, value in optional_fields.items():
        # Special handling for required fields or fields with special values
        if field in ["inbound", "category"] or (value is not None and value != ""):
            template_parts.append(f"|{field} ={value}")

    # Close the template
    template_parts.append("}}")

    # Join all parts with newlines
    return '\n'.join(template_parts)

def query(name: str, seed_produce: str="") -> str:
    name = name.lower()
    seed_produce = seed_produce.lower()

    item_value = item_value_df.loc[name]
    upgrade_value = upgrade_value_df.loc[name]

    try:
        item_use_value = item_use_value_df.loc[name]
    except KeyError:
        item_use_value = None

    item_desc = item_desc_df.loc[name]['desc']

    upgrade_value_formated = process_row(upgrade_value, "cook", True)
    cook_value_formated = process_row(upgrade_value, "cook")
    cook_value_formated = cook_value_formated.replace(" cook", "")

    item_use_formated = "INEDIBLE"
    if item_use_value is not None:
        item_use_value_processed = process_row(item_use_value)
        eat_status_effect = parse_status_hex(item_use_value["Status Flags"])

        item_use_formated_list = [eat_status_effect,item_use_value_processed]
        item_use_formated = "<br/>".join(filter(None, item_use_formated_list))

        if not item_use_formated:
            item_use_formated = "NO EFFECT"
        
    sell_price = int(item_value['Sell'])
    buy_price = int(item_value['Buy'])
    rarity = item_value['Rarity']
    difficulty = upgrade_value['Diff']

    cook_status_effect = parse_status_hex(upgrade_value["Status cook"])

    if cook_status_effect:
         if cook_value_formated:
            cook_value_formated = f"{cook_status_effect}<br/>{cook_value_formated}"
         else:
            cook_value_formated = cook_status_effect

    with open('gift/python/category.yaml', 'r') as f:
        category_map = yaml.safe_load(f)['category']
        item_category_id = item_value['Category']
        item_category = category_map[item_category_id]

    growth = 0
    regrowth = 0
    harvested = 0
    crops_value_price = 0
    if seed_produce:
        crop_values = crop_values_df.loc[seed_produce]
        growth += int(crop_values['Stage 1 Days'])
        growth += int(crop_values['Stage 2 Days'])
        growth += int(crop_values['Stage 3 Days'])
        growth += int(crop_values['Stage 4 Days'])
        regrowth = int(crop_values['Regrowth Days'])
        harvested = int(crop_values['Quantity'])
        # sell = item_value_df.loc[seed_produce]['Sell']
        # if type(sell) != np.float64:
        #     sell = sell.sort_values(ascending=False)
        #     sell = sell.iloc[0]
        # crops_value_price = int(sell)
        crops_value_price = 0

    return build_rf4_info_template(
        name=name,
        item_desc=item_desc,
        category=item_category,
        sell_price=sell_price,
        buy_price=buy_price,
        rarity=rarity,
        item_use_formated=item_use_formated,
        cook_value_formated=cook_value_formated,
        difficulty=difficulty,
        upgrade_value_formated=upgrade_value_formated,
        growth=growth,
        regrowth=regrowth,
        harvested=harvested,
        produce=seed_produce,
        crops_value_price=crops_value_price
    )

if __name__ == '__main__':
    wiki_string = query("failed dish")
    print(wiki_string)
    xerox.copy(wiki_string)
    