import pandas as pd
import xerox

char = [
    "Vishnal",
    "Clorica",
    "Volkanon",
    "Forte",
    "Kiel",
    "Bado",
    "Margaret",
    "Dylas",
    "Arthur",
    "Porcoline",
    "Xiao Pai",
    "Lin Fa",
    "Amber",
    "Illuminata",
    "Doug",
    "Blossom",
    "Dolce",
    "Jones",
    "Nancy",
    "Leon",
    "Ventuswill",
    "Son",
    "Daughter",
    "Barrett",
    "Raven",
]

all_monster_code = "#8007"
monster_item_list = [
    'Silver',
    'Gold',
    'Green Core',
    'Red Core',
    'Yellow Core',
    'Blue Core',
    'Crystal Skull',
    'Magic Crystal',
    'Dark Crystal',
    'Fire Crystal',
    'Earth Crystal',
    'Love Crystal',
    'Wind Crystal',
    'Water Crystal',
    'Light Crystal',
    'Small Crystal',
    'Big Crystal',
    'Rune Crystal',
    'Electro Crystal',
    "Thin Stick",
    "Insect Horn",
    "Plant Stem",
    "Bull's Horn",
    "Moving Branch",
    "Rigid Horn",
    "Thick Stick",
    "Devil Horn",
    "Glue",
    "Devil Blood",
    "Paralysis Poison",
    "Poison King",
    "Bird's Feather",
    "Yellow Feather",
    "Black Bird Feather",
    "Thunderbird Feather",
    "Water Dragon Fin",
    "Turtle Shell",
    "Fish Fossil",
    "Skull",
    "Dragon Bones",
    "Blk. Tortoise Shell",
    "Ammonite",
    "Tiny Golem Stone",
    "Golem Stone",
    "Golem Tablet",
    "Golem Spirit Stone",
    "Tablet of Truth",
    "Old Bandage",
    "Ambrosia's Thorns",
    "Spider's Thread",
    "Puppetry Strings",
    "Vine",
    "Scorpion Tail",
    "Strong Vine",
    "Pretty Thread",
    "Chimera Tail",
    "Arrowhead",
    "Blade Shard",
    "Broken Hilt",
    "Broken Box",
    "Glistening Blade",
    "Great Hammer Shard",
    "Hammer Piece",
    "Shoulder Piece",
    "Pirate's Armor",
    "Rusty Screw",
    "Shiny Screw",
    "Left Rock Shard",
    "Right Rock Shard",
    "MTGU Plate",
    "Broken Ice Wall",
    "Fur (S)",
    "Fur (M)",
    "Fur",
    "Wooly Furball",
    "Yellow Down",
    "Quality Fur",
    "Quality Puffy Fur",
    "Penguin Down",
    "Lightning Mane",
    "Red Lion Fur",
    "Chest Hair",
    "Spore",
    "Poison Powder",
    "Holy Spore",
    "Fairy Dust",
    "Fairy Elixir",
    "Gunpowder",
    "Root",
    "Magic Powder",
    "Mysterious Powder",
    "Melody Bottle",
    "Magic",
    "Earth Dragon Ash",
    "Fire Dragon Ash",
    "Water Dragon Ash",
    "Turnip's Miracle",
    "Cheap Cloth",
    "Quality Cloth",
    "Quality Worn Cloth",
    "Silk Cloth",
    "Ghost Hood",
    "Giant's Gloves",
    "Blue Giant's Glove",
    "Insect Carapace",
    "Pretty Carapace",
    "Ancient Ore Cloth",
    "Insect Jaw",
    "Panther Claw",
    "Magic Claw",
    "Wolf Fang",
    "Gold Wolf Fang",
    "Palm Claw",
    "Malm Claw",
    "Giant's Nail",
    "Big Giant's Nail",
    "Chimera's Claw",
    "Ivory Tusk",
    "Scorpion Pincer",
    "Dangerous Scissors",
    "Cheap Propeller",
    "Quality Propeller",
    "Dragon Fang",
    "Queen's Jaw",
    "Wet Scale",
    "Grimoire Scale",
    "Dragon Scale",
    "Crimson Scale",
    "Blue Scale",
    "Glitter Scale",
    "Love Scale",
    "Black Scale",
    "Firewyrm Scale",
    "Earthwyrm Scale",
    "Double Steel",
    "10X Steel",
    "Rune Sphere Shard",
    "Raccoon Leaf",
    "Icy Nose",
    "Big Bird's Comb",
    "Rafflesia Petal",
    "Cursed Doll",
    "Warrior's Proof",
    "Proof of Rank",
    "Throne of the Empire",
    "legendary scale",
    "dragon fin",
    "unbroken ivory tusk",
    "Ancient Orc Cloth"
]
monster_item_list = [x.lower() for x in monster_item_list]

gift_df = pd.read_excel('../xlsx/newdata.xlsx', sheet_name='gift')


def query(name: str) -> str:
    name = name.lower()

    df = gift_df.copy()

    df['item'] = df['item'].str.lower()
    df = df.loc[df['item'] == name]
    df = df.drop_duplicates(subset='name', keep='last')

    preference_map = {
        'dislike2': df[(df['taste'] == 'Dislikes') & (df['fp'] == -10)],
        'dislike': df[(df['taste'] == 'Dislikes') & (df['fp'] == -5)],
        'like2': df[(df['taste'] == 'Likes') & (df['fp'] == 6)],
        'like': df[(df['taste'] == 'Likes') & (df['fp'] == 9)],
        'like3': df[(df['taste'] == 'Likes') & (df['fp'] == 15)],
        'love2': df[(df['taste'] == 'Loves') & (df['fp'] == 9)],
        'love': df[(df['taste'] == 'Loves') & (df['fp'] == 15)]
    }

    if name in monster_item_list and "Ventuswill" not in preference_map['dislike']['name'].values:
        preference_map['dislike'] = pd.concat(
            [preference_map['dislike'], pd.DataFrame(['Ventuswill'], columns=['name'])])

    neutral = char.copy()

    gift_list = ["love", "love2", "like3", "like", "like2", "dislike", "dislike2"]

    body = ""
    for el in gift_list:
        df_list = preference_map[el]
        if len(df_list) > 0:
            body += f"\n |{el}="
            body += df_list['name'].str.cat(sep=",")
            df_list.apply(lambda x: neutral.remove(x['name']) if x['name'] in neutral else None, axis=1)

    if len(neutral) > 0:
        body += "\n |neutral="
        body += ",".join(neutral)

    gift_string = '{{{{RF4Gift{}\n}}}}'.format(body)
    gift_string = gift_string.replace("Son", "Noel")
    gift_string = gift_string.replace("Daughter", "Luna")
    gift_string = "==== Gifts ====\n" + gift_string

    return gift_string


if __name__ == '__main__':
    wiki_string = query("heaven asunder")
    print(wiki_string)
    xerox.copy(wiki_string)
